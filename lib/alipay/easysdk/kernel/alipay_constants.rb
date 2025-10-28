require_relative '../version'

module Alipay
  module EasySDK
    module Kernel
      module AlipayConstants
        # Config键名（对齐PHP版）
        PROTOCOL_CONFIG_KEY = "protocol"
        HOST_CONFIG_KEY = "gatewayHost"
        ALIPAY_CERT_PATH_CONFIG_KEY = "alipayCertPath"
        MERCHANT_CERT_PATH_CONFIG_KEY = "merchantCertPath"
        ALIPAY_ROOT_CERT_PATH_CONFIG_KEY = "alipayRootCertPath"
        SIGN_TYPE_CONFIG_KEY = "signType"
        NOTIFY_URL_CONFIG_KEY = "notifyUrl"

        # 与网关交互使用的字段
        BIZ_CONTENT_FIELD = "biz_content"
        ALIPAY_CERT_SN_FIELD = "alipay_cert_sn"
        SIGN_FIELD = "sign"
        BODY_FIELD = "http_body"
        NOTIFY_URL_FIELD = "notify_url"
        METHOD_FIELD = "method"
        RESPONSE_SUFFIX = "_response"
        ERROR_RESPONSE = "error_response"

        DEFAULT_CHARSET = "UTF-8"
        DEFAULT_FORMAT = "json"
        DEFAULT_VERSION = "1.0"
        DEFAULT_SIGN_TYPE = "RSA2"

        SIGN_TYPE_RSA = "RSA"
        SIGN_TYPE_RSA2 = "RSA2"
        RSA2 = "RSA2"
        SHA_256_WITH_RSA = "SHA256WithRSA"
        RSA = "RSA"

        GET = "GET"
        POST = "POST"

        SDK_VERSION = "alipay-easysdk-ruby-#{Alipay::EasySDK::VERSION}"
      end
    end
  end
end
