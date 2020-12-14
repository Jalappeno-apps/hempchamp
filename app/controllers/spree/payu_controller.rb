# frozen_string_literal: true

module Spree
  class PayuController < Spree::BaseController
    def create
      access_token = PayuAccessToken.execute!

      redirect = PayuCreateOrder.execute!(
        params[:order],
        access_token,
        request.remote_ip
      )

      redirect_to redirect
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
  end
end
