# frozen_string_literal: true

class PayuCreateOrder
  class << self
    def execute!(order_id, token, ip_address)
      order = Spree::Order.find_by(number: order_id)
      uri = URI.parse ENV["PAYU_ORDER_URL"]

      all_products = order.line_items.map do |p|
        { name: p.name, unitPrice: p.display_amount.money.fractional, quantity: p.quantity }
      end

      order_req = JSON.dump({
        "notifyUrl": ENV['PAYU_NOTIFY_URL'],
        "customerIp": ip_address,
        "merchantPosId": ENV['PAYU_MERCHANT_POS_ID'],
        "description": ENV['PAYU_INVOICE_DESCRIPTION'],
        "currencyCode": "PLN",
        "extOrderId": order.number,
        "totalAmount": order.display_total.money.fractional,
        "buyer": {
          "email": order.email,
          "phone": order.shipping_address.phone,
          "firstName": order.shipping_address.firstname,
          "lastName": order.shipping_address.lastname
        },
        "products": all_products,
        "redirectUri": "http://bhpartykuly.pl/store_return",
        "continueUrl": "http://bhpartykuly.pl/store_return/?order=#{order.number}"
      })

      # Create the HTTP objects
      https = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = "application/json"
      request["Authorization"] = "Bearer #{token}"
      request.body = order_req
      https.use_ssl = true

      # Send the request
      response = https.request(request)
      response_parsed = JSON.parse(response.body)
      order.update!(payu_order_id: response_parsed["orderId"])

      response_parsed["redirectUri"]
    end
  end
end
