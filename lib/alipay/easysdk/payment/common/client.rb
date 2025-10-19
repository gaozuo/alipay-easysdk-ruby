require 'net/http'
require 'uri'
require 'cgi'

require_relative '../../kernel/easy_sdk_kernel'
require_relative 'models/alipay_trade_create_response'
require_relative 'models/alipay_trade_query_response'
require_relative 'models/alipay_trade_refund_response'
require_relative 'models/alipay_trade_close_response'
require_relative 'models/alipay_trade_cancel_response'
require_relative 'models/alipay_trade_fastpay_refund_query_response'
require_relative 'models/alipay_data_dataservice_bill_downloadurl_query_response'

module Alipay
  module EasySDK
    module Payment
      module Common
        class Client
          def initialize(kernel)
            @kernel = kernel
          end

          def create(subject, out_trade_no, total_amount, buyer_id)
            biz_params = {
              'subject' => subject,
              'out_trade_no' => out_trade_no,
              'total_amount' => total_amount,
              'buyer_id' => buyer_id
            }
            execute('alipay.trade.create', biz_params, {}, Models::AlipayTradeCreateResponse)
          end

          def query(out_trade_no)
            biz_params = { 'out_trade_no' => out_trade_no }
            execute('alipay.trade.query', biz_params, {}, Models::AlipayTradeQueryResponse)
          end

          def refund(out_trade_no, refund_amount)
            biz_params = {
              'out_trade_no' => out_trade_no,
              'refund_amount' => refund_amount
            }
            execute('alipay.trade.refund', biz_params, {}, Models::AlipayTradeRefundResponse)
          end

          def close(out_trade_no)
            biz_params = { 'out_trade_no' => out_trade_no }
            execute('alipay.trade.close', biz_params, {}, Models::AlipayTradeCloseResponse)
          end

          def cancel(out_trade_no)
            biz_params = { 'out_trade_no' => out_trade_no }
            execute('alipay.trade.cancel', biz_params, {}, Models::AlipayTradeCancelResponse)
          end

          def query_refund(out_trade_no, out_request_no)
            biz_params = {
              'out_trade_no' => out_trade_no,
              'out_request_no' => out_request_no
            }
            execute('alipay.trade.fastpay.refund.query', biz_params, {}, Models::AlipayTradeFastpayRefundQueryResponse)
          end

          def download_bill(bill_type, bill_date)
            biz_params = {
              'bill_type' => bill_type,
              'bill_date' => bill_date
            }
            execute('alipay.data.dataservice.bill.downloadurl.query', biz_params, {}, Models::AlipayDataDataserviceBillDownloadurlQueryResponse)
          end

          def verify_notify(parameters)
            if @kernel.is_cert_mode
              @kernel.verify_params(parameters, @kernel.extract_alipay_public_key(@kernel.get_alipay_cert_sn('')))
            else
              @kernel.verify_params(parameters, @kernel.get_config('alipayPublicKey'))
            end
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

          private

          def execute(api_method, biz_params, text_params, response_class)
            system_params = base_system_params(api_method)

            sign = @kernel.sign(system_params, biz_params, text_params, @kernel.get_config('merchantPrivateKey'))

            text_query = (@kernel.text_params || {}).dup
            query_params = { 'sign' => sign }.merge(system_params)
            query_params.merge!(text_query) unless text_query.empty?

            uri = build_gateway_uri(query_params)
            request = Net::HTTP::Post.new(uri.request_uri)
            request['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'
            request.body = @kernel.to_url_encoded_request_body(biz_params)

            response = perform_http_request(uri, request)

            resp_map = @kernel.read_as_json(response, api_method)

            unless verify_response(resp_map)
              raise '验签失败，请检查支付宝公钥设置是否正确。'
            end

            map = @kernel.to_resp_model(resp_map)
            response_class.from_map(map)
          ensure
            clear_optional_params
          end

          def base_system_params(method)
            {
              'method' => method,
              'app_id' => @kernel.get_config('appId'),
              'timestamp' => @kernel.get_timestamp,
              'format' => 'json',
              'version' => '1.0',
              'alipay_sdk' => @kernel.get_sdk_version,
              'charset' => 'UTF-8',
              'sign_type' => @kernel.get_config('signType'),
              'app_cert_sn' => @kernel.get_merchant_cert_sn,
              'alipay_root_cert_sn' => @kernel.get_alipay_root_cert_sn
            }.compact
          end

          def build_gateway_uri(query_params)
            host = @kernel.get_config('gatewayHost').to_s.sub(%r{/gateway\.do$}, '')
            scheme = @kernel.get_config('protocol') || 'https'
            uri = URI("#{scheme}://#{host}/gateway.do")
            uri.query = URI.encode_www_form(query_params.sort.to_h)
            uri
          end

          def perform_http_request(uri, request)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = uri.scheme == 'https'
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl?
            http.open_timeout = 15
            http.read_timeout = 15
            http.request(request)
          end

          def verify_response(resp_map)
            if @kernel.is_cert_mode
              @kernel.verify(resp_map, @kernel.extract_alipay_public_key(@kernel.get_alipay_cert_sn(resp_map)))
            else
              @kernel.verify(resp_map, @kernel.get_config('alipayPublicKey'))
            end
          end

          def clear_optional_params
            @kernel.optional_text_params.clear if @kernel.optional_text_params
            @kernel.optional_biz_params.clear if @kernel.optional_biz_params
          end
        end
      end
    end
  end
end
