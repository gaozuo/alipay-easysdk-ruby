require_relative 'alipay_constants'
require_relative 'config'
require_relative 'util/json_util'
require_relative 'util/signer'
require_relative 'util/sign_content_extractor'
require_relative 'util/aes'
require_relative 'util/page_util'
require 'net/http'
require 'uri'
require 'cgi'
require 'json'

module Alipay
  module EasySDK
    module Kernel
      class EasySDKKernel
        attr_reader :config, :optional_text_params, :optional_biz_params, :text_params, :biz_params

      def initialize(config)
        @config = config
        @optional_text_params = {}
        @optional_biz_params = {}
        @text_params = {}
        @biz_params = {}
      end

      def inject_text_param(key, value)
        if key != nil
          @optional_text_params[key] = value
        end
      end

      def inject_biz_param(key, value)
        if key != nil
          @optional_biz_params[key] = value
        end
      end

      def get_timestamp
        return Time.now.strftime("%Y-%m-%d %H:%M:%S")
      end

      def get_config(key)
        method = key.to_s
        return @config.public_send(method) if @config.respond_to?(method)

        snake = method.gsub(/([A-Z]+)/) { "_#{$1.downcase}" }.sub(/^_/, '')
        return @config.public_send(snake) if @config.respond_to?(snake)

        camel = snake.split('_').inject { |memo, part| memo + part.capitalize }
        return @config.public_send(camel) if camel && @config.respond_to?(camel)

        nil
      end

      def get_sdk_version
        AlipayConstants::SDK_VERSION
      end

      def to_url_encoded_request_body(biz_params)
        sorted_map = get_sorted_map(nil, biz_params, nil)
        if sorted_map.nil? || sorted_map.empty?
          return nil
        end
        build_query_string(sorted_map)
      end

      def read_as_json(response, method)
        response_body = response.body
        map = {}
        map[AlipayConstants::BODY_FIELD] = response_body
        map[AlipayConstants::METHOD_FIELD] = method
        map
      end

      def get_random_boundary
        Time.now.strftime("%Y-%m-%d %H:%M:%S") + ''
      end

      def generate_page(method, system_params, biz_params, text_params, sign)
        puts "[DEBUG] generate_page - sign长度: #{sign.length}" if ENV['DEBUG']
        signed_params = build_signed_params(system_params, biz_params, text_params, sign)
        case method
        when AlipayConstants::GET
          build_gateway_url(signed_params)
        when AlipayConstants::POST
          puts "[DEBUG] generate_page POST - sorted_map中sign长度: #{signed_params[AlipayConstants::SIGN_FIELD].length}" if ENV['DEBUG']
          build_form(get_gateway_server_url, signed_params)
        else
          raise "不支持" + method
        end
      end

      def generate_payment_url(system_params, biz_params, text_params, sign)
        signed_params = build_signed_params(system_params, biz_params, text_params, sign)
        build_gateway_url(signed_params)
      end

      def get_merchant_cert_sn
        return @config.merchant_cert_sn
      end

      def get_alipay_cert_sn(resp_map)
        if !@config.merchant_cert_sn.nil? && !@config.merchant_cert_sn.empty?
          body = JSON.parse(resp_map[AlipayConstants::BODY_FIELD])
          alipay_cert_sn = body[AlipayConstants::ALIPAY_CERT_SN_FIELD]
          return alipay_cert_sn
        end
      end

      def get_alipay_root_cert_sn
        return @config.alipay_root_cert_sn
      end

      def is_cert_mode
        return @config.merchant_cert_sn
      end

      def extract_alipay_public_key(alipay_cert_sn)
        # Ruby 版本只存储一个版本支付宝公钥
        return @config.alipay_public_key
      end

      def verify(resp_map, alipay_public_key)
        resp = JSON.parse(resp_map[AlipayConstants::BODY_FIELD])
        sign = resp[AlipayConstants::SIGN_FIELD]
        sign_content_extractor = Alipay::EasySDK::Kernel::Util::SignContentExtractor.new
        content = sign_content_extractor.get_sign_source_data(resp_map[AlipayConstants::BODY_FIELD], resp_map[AlipayConstants::METHOD_FIELD])
        signer = Alipay::EasySDK::Kernel::Util::Signer.new
        return signer.verify(content, sign, alipay_public_key)
      end

      def sign(system_params, biz_params, text_params, private_key)
        sorted_map = get_sorted_map(system_params, biz_params, text_params)
        data = get_sign_content(sorted_map)
        if ENV['DEBUG']
          puts "[DEBUG] sign content: #{data}"
        end
        puts "[DEBUG] 签名内容: #{data[0, 100]}..." if ENV['DEBUG']
        signer = Alipay::EasySDK::Kernel::Util::Signer.new
        signature = signer.sign(data, private_key)
        puts "[DEBUG] 生成签名长度: #{signature.length}" if ENV['DEBUG']
        return signature
      end

      def generate_order_string(system_params, biz_params, text_params, sign)
        # 采集并排序所有参数
        sorted_map = get_sorted_map(system_params, biz_params, text_params)
        sorted_map[AlipayConstants::SIGN_FIELD] = sign
        URI.encode_www_form(sorted_map)
      end

      def to_multipart_request_body(text_params, file_params, boundary)
        @text_params = text_params
        @biz_params = nil
        if text_params != nil && !@optional_text_params.empty?
          @text_params = text_params.merge(@optional_text_params)
        elsif text_params == nil
          @text_params = @optional_text_params.dup
        end

        parts = []
        (@text_params || {}).each do |key, value|
          parts << build_multipart_text_part(boundary, key, value)
        end

        (file_params || {}).each do |key, path|
          raise "文件#{path}不存在" unless File.exist?(path.to_s)
          file_content = File.binread(path)
          filename = File.basename(path)
          parts << build_multipart_file_part(boundary, key, filename, file_content)
        end

        return nil if parts.empty?

        parts << "--#{boundary}--\r\n"
        parts.join
      end

      def aes_encrypt(content, encrypt_key)
        aes = Alipay::EasySDK::Kernel::Util::AES.new
        aes.aes_encrypt(content, encrypt_key)
      end

      def aes_decrypt(content, encrypt_key)
        aes = Alipay::EasySDK::Kernel::Util::AES.new
        aes.aes_decrypt(content, encrypt_key)
      end

      def sort_map(random_map)
        return random_map
      end

      def to_resp_model(resp_map)
        body = resp_map[AlipayConstants::BODY_FIELD]
        method_name = resp_map[AlipayConstants::METHOD_FIELD]
        response_node_name = method_name.gsub(".", "_") + "_response"

        model = JSON.parse(body)
        if body.include?(AlipayConstants::ERROR_RESPONSE)
          result = model[AlipayConstants::ERROR_RESPONSE]
          result['body'] = body
        else
          result = model[response_node_name]
          result['body'] = body
        end
        return result
      end

      def verify_params(parameters, public_key)
        signer = Alipay::EasySDK::Kernel::Util::Signer.new
        return signer.verify_params(parameters, public_key)
      end

      def concat_str(a, b)
        return a + b
      end

      private

      def build_query_string(sorted_map)
        request_url = nil
        sorted_map.each do |sys_param_key, sys_param_value|
          if request_url.nil?
            request_url = "#{sys_param_key}=" + url_encode(characet(sys_param_value.to_s, AlipayConstants::DEFAULT_CHARSET)) + "&"
          else
            request_url += "#{sys_param_key}=" + url_encode(characet(sys_param_value.to_s, AlipayConstants::DEFAULT_CHARSET)) + "&"
          end
        end
        request_url = request_url[0...-1] unless request_url.nil?
        return request_url
      end

      def get_sorted_map(system_params, biz_params, text_params)
        @text_params = text_params
        @biz_params = biz_params
        if text_params != nil && !@optional_text_params.empty?
          @text_params = text_params.merge(@optional_text_params)
        elsif text_params == nil
          @text_params = @optional_text_params
        end
        if biz_params != nil && !@optional_biz_params.empty?
          @biz_params = biz_params.merge(@optional_biz_params)
        elsif biz_params == nil
          @biz_params = @optional_biz_params
        end

        json_util = Alipay::EasySDK::Kernel::Util::JsonUtil.new
        biz_content = json_util.to_json_string(@biz_params) unless @biz_params.nil?

        sorted_map = (system_params || {}).dup
        if !biz_content.nil?
          unless biz_content.respond_to?(:empty?) && biz_content.empty?
            serialized = JSON.generate(biz_content, ascii_only: false).gsub('/', '\\/')
            sorted_map[AlipayConstants::BIZ_CONTENT_FIELD] = serialized
          end
        end
        if !@text_params.nil? && !@text_params.empty?
          if !sorted_map.empty?
            sorted_map = sorted_map.merge(@text_params)
          else
            sorted_map = @text_params
          end
        end
        notify_value = get_config(AlipayConstants::NOTIFY_URL_CONFIG_KEY)
        if !notify_value.nil? && notify_value.to_s.strip != ''
          sorted_map[AlipayConstants::NOTIFY_URL_FIELD] = notify_value
        end
        return sorted_map
      end

      def get_sign_content(params)
        # 模拟PHP的ksort
        normalized = params.each_with_object({}) do |(key, value), acc|
          acc[key.to_s] = value
        end
        sorted_params = normalized.sort.to_h

        string_to_be_signed = ""
        i = 0
        sorted_params.each do |k, v|
          if !check_empty(v) && v.to_s[0] != "@"
            # 转换成目标字符集
            v = characet(v.to_s, AlipayConstants::DEFAULT_CHARSET)
            if i == 0
              string_to_be_signed += "#{k}=#{v}"
            else
              string_to_be_signed += "&#{k}=#{v}"
            end
            i += 1
          end
        end
        return string_to_be_signed
      end

      def get_gateway_server_url
        protocol = get_config(AlipayConstants::PROTOCOL_CONFIG_KEY)
        host = get_config(AlipayConstants::HOST_CONFIG_KEY)
        return protocol + '://' + host.gsub('/gateway.do', '') + '/gateway.do'
      end

      def check_empty(value)
        if value.nil?
          return true
        end
        if value == ""
          return true
        end
        if value.to_s.strip == ""
          return true
        end
        return false
      end

      def characet(data, target_charset)
        if !data.nil? && !data.empty?
          file_type = AlipayConstants::DEFAULT_CHARSET
          if file_type.downcase != target_charset.downcase
            begin
              data = data.encode(target_charset, invalid: :replace, undef: :replace)
            rescue
              data = data.force_encoding(target_charset)
            end
          end
        end
        return data
      end

      def url_encode(str)
        # 模拟PHP的urlencode
        str.gsub(/[^a-zA-Z0-9\-_.~]/n) do |s|
          '%' + s.unpack('H2' * s.bytesize).join('%').upcase
        end
      end

      def build_form(url, params)
        puts "[DEBUG] build_form - 原始params keys: #{params.keys.join(', ')}" if ENV['DEBUG']
        puts "[DEBUG] build_form - sign长度: #{params[AlipayConstants::SIGN_FIELD].length}" if ENV['DEBUG'] && params[AlipayConstants::SIGN_FIELD]

        page_util = Alipay::EasySDK::Kernel::Util::PageUtil.new
        page_util.build_form(url, params)
      end

      def build_signed_params(system_params, biz_params, text_params, sign)
        sorted_map = get_sorted_map(system_params, biz_params, text_params)
        sorted_map[AlipayConstants::SIGN_FIELD] = sign
        sorted_map
      end

      def build_gateway_url(signed_params)
        base_url = get_gateway_server_url
        query = build_query_string(signed_params)
        return base_url if query.nil? || query.empty?
        base_url + '?' + query
      end

      def build_multipart_text_part(boundary, key, value)
        "--#{boundary}\r\n" \
          "Content-Disposition: form-data; name=\"#{key}\"\r\n" \
          "\r\n" \
          "#{value}\r\n"
      end

      def build_multipart_file_part(boundary, key, filename, content)
        "--#{boundary}\r\n" \
          "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{filename}\"\r\n" \
          "Content-Type: application/octet-stream\r\n" \
          "\r\n" \
          "#{content}\r\n"
      end
      end
    end
  end
end
