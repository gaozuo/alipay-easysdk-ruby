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
    merchant_private_key: 'MIIEpAIBAAKCAQEAvj1if+DJ6Q+D5m72q2cT2nFiYjNREM4l4gvr1w/DuNEs6+1d4j6oCxHstIb718TIqF1FWfJc3K0RQgBOOsxkcXvyvPIhwumEN6sXLMQiEuq5mDKvaDcoIQJ0FC6784LzhORzy1IAGNFCZpeg4DfgukOM9x8v+Q8/NGbcvyVWbPRWoQq52DPSLFMK1Q2ZYpMQMFMix8g3Gf4BJLB9Ya9n5aVcxrFWmjstSEqn5H+lCxBzwWkTsFBOK5itashHvNCTKy7An0U2xh4slh8wiYL8QwD5Qz7S++UkU+vY2HhY81qOTBQbrjapx7qy03C7Sy8cOeRMeXdn64y0xD+E1vTL6QIDAQABAoIBACx5+X9gNJRydin3o1/rV27ot1GyIa/GIoE4vEipfN7GuLPn6N0uPOdpp2eFb3fAoBEMzVv8F83YAILnw2JnysvlaJjYGyCQq8LAE0j6CeVWT1HP98ZrrswY4L6fNn32DazyJEhSwYcL1XRa2tfQ+I9Tn69e8T5PXD2KFu3xcsVB615ipPQ5TEToi2fJ31apir1AYKfDK4dd/0JwK6HUhPXuOf5GZ4Vdq6zkZYSLV8rJA+5MsQYPA3TwszEIrOe1YeQelvNmB2Rl2oCV6rigIPtfnaEFi9GfaKfGiE4r2bBb24NliS6ruflel92jeiJ0+mAT8GE7zVXnX5Sx8BVYHqECgYEA64haWxKv5Q/ujkSbfRRM+CnD1JWdQdPEdh/IxG9fsdgCS72YPypWkSwikAObOrijQf2GTp1bne9Zk9hueQ2tVOrUG9XxEELlJNqkXCufCgrABTEvSUJV+qAZgyalFDe00Z+nJPHZtRmWFjnFLDCJtEnYsVFcQ6v/KvmVO7bMOj0CgYEAzsVzEBiEN/4jL7w7lxnDNp8VznG6W6bnuu4xGlIcziwPIpqeOWzMf90zHRvsh6AsDfzzMDoEvHdj44JQN83xQm/L+Q/R8s+XSB4d6UavfVbApxHGE1iINS2Au0R8SfnPCpQl6WY8IWftL/YCccQUgBRuG9sDI69iaCP+g661Lx0CgYAqkdFq5ny+FNwUAJhtye6DZ+EKGiR7ElBO3T3HKy4LkbQQhmru97L/uA9jIhO7UEXJlo3gxZYafHkfPJ3y6SLr1ymRAmD4hG6v84iDVCsBgKHmDlaykffCPY9+4cwyVEMtJALsrX2gusgiqjxV2Uv6NuKgYckgPgT3enabfVV6LQKBgQCXcqPejDZ71JbtJc/30pTbcxZDyaUX8F4W2tP4VWBn2nmTfPCbWwdGODxx+7v5cuYRsM5m6ngBmuj9ALvExAEMClq6KE48rLQ/zF9YN7/d7Cbbt/b+wH+zg4qgn37xqBlvxCcolws/5KEj2ercbSQe09f6ayYXgyRu5r5KsTJgOQKBgQDcyFC5taNAfGHU5b1k5TLPdTPSEQiBd3//uCH2wXSnj7K8mMLEigS0GIlNlQPjn1h9Hoed9me4zJiRLAKdMTEZQ0ZtevELYFkkC+D9IHpLdKvIFycGpKR/DpZBSTr2LETn1WeZc3LR3ijDixpxH4PqUivkSZl/vnsTSPZsNgCsMg==',
    alipay_public_key: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAvj1if+DJ6Q+D5m72q2cT2nFiYjNREM4l4gvr1w/DuNEs6+1d4j6oCxHstIb718TIqF1FWfJc3K0RQgBOOsxkcXvyvPIhwumEN6sXLMQiEuq5mDKvaDcoIQJ0FC6784LzhORzy1IAGNFCZpeg4DfgukOM9x8v+Q8/NGbcvyVWbPRWoQq52DPSLFMK1Q2ZYpMQMFMix8g3Gf4BJLB9Ya9n5aVcxrFWmjstSEqn5H+lCxBzwWkTsFBOK5itashHvNCTKy7An0U2xh4slh8wiYL8QwD5Qz7S++UkU+vY2HhY81qOTBQbrjapx7qy03C7Sy8cOeRMeXdn64y0xD+E1vTL6QIDAQAB',
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
    .optional('seller_id', '2088102147948060')
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
