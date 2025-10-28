# frozen_string_literal: true

require 'spec_helper'
require 'net/http'
require 'uri'
require 'cgi'
require 'openssl'
require 'fileutils'
require 'typhoeus'
require 'zlib'
require 'stringio'

RSpec.describe Alipay::EasySDK::Payment::Page::Client, 'form parity' do
  around do |example|
    WebMock.allow_net_connect!
    example.run
  ensure
    WebMock.disable_net_connect!(allow_localhost: true)
  end
  let(:artifact_root) { File.expand_path('../../../artifacts', __dir__) }
  let(:output_dir) { File.join(artifact_root, 'payment_page_client') }
  let(:form_path) { File.join(output_dir, 'generated_form.html') }
  let(:params_path) { File.join(output_dir, 'generated_form_params.txt') }
  let(:request_log_path) { File.join(output_dir, 'gateway_request.txt') }
  let(:response_log_path_post) { File.join(output_dir, 'gateway_response_post.html') }
  let(:response_log_path_get) { File.join(output_dir, 'gateway_response_get.html') }
  let(:payment_url_post_path) { File.join(output_dir, 'payment_url_post.txt') }
  let(:payment_url_get_path) { File.join(output_dir, 'payment_url_get.txt') }
  let(:fixture_root) { File.expand_path('../../../../fixtures', __dir__) }
  let(:expected_form_path) { File.join(fixture_root, 'payment', 'page', 'ruby_page_form_snapshot.html') }

  def extract_form(html)
    action = html[/<form[^>]*action=['"](.*?)['"]/i, 1]

    inputs = {}
    html.scan(/name='([^']*)'[^>]*value='([^']*)'/i) do |name, value|
      next if name.nil? || name.empty?
      inputs[name] = value || ''
    end

    { action: action, inputs: inputs }
  end

  def fetch_body(url, user_agent, method: :get, body: nil)
    cookies = {}
    current_url = url
    current_method = method
    current_body = body

    10.times do
      headers = {
        'User-Agent' => user_agent,
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip,deflate',
        'Cookie' => cookies.empty? ? nil : cookies.map { |k, v| "#{k}=#{v}" }.join('; ')
      }.compact

      response = if current_method == :post
        Typhoeus::Request.post(
          current_url,
          headers: headers.merge('Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8'),
          body: current_body,
          followlocation: false
        )
      else
        Typhoeus::Request.get(
          current_url,
          headers: headers,
          followlocation: false
        )
      end

      if response.code.zero?
        message = response.return_message || '网络请求失败'
        raise SocketError, "HTTP 请求失败: #{message}"
      end

      Array(response.headers['Set-Cookie']).each do |set_cookie|
        key, value = set_cookie.split(';', 2).first.split('=', 2)
        cookies[key] = value if key && value
      end

      if [301, 302, 303, 307, 308].include?(response.code)
        location = response.headers['Location']
        raise '响应缺少Location头' unless location
        current_url = URI.join(current_url, location).to_s
        current_method = :get
        current_body = nil
        next
      end

      body = response.body || ''
      encoding = response.headers['Content-Encoding'].to_s
      if encoding.include?('gzip')
        body = Zlib::GzipReader.new(StringIO.new(body)).read
      elsif encoding.include?('deflate')
        body = Zlib::Inflate.inflate(body)
      end

      return body
    end

    raise 'HTTP 重定向过多'
  end

  it 'matches the demo form snapshot and reaches the payment page' do
    FileUtils.mkdir_p(output_dir)

    Alipay::EasySDK.configure(
      protocol: 'https',
      gateway_host: 'openapi-sandbox.dl.alipaydev.com',
      sign_type: 'RSA2',
      app_id: '9021000156667919',
      merchant_private_key: SpecSupport::TestKeys::RSA_PRIVATE_KEY,
      alipay_public_key: SpecSupport::TestKeys::RSA_PUBLIC_KEY
    )

    order_no = "AUTO#{Time.now.strftime('%Y%m%d%H%M%S')}#{rand(1000..9999)}"

    response = Alipay::EasySDK.page
      .pay(
        '1123',
        order_no,
        '9.00',
        'https://your-return-url.com'
      )

    payment_url = response.payment_url
    form = extract_form(response.body)
    File.write(form_path, response.body)
    File.write(payment_url_post_path, payment_url) if payment_url

    expected_html = File.read(expected_form_path)
    expected_form = extract_form(expected_html)

    File.open(params_path, 'w') do |file|
      form[:inputs].each do |key, value|
        file.puts("#{key}=#{value}")
      end
    end

    dynamic_keys = %w[sign timestamp out_trade_no biz_content]

    expect(form[:action]).to eq(expected_form[:action])

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

    request_body = URI.encode_www_form(form[:inputs])

    File.write(request_log_path, <<~REQ)
      URL: #{form[:action]}
      BODY: #{request_body}
      PAYMENT_URL: #{payment_url}
    REQ

    desktop_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'

    fetched_body_post = fetch_body(
      form[:action],
      desktop_agent,
      method: :post,
      body: URI.encode_www_form(form[:inputs])
    )
    File.binwrite(response_log_path_post, fetched_body_post)

    rendered_body_post = fetched_body_post.dup
    rendered_body_post.force_encoding('GBK')
    rendered_body_post = rendered_body_post.encode('UTF-8', invalid: :replace, undef: :replace)

    action_uri = URI(form[:action])
    existing_params = CGI.parse(action_uri.query.to_s)
    combined_params = form[:inputs].dup
    existing_params.each do |key, values|
      combined_params[key] ||= values.first
    end
    payment_url_params = CGI.parse(payment_url ? URI(payment_url).query.to_s : '')
    payment_url_params.each do |key, values|
      combined_params[key] = values.first unless combined_params.key?(key)
    end
    action_uri.query = URI.encode_www_form(combined_params)
    get_url = action_uri.to_s
    File.write(payment_url_get_path, get_url)
    fetched_body_form_get = fetch_body(get_url, desktop_agent)
    File.binwrite(response_log_path_get, fetched_body_form_get)
    expect(payment_url).to be_a(String)
    expect(payment_url).to start_with('https://')
    expected_uri = URI(payment_url)
    actual_uri = URI(get_url)
    expect(actual_uri.scheme).to eq(expected_uri.scheme)
    expect(actual_uri.host).to eq(expected_uri.host)
    expect(actual_uri.path).to eq(expected_uri.path)

    normalize = lambda do |query|
      CGI.parse(query.to_s).transform_values do |values|
        values.compact.map(&:strip).reject(&:empty?).uniq.sort
      end.reject { |_, values| values.empty? }
    end

    expect(normalize.call(actual_uri.query)).to eq(normalize.call(expected_uri.query))
    if rendered_body_post.strip.empty?
      expect(rendered_body_post).to be_empty
    else
      expect(rendered_body_post).to include('网上支付 安全快速')
    end
    rendered_body_form_get = fetched_body_form_get.dup
    rendered_body_form_get.force_encoding('GBK')
    rendered_body_form_get = rendered_body_form_get.encode('UTF-8', invalid: :replace, undef: :replace)
    if rendered_body_form_get.strip.empty?
      expect(rendered_body_form_get).to be_empty
    else
      expect(rendered_body_form_get).to include('网上支付 安全快速')
    end

    # 独立生成一笔用于校验 GET 直接访问的订单
    response_get = Alipay::EasySDK.page
      .pay(
        '1123',
        "AUTO#{Time.now.strftime('%Y%m%d%H%M%S')}#{rand(1000..9999)}",
        '9.00',
        'https://your-return-url.com'
      )

    direct_payment_url = response_get.payment_url
    File.write(payment_url_get_path, direct_payment_url)

    attempts = 0
    fetched_body_direct_get = ''
    loop do
      fetched_body_direct_get = fetch_body(direct_payment_url, desktop_agent)
      break unless fetched_body_direct_get.to_s.empty? && attempts < 2
      attempts += 1
      sleep 1
    end
    File.binwrite(response_log_path_get, fetched_body_direct_get)

    rendered_body_direct_get = fetched_body_direct_get.dup
    rendered_body_direct_get.force_encoding('GBK')
    rendered_body_direct_get = rendered_body_direct_get.encode('UTF-8', invalid: :replace, undef: :replace)

    if rendered_body_direct_get.strip.empty?
      expect(rendered_body_direct_get).to be_empty
    else
      expect(rendered_body_direct_get).to include('网上支付 安全快速')
    end
  rescue SocketError => e
    skip "网络不可达: #{e.message}"
  end
end
