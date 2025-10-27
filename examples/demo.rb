#!/usr/bin/env ruby

require 'alipay/easysdk'
require 'net/http'
require 'uri'
require 'cgi'
require 'openssl'

# ------------------ 辅助方法（完全对应 PHP 版逻辑） ------------------

def get_options
  Alipay::EasySDK::Kernel::Config.new(
    protocol: 'https',
    gateway_host: 'openapi-sandbox.dl.alipaydev.com',
    sign_type: 'RSA2',
    app_id: '9021000156667919',
    merchant_private_key: 'MIIEogIBAAKCAQEAmy8gfxY5RFBKixIWoflLqULF1gZ43QdlEYln+1f0k+tbiWbhi3DBOKp9gjgGmOJmBzVuaDQ+VMDmrolIc8tOz6urQU2PSjMSSqLub3xwyxiZO2qjfkn5riO68ITkr3RN7zVyZcheoaTfexygtg7xH8eqbqhghnVs97KwKnkIt7mzhIvbs60qrV8YAkbm6Hw85s4BVBoBleFZPQCBDXffVTz72GGu5iFHcbVoZdtT2GKPWWiaYb9BEuzzmUo41pPdHrMYP0VnR9UdGnLZyC70YXQ6ZshRux0/rkIrxLGVlk5UBTqdxtP8r2oqoVLl4L5tBcTw4gRPqL4+UiDQ7YE3ZQIDAQABAoIBAHhcqhjIFOy+VcLd6b4BjMSgbK+e33mXtbVPXN4ejy13e8zrhf5QGx2nZqdsavmDh90JfTPHaZz07TbsdcySIPOD09VXoc7MI+DN1J+V5iowTxE9mcdm+wgs4F6SxIitbZEeZDc7nOJE7a0gPCpZFn4usCsZ35wKUdUgu/CFZdSRNdSKBdwdDQcMA/rClHqDvIeCBAbK979cr4/ltAofBQTt9YhZsXpChSQZOnyYFRBPtlblthPcJQOhN6ZH7EsNftdh+elHNjNaH+a6fcCiS4J9yhEtqeQs0ZGDSsE3b7zHW+cOaicvE4X9U651ipVxkYXRK1WhfctRF/cjzqsVtNUCgYEA30NT2kk3CLc8/gXEm/oitEkLx3gp+eH5gLrAE41fcTUloeg+bHXPqQh0IFyLTNUIJ4RF/HdlqHFciKVDUN5HVZeG/RAB3BgTpQV174LuebRs6Fuj3T/qvaV9GdKsTMwnZpljsTJJFiQNMW/vczmy+HbPeMO4r1TWk8GgaD4580MCgYEAsfBObh5dC9D9hIkPIaxZFdAIhmWN8MF3WbEg0LI3YzjW9b6Qd6rn9IyB2UtM4u+lseiLe5XMrR1nzwgxyELyr/w2Mov2F9Zf/DhUqPv/qpegu7xD6U8ca4fJMYfN3sT9R2M3P074U15MlPjBEojtSwg/4oBEcono43+lcRiI/DcCgYAHp6BNYKtBYj72Gq6GBoqAEe0UdrtBtQy/7Cc/xF4cXI0gwvy47UUkb4TDw0iHZtpzuGZJ5LIYl2Jr0PbA5A4gEiTvskfOCwlJZCmJ/7w7cgM16EZzBIkA3ZavdvivXWSQcPvpDGdTGgNVyZe1JKpNOI2ef19qq4b74+yjBlcoTwKBgA/vUkbAR1rgi2OMFqPQWGYArFLE03JFERgiKasm2pjzJST6vNtKnd0jnBlGigskpPUKuzsFDkBOitZaiILDpBIohv391LsLwqrGrKY5cwrm60kEshw5rnTewyDBZalWgMwc0XzE6K4mmrsYj8nGI2H9yiLRk8+iFA4Th1BafyH/AoGAcQHDXuNR0inKvsoEX1hYAoYmE7GwYcxl88AdrAnfqJHgdxHaWCKb/gYiXqRR0RFhiAEZCuVm9IvJ6Dh2eR2psC9lyixgQiyiJYLSA1sLzVzQS/OkSpC3w5srcwxOWzRTBreZbGzV+zJqh9NBCQt0S3Bq2Mi1qYxzxUAytlYSdrQ=',
    alipay_public_key: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmy8gfxY5RFBKixIWoflLqULF1gZ43QdlEYln+1f0k+tbiWbhi3DBOKp9gjgGmOJmBzVuaDQ+VMDmrolIc8tOz6urQU2PSjMSSqLub3xwyxiZO2qjfkn5riO68ITkr3RN7zVyZcheoaTfexygtg7xH8eqbqhghnVs97KwKnkIt7mzhIvbs60qrV8YAkbm6Hw85s4BVBoBleFZPQCBDXffVTz72GGu5iFHcbVoZdtT2GKPWWiaYb9BEuzzmUo41pPdHrMYP0VnR9UdGnLZyC70YXQ6ZshRux0/rkIrxLGVlk5UBTqdxtP8r2oqoVLl4L5tBcTw4gRPqL4+UiDQ7YE3ZQIDAQAB',
    encrypt_key: 'rEoolKE9DfJIQHMMelZapw=='
  )
end

def extract_action_url(form_html)
  match = form_html.match(/action=['"](.*?)['"]/)
  return nil unless match

  url = match[1]
  begin
    parsed_uri = URI.parse(url)
    "#{parsed_uri.scheme}://#{parsed_uri.host}#{parsed_uri.path}"
  rescue URI::InvalidURIError
    url
  end
end

def extract_all_form_params(form_html)
  params = {}
  form_html.scan(/<input[^>]*name=['"](.*?)['"][^>]*value=['"](.*?)['"][^>]*>/i) do |name, value|
    params[name] = CGI.unescapeHTML(value)
  end
  params
end

def send_post_request(url_string, params)
  uri = URI.parse(url_string)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if uri.scheme == 'https'

  post_data = params.map { |key, value| "#{CGI.escape(key)}=#{CGI.escape(value)}" }.join('&')

  puts "发送POST请求到: #{url_string}"
  puts "POST数据: #{post_data}"

  headers = {
    'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
    'Accept' => '*/*',
    'Accept-Charset' => 'UTF-8',
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  }

  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = post_data

  response = http.start { |client| client.request(request) }

  if response.code.to_i >= 300 && response.code.to_i < 400
    location = response['location']
    if location
      puts "检测到重定向到: #{location}"
      return send_post_request(location, params)
    end
  end

  puts "HTTP响应码: #{response.code}"
  puts "响应长度: #{response.body.length} 字节"

  unless response.code.to_i == 200
    puts "响应内容预览: #{response.body[0, 500]}..."
    raise "HTTP请求失败，响应码: #{response.code}"
  end

  response.body
end

def save_response_to_file(content, filename)
  File.write(filename, content)
end

# ------------------ 主流程 ------------------

begin
  Alipay::EasySDK::Kernel::Factory.set_options(get_options)

  response = Alipay::EasySDK::Kernel::Factory.payment
    .wap
  .pay(
      '1123',
      '70501111111S001111119',
      '9.00',
      'https://your-quit-url.com',
      'https://your-return-url.com'
    )

  response_checker = Alipay::EasySDK::Kernel::Util::ResponseChecker.new

  if response_checker.success(response)
    puts '调用成功'
    puts "支付表单HTML: #{response.body}"

    form_html = response.body
    action_url = extract_action_url(form_html)
    all_params = extract_all_form_params(form_html)

    puts "Action URL: #{action_url}"
    puts "表单参数数量: #{all_params.size}"
    all_params.each do |key, value|
      puts "  #{key}: #{value}"
    end

    if action_url && !all_params.empty?
      post_response = send_post_request(action_url, all_params)
      save_response_to_file(post_response, 'alipay_ruby_response.txt')
      puts '响应已保存到 alipay_ruby_response.txt'
    end
  else
    puts "调用失败，原因：#{response.error_message}"
  end
rescue => e
  puts "调用遭遇异常，原因：#{e.message}"
  puts e.backtrace.join("\n") if ENV['DEBUG']
  raise e
end
