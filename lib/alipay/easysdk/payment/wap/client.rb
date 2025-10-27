require_relative '../../kernel/easy_sdk_kernel'
require_relative 'models/alipay_trade_wap_pay_response'

module Alipay
  module EasySDK
    module Payment
      module Wap
        class Client
          def initialize(kernel)
            @kernel = kernel
          end

          # 完全复制PHP版本的pay方法
          def pay(subject, out_trade_no, total_amount, quit_url, return_url)
            system_params = {
              "method" => "alipay.trade.wap.pay",
              "app_id" => @kernel.get_config("appId"),
              "timestamp" => @kernel.get_timestamp(),
              "format" => "json",
              "version" => "1.0",
              "alipay_sdk" => @kernel.get_sdk_version(),
              "charset" => "UTF-8",
              "sign_type" => @kernel.get_config("signType"),
              "app_cert_sn" => @kernel.get_merchant_cert_sn(),
              "alipay_root_cert_sn" => @kernel.get_alipay_root_cert_sn()
            }
            biz_params = {
              "subject" => subject,
              "out_trade_no" => out_trade_no,
              "total_amount" => total_amount,
              "quit_url" => quit_url,
              "product_code" => "QUICK_WAP_WAY"
            }
            text_params = {
              "return_url" => return_url
            }

            # 完全按照PHP版本的逻辑：先设置所有参数，再生成签名，最后生成页面
            sign = @kernel.sign(system_params, biz_params, text_params, @kernel.get_config("merchantPrivateKey"))

            response = {
              "body" => @kernel.generate_page("POST", system_params, biz_params, text_params, sign),
              "payment_url" => @kernel.generate_payment_url(system_params, biz_params, text_params, sign)
            }
            return Alipay::EasySDK::Payment::Wap::Models::AlipayTradeWapPayResponse.from_map(response)
          end

          # ISV代商户代用，指定appAuthToken
          def agent(app_auth_token)
            @kernel.inject_text_param("app_auth_token", app_auth_token)
            return self
          end

          # 用户授权调用，指定authToken
          def auth(auth_token)
            @kernel.inject_text_param("auth_token", auth_token)
            return self
          end

          # 设置异步通知回调地址
          def async_notify(url)
            @kernel.inject_text_param("notify_url", url)
            return self
          end

          # 将本次调用强制路由到后端系统的测试地址上
          def route(test_url)
            @kernel.inject_text_param("ws_service_url", test_url)
            return self
          end

          # 设置API入参中没有的其他可选业务请求参数
          def optional(key, value)
            @kernel.inject_biz_param(key, value)
            return self
          end

          # 批量设置可选参数
          def batch_optional(optional_args)
            optional_args.each do |key, value|
              @kernel.inject_biz_param(key, value)
            end
            return self
          end
        end
      end
    end
  end
end
