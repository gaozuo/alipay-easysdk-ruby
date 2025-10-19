require_relative 'alipay_constants'

module Alipay
  module EasySDK
    module Kernel
      class Config
        attr_accessor :protocol, :gateway_host, :app_id, :merchant_private_key,
                      :alipay_public_key, :sign_type, :charset, :format, :version,
                      :merchant_cert_sn, :alipay_root_cert_sn, :notify_url

        def initialize(options = {})
          @protocol = options[:protocol] || 'https'
          @gateway_host = options[:gateway_host] || 'openapi.alipay.com/gateway.do'
          @app_id = options[:app_id]
          @merchant_private_key = options[:merchant_private_key]
          @alipay_public_key = options[:alipay_public_key]
          @sign_type = options[:sign_type] || AlipayConstants::DEFAULT_SIGN_TYPE
          @charset = options[:charset] || AlipayConstants::DEFAULT_CHARSET
          @format = options[:format] || AlipayConstants::DEFAULT_FORMAT
          @version = options[:version] || AlipayConstants::DEFAULT_VERSION
          @merchant_cert_sn = options[:merchant_cert_sn]
          @alipay_root_cert_sn = options[:alipay_root_cert_sn]
          @notify_url = options[:notify_url]
        end

        def gateway_url
          "#{@protocol}://#{@gateway_host}"
        end

        def validate
          raise "app_id is required" if @app_id.nil? || @app_id.empty?
          raise "merchant_private_key is required" if @merchant_private_key.nil? || @merchant_private_key.empty?
          raise "alipay_public_key is required" if @alipay_public_key.nil? || @alipay_public_key.empty?
        end
      end
    end
  end
end
