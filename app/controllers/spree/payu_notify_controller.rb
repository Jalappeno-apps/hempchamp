# frozen_string_literal: true

module Spree
  class PayuNotifyController < Spree::BaseController
    protect_from_forgery except: :create
    skip_before_action :verify_authenticity_token
    before_action :order, only: :create

    def index; end

    def create
      return unless order
      order.update!(pay_order_id: params["order"]["orderId"]) unless order&.payu_order_id
      payment = order&.payments&.last

      if params["refund"].present?
        refund_processing(
          payment,
          params["refund"]["status"]
        )
      else
        new_order_processing(
          payment,
          params["order"]["status"]
        )
      end
    end

    def new_order_processing(payment, status)
      case status
      when "COMPLETED"
        payment&.complete! unless payment&.completed?

        complete_order(order)
      when "CANCELED"
        payment&.failure! unless payment&.failed?
        if !order.cancelled_email?
          OrderMailer.cancel_email(order).deliver_later
          order.update!(cancelled_email: true)
        end
      when "PENDING"
        payment&.started_processing! unless payment&.processing?
      end
    end

    def refund_processing(payment, status)
      case status
      when "FINALIZED"
        r = order.reimbursements.first.reimbursed
        Spree::ReimbursementMailer.reimbursement_email(order.reimbursements.first.id).deliver_later if r
      else
        order
      end
    end

    def order_id
      params["order"]["orderId"] || params["orderId"]
    end

    def order
      order ||= Spree::Order.find_by(
        payu_order_id: params.include?("refund") ? params["orderId"] : params["order"]["orderId"]
      )
    end

    private
    
    def complete_order(order)
      return if order.confirmation_delivered?
      order.update!(confirmation_delivered: true) 
    end
  end
end
