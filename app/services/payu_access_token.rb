# frozen_string_literal: true

class PayuAccessToken
  class << self
    def execute!
      uri = URI.parse(ENV['PAYU_AUTH_URL'])
      access_ask = "grant_type=client_credentials&client_id=#{ENV['PAYU_CLIENT_ID']}&client_secret=#{ENV['PAYU_CLIENT_SECRET']}"

      # Create the HTTP objects
      https = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = access_ask
      https.use_ssl = true

      # Send the request
      response = https.request(request)
      begin
        JSON.parse(response.body)["access_token"]
      rescue JSON::ParserError
        puts "Error completing PayU order, server down? #{response.body}"
      end
    end
  end
end
