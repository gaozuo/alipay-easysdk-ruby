#!/usr/bin/env ruby

require 'alipay/easysdk'
require 'net/http'
require 'uri'
require 'json'
require 'cgi'

# 如果没有nokogiri，使用简单的正则表达式解析
begin
  require 'nokogiri'
rescue LoadError
  # Nokogiri not available, will use regex fallback
end

# 从HTML表单中提取action URL - 按照PHP版本逻辑
def extract_action_url(form_html)
  # 使用正则表达式提取action URL
  if match = form_html.match(/action=['"](.*?)['"]/)
    url = match[1]
    # 移除URL中的查询参数，因为不应该在URL中包含参数
    begin
      parsed_uri = URI.parse(url)
      "#{parsed_uri.scheme}://#{parsed_uri.host}#{parsed_uri.path}"
    rescue
      url
    end
  end
end

# 从HTML表单中提取所有input参数 - 按照PHP版本逻辑
def extract_all_form_params(form_html)
  params = {}

  # 尝试使用Nokogiri
  begin
    doc = Nokogiri::HTML(form_html)
    doc.css('input').each do |input|
      name = input['name']
      value = input['value']

      if name && !name.empty?
        # HTML解码
        decoded_value = CGI.unescapeHTML(value)
        params[name] = decoded_value
      end
    end
  rescue
    # Nokogiri不可用时，使用正则表达式
    form_html.scan(/<input[^>]*name=['"](.*?)['"][^>]*value=['"](.*?)['"][^>]*>/) do |match|
      name = match[0]
      value = match[1]
      if name && !name.empty?
        decoded_value = CGI.unescapeHTML(value)
        params[name] = decoded_value
      end
    end
  end

  params
end

# 从action URL中提取查询参数 - Ruby版本特有
def extract_url_params(action_url_with_params)
  params = {}

  begin
    parsed_uri = URI.parse(action_url_with_params)
    if parsed_uri.query
      # 解析查询参数
      query_params = CGI.parse(parsed_uri.query)
      query_params.each do |key, values|
        # CGI.parse返回数组，我们取第一个值
        params[key] = values[0] unless values.empty?
      end
    end
  rescue => e
    puts "解析URL参数时出错: #{e.message}"
  end

  params
end

# 发送POST请求 - 按照PHP版本逻辑
def send_post_request(url_string, params)
  puts "调试：发送POST请求到URL = #{url_string}"
  uri = URI.parse(url_string)
  puts "调试：URI解析结果 scheme=#{uri.scheme}, host=#{uri.host}, port=#{uri.port}"
  http = Net::HTTP.new(uri.host, uri.port)

  # 正确处理HTTPS
  if uri.scheme == 'https'
    puts "调试：启用HTTPS"
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  else
    puts "调试：使用HTTP（scheme=#{uri.scheme}）"
  end

  # 构建POST数据，包含所有参数（包括sign） - 按字母顺序排列（与签名生成时一致）
  # 注意：sign参数需要包含在POST请求中，但不参与签名排序
  post_params = params.dup
  sign_value = post_params.delete('sign')  # 临时移除sign参数

  # 对其他参数按字母排序
  sorted_params = Hash[post_params.sort_by { |key, _| key }]

  # 构建POST数据（先排序的参数，最后加上sign）
  post_data_parts = sorted_params.map { |key, value|
    "#{URI.encode_www_form_component(key)}=#{URI.encode_www_form_component(value)}"
  }

  # 如果有sign参数，添加到最后
  if sign_value
    post_data_parts << "#{URI.encode_www_form_component('sign')}=#{URI.encode_www_form_component(sign_value)}"
  end

  post_data = post_data_parts.join('&')

  headers = {
    'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
    'Accept' => '*/*',
    'Accept-Charset' => 'UTF-8',
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
  }

  puts "发送POST请求到: #{url_string}"
  puts "POST数据: #{post_data}"

  request = Net::HTTP::Post.new(uri.request_uri, headers)
  request.body = post_data

  # 跟随重定向（按照PHP版本的curl设置）
  http.use_ssl = true if uri.scheme == 'https'
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE if uri.scheme == 'https'

  # 启用自动重定向跟随
  http.start do |http|
    response = http.request(request)

    puts "HTTP响应码: #{response.code}"
    puts "响应长度: #{response.body.length} 字节"

    # 检查重定向并跟随（类似PHP版本的CURLOPT_FOLLOWLOCATION）
    if response.code.to_i >= 300 && response.code.to_i < 400
      location = response['location']
      if location
        puts "检测到重定向到: #{location}"
        # 如果是重定向，递归调用
        return send_post_request(location, params)
      end
    end

    if response.code.to_i != 200
      puts "HTTP响应头信息:"
      response.each_header do |key, value|
        if key.start_with?('http') || key.downcase == 'location'
          puts "  #{key}: #{value}"
        end
      end
      puts "响应内容预览:"
      puts response.body[0, 500] + "..." if response.body.length > 500
      raise "HTTP请求失败，响应码: #{response.code}"
    end

    return response.body
  end
end

# 将响应保存到文件
def save_response_to_file(content, filename)
  File.write(filename, content)
end

begin
  # 1. 设置配置（全局只需设置一次）- 使用与PHP版本完全相同的配置
  Alipay::EasySDK.configure(
    protocol: 'https',
    gateway_host: 'openapi-sandbox.dl.alipaydev.com',
    sign_type: 'RSA2',
    app_id: '9021000156667919',
    merchant_private_key: 'MIIEogIBAAKCAQEAmy8gfxY5RFBKixIWoflLqULF1gZ43QdlEYln+1f0k+tbiWbhi3DBOKp9gjgGmOJmBzVuaDQ+VMDmrolIc8tOz6urQU2PSjMSSqLub3xwyxiZO2qjfkn5riO68ITkr3RN7zVyZcheoaTfexygtg7xH8eqbqhghnVs97KwKnkIt7mzhIvbs60qrV8YAkbm6Hw85s4BVBoBleFZPQCBDXffVTz72GGu5iFHcbVoZdtT2GKPWWiaYb9BEuzzmUo41pPdHrMYP0VnR9UdGnLZyC70YXQ6ZshRux0/rkIrxLGVlk5UBTqdxtP8r2oqoVLl4L5tBcTw4gRPqL4+UiDQ7YE3ZQIDAQABAoIBAHhcqhjIFOy+VcLd6b4BjMSgbK+e33mXtbVPXN4ejy13e8zrhf5QGx2nZqdsavmDh90JfTPHaZz07TbsdcySIPOD09VXoc7MI+DN1J+V5iowTxE9mcdm+wgs4F6SxIitbZEeZDc7nOJE7a0gPCpZFn4usCsZ35wKUdUgu/CFZdSRNdSKBdwdDQcMA/rClHqDvIeCBAbK979cr4/ltAofBQTt9YhZsXpChSQZOnyYFRBPtlblthPcJQOhN6ZH7EsNftdh+elHNjNaH+a6fcCiS4J9yhEtqeQs0ZGDSsE3b7zHW+cOaicvE4X9U651ipVxkYXRK1WhfctRF/cjzqsVtNUCgYEA30NT2kk3CLc8/gXEm/oitEkLx3gp+eH5gLrAE41fcTUloeg+bHXPqQh0IFyLTNUIJ4RF/HdlqHFciKVDUN5HVZeG/RAB3BgTpQV174LuebRs6Fuj3T/qvaV9GdKsTMwnZpljsTJJFiQNMW/vczmy+HbPeMO4r1TWk8GgaD4580MCgYEAsfBObh5dC9D9hIkPIaxZFdAIhmWN8MF3WbEg0LI3YzjW9b6Qd6rn9IyB2UtM4u+lseiLe5XMrR1nzwgxyELyr/w2Mov2F9Zf/DhUqPv/qpegu7xD6U8ca4fJMYfN3sT9R2M3P074U15MlPjBEojtSwg/4oBEcono43+lcRiI/DcCgYAHp6BNYKtBYj72Gq6GBoqAEe0UdrtBtQy/7Cc/xF4cXI0gwvy47UUkb4TDw0iHZtpzuGZJ5LIYl2Jr0PbA5A4gEiTvskfOCwlJZCmJ/7w7cgM16EZzBIkA3ZavdvivXWSQcPvpDGdTGgNVyZe1JKpNOI2ef19qq4b74+yjBlcoTwKBgA/vUkbAR1rgi2OMFqPQWGYArFLE03JFERgiKasm2pjzJST6vNtKnd0jnBlGigskpPUKuzsFDkBOitZaiILDpBIohv391LsLwqrGrKY5cwrm60kEshw5rnTewyDBZalWgMwc0XzE6K4mmrsYj8nGI2H9yiLRk8+iFA4Th1BafyH/AoGAcQHDXuNR0inKvsoEX1hYAoYmE7GwYcxl88AdrAnfqJHgdxHaWCKb/gYiXqRR0RFhiAEZCuVm9IvJ6Dh2eR2psC9lyixgQiyiJYLSA1sLzVzQS/OkSpC3w5srcwxOWzRTBreZbGzV+zJqh9NBCQt0S3Bq2Mi1qYxzxUAytlYSdrQ=',
    alipay_public_key: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmy8gfxY5RFBKixIWoflLqULF1gZ43QdlEYln+1f0k+tbiWbhi3DBOKp9gjgGmOJmBzVuaDQ+VMDmrolIc8tOz6urQU2PSjMSSqLub3xwyxiZO2qjfkn5riO68ITkr3RN7zVyZcheoaTfexygtg7xH8eqbqhghnVs97KwKnkIt7mzhIvbs60qrV8YAkbm6Hw85s4BVBoBleFZPQCBDXffVTz72GGu5iFHcbVoZdtT2GKPWWiaYb9BEuzzmUo41pPdHrMYP0VnR9UdGnLZyC70YXQ6ZshRux0/rkIrxLGVlk5UBTqdxtP8r2oqoVLl4L5tBcTw4gRPqL4+UiDQ7YE3ZQIDAQAB',
    encrypt_key: 'rEoolKE9DfJIQHMMelZapw=='
  )

  # 2. 发起WAP支付API调用 - 与PHP版本完全相同的参数
  response = Alipay::EasySDK.wap
    .optional("seller_id", "2036665393371081")  # 可选：设置卖家支付宝用户ID
    .pay(
      "1123",                    # 商品名称 - 与PHP版本一致
      "70501111111S001111119",    # 商户订单号
      "9.00",                     # 支付金额
      "https://your-quit-url.com", # 用户付款中途退出返回商户网站的地址
      "https://your-return-url.com"  # 用户付款成功返回商户网站的地址
    )

  # 3. 处理响应或异常
  if response.success?
    puts "调用成功"
    puts "支付表单HTML: #{response.form}" if response.form

    # 4. 提取form表单中的action URL和所有参数 - 完全按照PHP版本逻辑
    form_html = response.form
    action_url = extract_action_url(form_html)
    all_params = extract_all_form_params(form_html)

    puts "Action URL: #{action_url}"
    puts "表单参数数量: #{all_params.length}"
    all_params.each do |key, value|
      puts "  #{key}: #{value}"
    end

    # 5. action URL已经在第4步提取完成，无需重复提取

    # 6. 现在Ruby版本的表单结构与PHP一致，所有参数都在input字段中
    # 直接使用提取的input参数
    combined_params = all_params

    puts "表单参数总数: #{combined_params.length}"

    # 7. 发送POST请求 - 使用基础URL和所有参数
    if action_url && !combined_params.empty?
      post_response = send_post_request(action_url, combined_params)

      # 8. 将响应保存到文件
      save_response_to_file(post_response, "alipay_ruby_response.txt")
      puts "响应已保存到 alipay_ruby_response.txt"
    end

  else
    puts "调用失败，原因：#{response.error_message}"
  end

rescue => e
  puts "调用遭遇异常，原因：#{e.message}"
  puts e.backtrace.join("\n") if ENV['DEBUG']
  raise e
end
