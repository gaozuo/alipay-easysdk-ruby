module Alipay
  module EasySDK
    module Kernel
      class Config
        attr_accessor :protocol,
                      :gatewayHost,
                      :appId,
                      :signType,
                      :alipayPublicKey,
                      :merchantPrivateKey,
                      :merchantCertPath,
                      :alipayCertPath,
                      :alipayRootCertPath,
                      :merchantCertSN,
                      :alipayCertSN,
                      :alipayRootCertSN,
                      :notifyUrl,
                      :encryptKey,
                      :httpProxy,
                      :ignoreSSL

        def initialize(options = nil)
          assign_attributes(options) if options
        end

        # 下划线风格的访问器保持向后兼容
        alias_method :gateway_host, :gatewayHost
        alias_method :gateway_host=, :gatewayHost=

        alias_method :app_id, :appId
        alias_method :app_id=, :appId=

        alias_method :sign_type, :signType
        alias_method :sign_type=, :signType=

        alias_method :alipay_public_key, :alipayPublicKey
        alias_method :alipay_public_key=, :alipayPublicKey=

        alias_method :merchant_private_key, :merchantPrivateKey
        alias_method :merchant_private_key=, :merchantPrivateKey=

        alias_method :merchant_cert_path, :merchantCertPath
        alias_method :merchant_cert_path=, :merchantCertPath=

        alias_method :alipay_cert_path, :alipayCertPath
        alias_method :alipay_cert_path=, :alipayCertPath=

        alias_method :alipay_root_cert_path, :alipayRootCertPath
        alias_method :alipay_root_cert_path=, :alipayRootCertPath=

        alias_method :merchant_cert_sn, :merchantCertSN
        alias_method :merchant_cert_sn=, :merchantCertSN=

        alias_method :alipay_cert_sn, :alipayCertSN
        alias_method :alipay_cert_sn=, :alipayCertSN=

        alias_method :alipay_root_cert_sn, :alipayRootCertSN
        alias_method :alipay_root_cert_sn=, :alipayRootCertSN=

        alias_method :notify_url, :notifyUrl
        alias_method :notify_url=, :notifyUrl=

        alias_method :encrypt_key, :encryptKey
        alias_method :encrypt_key=, :encryptKey=

        alias_method :http_proxy, :httpProxy
        alias_method :http_proxy=, :httpProxy=

        alias_method :ignore_ssl, :ignoreSSL
        alias_method :ignore_ssl=, :ignoreSSL=

        private

        def assign_attributes(options)
          options.each do |key, value|
            setter = attribute_writer_for(key)
            public_send(setter, value) if setter && respond_to?(setter, true)
          end
        end

        def attribute_writer_for(key)
          string_key = key.to_s
          writer = "#{string_key}="
          return writer if respond_to?(writer, true)

          camel_case = underscore_to_camel(string_key)
          writer = "#{camel_case}="
          return writer if respond_to?(writer, true)

          snake_case = camel_to_snake(string_key)
          writer = "#{snake_case}="
          return writer if respond_to?(writer, true)

          nil
        end

        def underscore_to_camel(str)
          str.split('_').inject do |memo, part|
            memo + part.capitalize
          end
        end

        def camel_to_snake(str)
          str.gsub(/([A-Z]+)/) { "_#{$1.downcase}" }.sub(/^_/, '')
        end
      end
    end
  end
end
