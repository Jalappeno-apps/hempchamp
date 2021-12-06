# frozen_string_literal: true

module Spree
  class PayuController < StoreController
    def create
      order = current_order || raise(ActiveRecord::RecordNotFound)
      items = order.line_items.map(&method(:line_item))

      additional_adjustments = order.all_adjustments.additional
      tax_adjustments = additional_adjustments.tax
      shipping_adjustments = additional_adjustments.shipping

      additional_adjustments.eligible.each do |adjustment|
        next if adjustment.amount.zero?
        next if tax_adjustments.include?(adjustment) || shipping_adjustments.include?(adjustment)

        items << {
          name: adjustment.label,
          quantity: 1,
          unit_price: adjustment.amount
        }
      end

      # payu_request = provider

      redirect_path = checkout_state_path(:payment)
      ActiveRecord::Base.transaction do
        response = payment_method.purchase(
          order.total, 
          build_purchase(
            order, 
            request, 
            items
          )
        )
        
        order.payments.create!({
          source: payment_method,
          amount: order.total,
          intent_client_key: response["orderId"],
          payment_method: payment_method
        })
        redirect_path = response["redirectUri"]
      end

      redirect_to redirect_path
    end

    def confirm
      order = current_order || raise(ActiveRecord::RecordNotFound)
      order.payments.create!({
        source: Spree::PaypalExpressCheckout.create({
          token: params[:token],
          payer_id: params[:PayerID]
        }),
        amount: order.total,
        payment_method: payment_method
      })
      order.next
      if order.complete?
        flash.notice = Spree.t(:order_processed_successfully)
        flash[:order_completed] = true
        session[:order_id] = nil
        redirect_to completion_route(order)
      else
        redirect_to checkout_state_path(order.state)
      end
    end

    def build_purchase order, request, items
      { 
        notifyUrl: payment_method.preferences[:notify_url],
        merchantPosId: payment_method.preferences[:merchant_pos_id],
        description: "Hempchamp",
        referrer: request.env['HTTP_REFERER'],
        user_agent: request.env['HTTP_USER_AGENT'],
        ip: request.remote_ip,
        customer: { 
          first_name: order.bill_address.firstname,
          last_name: order.bill_address.lastname,
          email: order.email,
          phone: order.bill_address.phone,
          language: 'pl'
        }, products: items
      }
    end

    def store_return
      order = Order.find_by(number: params["order"])

      PayuCheckStatus.execute!(
        order.number,
        PayuAccessToken.execute!
      )

      if order.payment_state == "balance_due"
        redirect_to order_path(order), flash: { success: "Dziękujemy za zamówienie, czekamy na potwierdzenie płatności. Proszę sprawdzić skrzynkę email" }
        ::PayuStatusWorker.perform_async(order.number)
        ::PayuStatusWorker.perform_in(2.minutes, order.number)
        ::PayuStatusWorker.perform_in(10.minutes, order.number)
        ::PayuStatusWorker.perform_in(20.minutes, order.number)

      elsif order.payment_state == "paid"
        redirect_to order_path(order), flash: { success: "Dziękujemy za zamówienie, prosimy o sprawdzenie skrzynki email" }
      elsif order.payment_state == "void"
        redirect_to root_path, flash: { error: "Przykro nam, Twoje zamówienie się nie powiodło, prosimy o kontakt" }
      end
    end

    def payment_status
      order = Order.find_by(number: params["order"])
      begin
      notice = PayuCheckStatus.execute!(
        order.number,
        PayuAccessToken.execute!
      )
      rescue NoMethodError
        notice = "Order not registered on PayU, please consider cancelling it"
      end
      redirect_to request.referer, flash: { notice: notice }
    end

    private
    def provider
      payment_method.provider
    end

    def payment_method
      Spree::PaymentMethod.find(params[:payment_method_id])
    end

    def line_item(item)
      {
        name: item.product.name,
        number: item.variant.sku,
        quantity: item.quantity,
        unit_price: item.price
      }
    end

  end
end
