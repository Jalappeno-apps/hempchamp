# frozen_string_literal: true

class PayuCheckStatus
  class << self
    def execute!(order_id, token)
      order = Spree::Order.find_by(number: order_id)
      uri = URI.parse("#{ENV['PAYU_STATUS_URL']}#{order.payu_order_id}")

      # Create the HTTP objects
      https = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.content_type = "application/json"
      request["Authorization"] = "Bearer #{token}"
      https.use_ssl = true

      # Send the request
      response = https.request(request)
      response_parsed = JSON.parse(response.body)
      status = response_parsed["orders"][0]["status"]
      payment = order.payments.last
      puts response.body
      puts status
      if status == "COMPLETED"
        payment.complete! unless payment.completed?
      elsif status == "PENDING"
        payment.update!(state: "balance_due") unless payment.processing?
      elsif status == "CANCELLED"
        order.cancel
      end
    end  
  end
end


