# frozen_string_literal: true

class PayuRefundOrder
  class << self
    def execute!(amount, order_id, refund_id)
      token = PayuAccessToken.execute!
      order = Spree::Order.find(order_id)
      refund = Spree::Reimbursement.find(refund_id)

      uri = URI.parse("https://secure.snd.payu.com/api/v2_1/orders/#{order.payu_order_id}/refunds")


      refund_req = JSON.dump({
        "orderId": order.number,
        "extOrderId": order.payu_order_id,
        "refund": {
          "description": "Refund",
          "refundId": refund.number,
          "amount": amount,
          "totalAmount": amount,
          "currencyCode": refund.display_total.money.currency.iso_code,
          "status": "FINALIZED",
          "reason": "refund",
          "reasonDescription": refund.return_items.first.return_authorization.reason.name,
        }
      })

      # Create the HTTP objects
      https = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = "application/json"
      request["Authorization"] = "Bearer #{token}"
      request.body = refund_req
      https.use_ssl = true

      # Send the request
      response = https.request(request)
      response_parsed = JSON.parse(response.body)
      response_parsed
    end
  end
end
