# frozen_string_literal: true

class Spree::PaymentMethod::Payu < Spree::PaymentMethod
  def actions
    %w{void}
  end

  def method_type
    "payu"
  end

  def void(*)
    ActiveMerchant::Billing::Response.new(true, "PaymentCancelled", {}, {})
  end

  def credit(amount, source, options = {})
    response = PayuRefundOrder.execute!(
      amount,
      options[:originator].reimbursement.order.id,
      options[:originator].reimbursement.id
    )

    return ActiveMerchant::Billing::Response.new(
      false,
      "PayU error(#{response["status"]["code"]}): " + response["status"]["statusCode"] + ", " + response["status"]["statusDesc"],
      {},
      {}
    ) if response["status"]["statusCode"].include?("ERROR")

    if response["status"]["statusCode"] == "SUCCESS"
      ActiveMerchant::Billing::Response.new(
        false,
        "PayU: " + response["status"]["statusCode"] + " " + response["status"]["statusDesc"],
        {},
        {}
      )
    else
      ActiveMerchant::Billing::Response.new(
        false,
        response["status"]["statusCode"] + ", " + response["status"]["statusDesc"],
        {},
        {}
      )
    end
  end

  # def provider_class
  #   self.class
  # end

  # def self.success?
  #   true
  # end

  def source_required?
    false
  end
end