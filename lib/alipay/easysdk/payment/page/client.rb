require_relative '../../kernel/easy_sdk_kernel'
require_relative 'models/alipay_trade_page_pay_response'

module Alipay
  module EasySDK
    module Payment
      module Page
        class Client
          def initialize(kernel)
            @kernel = kernel
          end

          def pay(subject, out_trade_no, total_amount, return_url)
            system_params = {
              'method' => 'alipay.trade.page.pay',
              'app_id' => @kernel.get_config('appId'),
              'timestamp' => @kernel.get_timestamp,
              'format' => 'json',
              'version' => '1.0',
              'alipay_sdk' => @kernel.get_sdk_version,
              'charset' => 'UTF-8',
              'sign_type' => @kernel.get_config('signType'),
              'app_cert_sn' => @kernel.get_merchant_cert_sn,
              'alipay_root_cert_sn' => @kernel.get_alipay_root_cert_sn
            }
            biz_params = {
              'subject' => subject,
              'out_trade_no' => out_trade_no,
              'total_amount' => total_amount,
              'product_code' => 'FAST_INSTANT_TRADE_PAY'
            }
            text_params = {
              'return_url' => return_url
            }

            sign = @kernel.sign(system_params, biz_params, text_params, @kernel.get_config('merchantPrivateKey'))

            response = {
              'body' => @kernel.generate_page('POST', system_params, biz_params, text_params, sign)
            }

            Models::AlipayTradePagePayResponse.from_map(response)
          end

          def agent(app_auth_token)
            @kernel.inject_text_param('app_auth_token', app_auth_token)
            self
          end

          def auth(auth_token)
            @kernel.inject_text_param('auth_token', auth_token)
            self
          end

          def async_notify(url)
            @kernel.inject_text_param('notify_url', url)
            self
          end

          def route(test_url)
            @kernel.inject_text_param('ws_service_url', test_url)
            self
          end

          def optional(key, value)
            @kernel.inject_biz_param(key, value)
            self
          end

          def batch_optional(optional_args)
            optional_args.each do |key, value|
              @kernel.inject_biz_param(key, value)
            end
            self
          end
        end
      end
    end
  end
end
