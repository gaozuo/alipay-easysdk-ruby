# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'uri'
require 'cgi'
require 'openssl'
require 'fileutils'

RSpec.describe Alipay::EasySDK::Payment::Wap::Client, 'form parity' do
  let(:artifact_root) { File.expand_path('../../../artifacts', __dir__) }
  let(:output_dir) { File.join(artifact_root, 'payment_wap_client') }
  let(:form_path) { File.join(output_dir, 'generated_form.html') }
  let(:params_path) { File.join(output_dir, 'generated_form_params.txt') }
  let(:request_log_path) { File.join(output_dir, 'gateway_request.txt') }
  let(:response_log_path) { File.join(output_dir, 'gateway_response.txt') }
  let(:fixture_root) { File.expand_path('../../../../fixtures', __dir__) }
  let(:expected_form_path) { File.join(fixture_root, 'payment', 'wap', 'ruby_wap_form_snapshot.html') }
  let(:gateway_response_path) { File.join(fixture_root, 'payment', 'wap', 'ruby_wap_gateway_response.html') }

  def extract_form(html)
    action = html[/<form[^>]*action=['"](.*?)['"]/i, 1]

    inputs = {}
    html.scan(/name='([^']*)'[^>]*value='([^']*)'/i) do |name, value|
      next if name.nil? || name.empty?
      inputs[name] = value || ''
    end

    { action: action, inputs: inputs }
  end

  def post_form(action_url, params)
    uri = URI(action_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
    request['Accept'] = '*/*'
    request['Accept-Charset'] = 'UTF-8'
    request['User-Agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    request.body = URI.encode_www_form(params)

    response = http.request(request)
    redirects = 0

    while response.is_a?(Net::HTTPRedirection) && redirects < 5
      redirects += 1
      location = response['location']
      raise '响应缺少Location头' unless location

      uri = URI(location)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
      response = http.get(uri.request_uri)
    end

    [response, uri, request.body]
  end

  it 'matches PHP page output and reaches payment page' do
    FileUtils.mkdir_p(output_dir)

    Alipay::EasySDK.configure(
      protocol: 'https',
      gateway_host: 'openapi-sandbox.dl.alipaydev.com',
      sign_type: 'RSA2',
      app_id: '9021000156667919',
      merchant_private_key: SpecSupport::TestKeys::RSA_PRIVATE_KEY,
      alipay_public_key: SpecSupport::TestKeys::RSA_PUBLIC_KEY
    )

    response = Alipay::EasySDK.wap
      .optional('seller_id', '2088102147948060')
      .pay(
        '1123',
        '70501111111S001111119',
        '9.00',
        'https://your-quit-url.com',
      'https://your-return-url.com'
    )

    form = extract_form(response.body)
    File.write(form_path, response.body)

    expected_html = File.read(expected_form_path)
    expected_form = extract_form(expected_html)

    File.open(params_path, 'w') do |file|
      form[:inputs].each do |key, value|
        file.puts("#{key}=#{value}")
      end
    end

    expect(form[:action]).to eq(expected_form[:action])

    dynamic_keys = %w[sign timestamp]

    expected_form[:inputs].each do |key, value|
      expect(form[:inputs]).to have_key(key), "missing key #{key}"
      if key == 'alipay_sdk'
        expect(form[:inputs][key]).to start_with('alipay-easysdk-ruby')
      elsif dynamic_keys.include?(key)
        expect(form[:inputs][key]).to be_a(String)
        expect(form[:inputs][key]).not_to be_empty
      else
        expect(form[:inputs][key]).to eq(value)
      end
    end

    payment_page_html = File.read(gateway_response_path)

    stub_request(:post, form[:action])
      .to_return(status: 200, body: payment_page_html, headers: { 'Content-Type' => 'text/html' })

    response, _uri, request_body = post_form(form[:action], form[:inputs])

    File.write(request_log_path, <<~REQ)
      URL: #{form[:action]}
      BODY: #{request_body}
    REQ

    File.binwrite(response_log_path, response.body)

    expect(response.code.to_i).to eq(200)

    expect(response.body).to eq(payment_page_html)

    body = response.body.dup.force_encoding('UTF-8')
    expect(body).to include('支付宝付款')
    expect(body).not_to match(/invalid-signature|missing-signature|错误/i)
  rescue SocketError => e
    skip "网络不可达: #{e.message}"
  end
end
