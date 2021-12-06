# frozen_string_literal: true

class PayuAccessToken
  class << self
    def execute! auth_url, client_id, client_secret
      uri = URI.parse(auth_url)
      access_ask = "grant_type=client_credentials&client_id=#{client_id}&client_secret=#{client_secret}"

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
