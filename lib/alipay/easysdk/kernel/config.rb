require_relative 'alipay_constants'

module Alipay
  module EasySDK
    module Kernel
      class Config
        attr_accessor :protocol,
                      :gateway_host,
                      :app_id,
                      :sign_type,
                      :alipay_public_key,
                      :merchant_private_key,
                      :merchant_cert_path,
                      :alipay_cert_path,
                      :alipay_root_cert_path,
                      :merchant_cert_sn,
                      :alipay_cert_sn,
                      :alipay_root_cert_sn,
                      :notify_url,
                      :encrypt_key,
                      :http_proxy,
                      :ignore_ssl,
                      :charset,
                      :format,
                      :version

        def initialize(options = {})
          opts = options || {}

          @protocol = fetch_option(opts, :protocol, 'protocol') || 'https'
          @gateway_host = fetch_option(opts, :gateway_host, 'gateway_host', :gatewayHost, 'gatewayHost') || 'openapi.alipay.com/gateway.do'
          @app_id = fetch_option(opts, :app_id, 'app_id', :appId, 'appId')
          @sign_type = fetch_option(opts, :sign_type, 'sign_type', :signType, 'signType') || AlipayConstants::DEFAULT_SIGN_TYPE
          @alipay_public_key = fetch_option(opts, :alipay_public_key, 'alipay_public_key', :alipayPublicKey, 'alipayPublicKey')
          @merchant_private_key = fetch_option(opts, :merchant_private_key, 'merchant_private_key', :merchantPrivateKey, 'merchantPrivateKey')
          @merchant_cert_path = fetch_option(opts, :merchant_cert_path, 'merchant_cert_path', :merchantCertPath, 'merchantCertPath')
          @alipay_cert_path = fetch_option(opts, :alipay_cert_path, 'alipay_cert_path', :alipayCertPath, 'alipayCertPath')
          @alipay_root_cert_path = fetch_option(opts, :alipay_root_cert_path, 'alipay_root_cert_path', :alipayRootCertPath, 'alipayRootCertPath')
          @merchant_cert_sn = fetch_option(opts, :merchant_cert_sn, 'merchant_cert_sn', :merchantCertSN, 'merchantCertSN')
          @alipay_cert_sn = fetch_option(opts, :alipay_cert_sn, 'alipay_cert_sn', :alipayCertSN, 'alipayCertSN')
          @alipay_root_cert_sn = fetch_option(opts, :alipay_root_cert_sn, 'alipay_root_cert_sn', :alipayRootCertSN, 'alipayRootCertSN')
          @notify_url = fetch_option(opts, :notify_url, 'notify_url', :notifyUrl, 'notifyUrl')
          @encrypt_key = fetch_option(opts, :encrypt_key, 'encrypt_key', :encryptKey, 'encryptKey')
          @http_proxy = fetch_option(opts, :http_proxy, 'http_proxy', :httpProxy, 'httpProxy')
          @ignore_ssl = fetch_option(opts, :ignore_ssl, 'ignore_ssl', :ignoreSSL, 'ignoreSSL')
          @charset = fetch_option(opts, :charset, 'charset') || AlipayConstants::DEFAULT_CHARSET
          @format = fetch_option(opts, :format, 'format') || AlipayConstants::DEFAULT_FORMAT
          @version = fetch_option(opts, :version, 'version') || AlipayConstants::DEFAULT_VERSION
        end

        def gateway_url
          "#{@protocol}://#{@gateway_host}"
        end

        def validate
          raise "app_id is required" if @app_id.nil? || @app_id.empty?
          raise "merchant_private_key is required" if @merchant_private_key.nil? || @merchant_private_key.empty?
          raise "alipay_public_key is required" if @alipay_public_key.nil? || @alipay_public_key.empty?
        end

        private

        def fetch_option(options, *keys)
          keys.each do |key|
            if key.is_a?(String)
              symbol_key = key.tr('-', '_').to_sym
              return options[key] if options.key?(key)
              return options[symbol_key] if options.key?(symbol_key)
            elsif key.is_a?(Symbol)
              string_key = key.to_s
              camel_case_key = string_key.gsub(/_([a-z])/) { Regexp.last_match(1).upcase }
              return options[key] if options.key?(key)
              return options[string_key] if options.key?(string_key)
              return options[camel_case_key] if options.key?(camel_case_key)
            end
          end
          nil
        end
      end
    end
  end
end
