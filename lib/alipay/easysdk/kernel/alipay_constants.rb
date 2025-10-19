require_relative '../version'

module Alipay
  module EasySDK
    module Kernel
      module AlipayConstants
        DEFAULT_CHARSET = "UTF-8"

      # 签名类型
      SIGN_TYPE_RSA = "RSA"
      SIGN_TYPE_RSA2 = "RSA2"

      # 字段常量
      APP_ID_FIELD = "app_id"
      METHOD_FIELD = "method"
      FORMAT_FIELD = "format"
      TIMESTAMP_FIELD = "timestamp"
      VERSION_FIELD = "version"
      SIGN_TYPE_FIELD = "sign_type"
      SIGN_FIELD = "sign"
      BIZ_CONTENT_FIELD = "biz_content"
      CHARSET_FIELD = "charset"
      BODY_FIELD = "body"
      ALIPAY_CERT_SN_FIELD = "alipay_cert_sn"
      NOTIFY_URL_FIELD = "notify_url"
      NOTIFY_URL_CONFIG_KEY = "notifyUrl"
      PROTOCOL_CONFIG_KEY = "protocol"
      HOST_CONFIG_KEY = "gatewayHost"
      RESPONSE_SUFFIX = "_response"
      ERROR_RESPONSE = "error_response"

      # 默认值
      DEFAULT_FORMAT = "json"
      DEFAULT_VERSION = "1.0"
      DEFAULT_SIGN_TYPE = SIGN_TYPE_RSA2

      # 请求方式
      GET = "GET"
      POST = "POST"

      # SDK信息
        SDK_VERSION = "alipay-easysdk-ruby-#{Alipay::EasySDK::VERSION}"
      end
    end
  end
end
