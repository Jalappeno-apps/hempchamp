require 'uri'
require 'net/http'

# 
# usage options = { :order_id => order.id,
#             :description    => "Some description",
#             :referrer       => request.env['HTTP_REFERER'],
#             :user_agent     => request.env['HTTP_USER_AGENT'],
#             :ip             => request.remote_ip,
#             :ext_order_id   => "123",
#             :customer       => { 
#               :first_name     => user.first_name,
#               :last_name      => user.last_name,
#               :email          => user.email,
#               :phone          => user.phone,
#               :language       => user.locale 
#             }
#             :products       => [{
#               :name           => product.name
#               :unit_price      => product.unit_price,
#               :quantity       => product.quantity 
#             }]
#           }

class Spree::Gateway::PayuPolska < Spree::Gateway
  attr_accessor :client_secret, :notify_url, :api_url, :options, :app_token

  self.inheritance_column = :_type_disabled

  preference :client_id, :string
  preference :merchant_pos_id, :string
  preference :client_secret, :password
  preference :notify_url, :string
  preference :api_url, :string

  def type
    self.to_s
  end

  def new(options = {})
    @merchant_pos_id = options[:merchant_pos_id]
    @client_secret = options[:client_secret]
    @notify_url = options[:notify_url]
    @api_url = options[:api_url]
  end

  def display_name 
    'PayU Polska'
  end

  def provider_class
    self
  end

  def payment_source_class
    Check
  end

  def method_type
    'payu'
  end

  def auto_capture?
    false
  end

  def purchase(money, options = {})
    post = {}

    add_invoice(post, money, options)
    add_customer_data(post, options)

    authorize(options)
    commit('api/v2_1/orders', post)
  end

  def app_token_from(response)
    @app_token = response['access_token']
  end

  def app_token_request
    {
      grant_type: "client_credentials",
      client_id: preferences[:client_id],
      client_secret: preferences[:client_secret]
    }
  end

  def authorize(options = {})
    response = commit('pl/standard/user/oauth/authorize', app_token_request)
    app_token_from(response)
  end

  def capture(money, authorization, options = {})
    commit('capture', post)
  end

  def refund(money, authorization, options = {})
    commit('refund', post)
  end

  def void(authorization, options = {})
    commit('void', post)
  end

  def verify(credit_card, options = {})
    MultiResponse.run(:use_first_response) do |r|
      r.process { authorize(100, credit_card, options) }
      r.process(:ignore_result) { void(r.authorization, options) }
    end
  end

  def supports_scrubbing?
    false
  end

  def scrub(transcript)
    transcript
  end

  private

  def add_customer_data(post, options)
    post[:buyer] = {}
    post[:buyer][:email] = options&.dig(:email)
    post[:buyer][:phone] = options&.dig(:phone)
    post[:buyer][:firstName] = options[:customer]&.dig(:first_name)
    post[:buyer][:lastName] = options[:customer]&.dig(:last_name)
    post[:buyer][:language] = options[:customer]&.dig(:language)
  end

  def add_invoice(post, money, options)
    post[:totalAmount] = money.to_i * 100
    post[:currencyCode] = 'PLN'
    post[:description] = options[:description]
    post[:customerIp] = options[:ip]
    post[:merchantPosId] = options[:merchantPosId]
    # post[:extOrderId] = options&.dig(:ext_order_id)
    post[:products] = options[:products].map do |product|
      {
        name: product&.dig(:name),
        unitPrice: product&.dig(:unit_price).to_i * 100,
        quantity: product&.dig(:quantity)
      }
    end
  end

  def parse(body)
    JSON.parse(body)
  end

  def response_builder(response)
    Response.new(
      success_from(response),
      message_from(response),
      response,
      authorization: authorization_from(response),
      avs_result: AVSResult.new(code: response['some_avs_response_key']),
      cvv_result: CVVResult.new(response['some_cvv_response_key']),
      test: test?,
      error_code: error_code_from(response)
    )
  end

  def headers
    headers = {
      'Content-Type' => "application/json"
    }

    headers['Authorization'] = "Bearer #{@app_token}" if @app_token
    headers
  end

  def commit(action, parameters)
    if action == 'pl/standard/user/oauth/authorize'
      post_url = "#{preferences[:api_url]}/#{action}?#{parameters.to_query}"
      uri = URI(post_url)

      request = Net::HTTP::Post.new(uri.path)
      request.set_form_data(parameters)
    else
      post_url = "#{preferences[:api_url]}/#{action}"
      uri = URI(post_url)
      
      request = Net::HTTP::Post.new(uri, headers)
      request.content_type = "application/json"
      
      request.body = JSON.dump(parameters)
    end

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    parse(response.body)
  end

  def success_from(response); end

  def message_from(response); end

  def authorization_from(response); end

  def error_code_from(response)
    unless success_from(response)
      # TODO: lookup error code for this response
    end
  end
end
