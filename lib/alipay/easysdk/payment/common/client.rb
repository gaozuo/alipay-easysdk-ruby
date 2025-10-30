require 'net/http'
require 'uri'
require 'cgi'
require 'openssl'

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
          class TeaError < StandardError
            attr_reader :data, :code

            def initialize(data = {}, message = '', code = nil, cause = nil)
              super(message)
              @data = data
              @code = code
              set_backtrace(cause.backtrace) if cause
            end
          end

          class TeaUnableRetryError < StandardError
            attr_reader :last_request, :last_exception

            def initialize(last_request, last_exception)
              super(last_exception&.message)
              @last_request = last_request
              @last_exception = last_exception
            end
          end

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
            runtime = {
              'ignoreSSL' => @kernel.get_config('ignoreSSL'),
              'httpProxy' => @kernel.get_config('httpProxy'),
              'connectTimeout' => 15000,
              'readTimeout' => 15000,
              'retry' => {
                'maxAttempts' => 0
              }
            }
            last_request = nil
            last_exception = nil
            started_at = Time.now.to_i
            retry_times = 0

            while allow_retry?(runtime['retry'], retry_times, started_at)
              if retry_times.positive?
                backoff_time = get_backoff_time(runtime['backoff'], retry_times)
                sleep(backoff_time) if backoff_time && backoff_time > 0
              end
              retry_times += 1

              begin
                system_params = {
                  'method' => 'alipay.trade.refund',
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
                  'out_trade_no' => out_trade_no,
                  'refund_amount' => refund_amount
                }
                text_params = {}
                sign = @kernel.sign(system_params, biz_params, text_params, @kernel.get_config('merchantPrivateKey'))
                query_params = @kernel.sort_map(merge_hashes(
                  { Alipay::EasySDK::Kernel::AlipayConstants::SIGN_FIELD => sign },
                  system_params,
                  text_params
                ))
                uri = build_gateway_uri(query_params)
                request = Net::HTTP::Post.new(uri.request_uri)
                request['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'
                host_header = @kernel.get_config('gatewayHost')
                request['Host'] = host_header if host_header
                request.body = @kernel.to_url_encoded_request_body(biz_params)
                last_request = {
                  'method' => request.method,
                  'uri' => uri.to_s,
                  'headers' => request.each_header.to_h,
                  'body' => request.body
                }
                response = perform_http_request(uri, request, runtime)
                resp_map = @kernel.read_as_json(response, 'alipay.trade.refund')
                if verify_response(resp_map)
                  return Models::AlipayTradeRefundResponse.from_map(@kernel.to_resp_model(resp_map))
                end
                raise TeaError.new({}, '验签失败，请检查支付宝公钥设置是否正确。')
              rescue TeaError => error
                last_exception = error
                raise error unless retryable?(runtime['retry'], error)
              rescue StandardError => error
                tea_error = TeaError.new({}, error.message, nil, error)
                last_exception = tea_error
                raise tea_error unless retryable?(runtime['retry'], tea_error)
              end
            end

            raise TeaUnableRetryError.new(last_request, last_exception)
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
            runtime = {
              'ignoreSSL' => @kernel.get_config('ignoreSSL'),
              'httpProxy' => @kernel.get_config('httpProxy'),
              'connectTimeout' => 15000,
              'readTimeout' => 15000,
              'retry' => {
                'maxAttempts' => 0
              }
            }
            last_request = nil
            last_exception = nil
            started_at = Time.now.to_i
            retry_times = 0

            while allow_retry?(runtime['retry'], retry_times, started_at)
              if retry_times.positive?
                backoff_time = get_backoff_time(runtime['backoff'], retry_times)
                sleep(backoff_time) if backoff_time && backoff_time > 0
              end
              retry_times += 1

              begin
                system_params = {
                  'method' => 'alipay.trade.fastpay.refund.query',
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
                  'out_trade_no' => out_trade_no,
                  'out_request_no' => out_request_no
                }
                text_params = {}
                sign = @kernel.sign(system_params, biz_params, text_params, @kernel.get_config('merchantPrivateKey'))
                query_params = @kernel.sort_map(merge_hashes(
                  { Alipay::EasySDK::Kernel::AlipayConstants::SIGN_FIELD => sign },
                  system_params,
                  text_params
                ))
                uri = build_gateway_uri(query_params)
                request = Net::HTTP::Post.new(uri.request_uri)
                request['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'
                host_header = @kernel.get_config('gatewayHost')
                request['Host'] = host_header if host_header
                request.body = @kernel.to_url_encoded_request_body(biz_params)
                last_request = {
                  'method' => request.method,
                  'uri' => uri.to_s,
                  'headers' => request.each_header.to_h,
                  'body' => request.body
                }
                response = perform_http_request(uri, request, runtime)
                resp_map = @kernel.read_as_json(response, 'alipay.trade.fastpay.refund.query')
                if verify_response(resp_map)
                  return Models::AlipayTradeFastpayRefundQueryResponse.from_map(@kernel.to_resp_model(resp_map))
                end
                raise TeaError.new({}, '验签失败，请检查支付宝公钥设置是否正确。')
              rescue TeaError => error
                last_exception = error
                raise error unless retryable?(runtime['retry'], error)
              rescue StandardError => error
                tea_error = TeaError.new({}, error.message, nil, error)
                last_exception = tea_error
                raise tea_error unless retryable?(runtime['retry'], tea_error)
              end
            end

            raise TeaUnableRetryError.new(last_request, last_exception)
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
              @kernel.verify_params(parameters, @kernel.extract_alipay_public_key(''))
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
            query_params = { Alipay::EasySDK::Kernel::AlipayConstants::SIGN_FIELD => sign }.merge(system_params)
            query_params.merge!(text_query) unless text_query.empty?

            uri = build_gateway_uri(query_params)
            request = Net::HTTP::Post.new(uri.request_uri)
            request['Content-Type'] = 'application/x-www-form-urlencoded;charset=utf-8'
            request.body = @kernel.to_url_encoded_request_body(biz_params)

            response = perform_http_request(uri, request)

            resp_map = @kernel.read_as_json(response, api_method)

            unless verify_response(resp_map)
              raise TeaError.new({}, '验签失败，请检查支付宝公钥设置是否正确。')
            end

            map = @kernel.to_resp_model(resp_map)
            response_class.from_map(map)
          rescue TeaError => e
            raise e
          rescue StandardError => e
            raise TeaError.new({}, e.message, nil, e)
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
            host = @kernel.get_config(Alipay::EasySDK::Kernel::AlipayConstants::HOST_CONFIG_KEY).to_s.sub(%r{/gateway\.do$}, '')
            scheme = @kernel.get_config(Alipay::EasySDK::Kernel::AlipayConstants::PROTOCOL_CONFIG_KEY) || 'https'
            uri = URI("#{scheme}://#{host}/gateway.do")
            uri.query = URI.encode_www_form(query_params.sort.to_h)
            uri
          end

          def perform_http_request(uri, request, runtime = nil)
            http = build_http_client(uri)
            http.use_ssl = uri.scheme == 'https'
            ignore_ssl_flag = if runtime && runtime.key?('ignoreSSL')
                                boolean_true?(runtime['ignoreSSL'])
                              else
                                ignore_ssl?
                              end
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && ignore_ssl_flag
            http.open_timeout = timeout_in_seconds(runtime&.dig('connectTimeout'), 15)
            http.read_timeout = timeout_in_seconds(runtime&.dig('readTimeout'), 15)
            http.request(request)
          end

          def verify_response(resp_map)
            if @kernel.is_cert_mode
              @kernel.verify(resp_map, @kernel.extract_alipay_public_key(@kernel.get_alipay_cert_sn(resp_map)))
            else
              @kernel.verify(resp_map, @kernel.get_config('alipayPublicKey'))
            end
          end

          def build_http_client(uri)
            proxy_settings = http_proxy_settings
            if proxy_settings
              Net::HTTP.new(uri.host, uri.port, *proxy_settings)
            else
              Net::HTTP.new(uri.host, uri.port)
            end
          end

          def http_proxy_settings
            raw_proxy = @kernel.get_config('httpProxy')
            return nil if raw_proxy.nil? || raw_proxy.to_s.strip.empty?

            proxy_uri = raw_proxy =~ %r{^https?://} ? URI(raw_proxy) : URI("http://#{raw_proxy}")
            [proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password]
          rescue URI::InvalidURIError
            nil
          end

          def ignore_ssl?
            value = @kernel.get_config('ignoreSSL')
            return false if value.nil?

            value == true || value.to_s.strip.downcase == 'true'
          end

          def merge_hashes(*hashes)
            hashes.compact.reduce({}) { |memo, item| memo.merge(item) }
          end

          def allow_retry?(retry_config, retry_times, _start_time)
            return false unless retry_times.is_a?(Numeric)

            config = retry_config.is_a?(Hash) ? retry_config : {}
            if retry_times.positive?
              retryable_key_present = config.key?('retryable') || config.key?(:retryable)
              retryable_flag = retryable_key_present && boolean_true?(config['retryable'] || config[:retryable])
              max_attempts_present = config.key?('maxAttempts') || config.key?(:maxAttempts)
              return false if config.empty? || !retryable_key_present || !retryable_flag || !max_attempts_present
            end

            max_attempts = config['maxAttempts'] || config[:maxAttempts]
            retry_limit = max_attempts.nil? ? 0 : max_attempts.to_i
            retry_limit >= retry_times
          end

          def get_backoff_time(backoff_config, retry_times)
            return 0 unless backoff_config.is_a?(Hash)

            policy = backoff_config['policy'] || backoff_config[:policy]
            return 0 if policy.nil? || policy.to_s.strip.empty? || policy.to_s.strip.downcase == 'no'

            period = backoff_config['period'] || backoff_config[:period]
            return 0 if period.nil? || period.to_s.strip.empty?

            value = period.to_i
            return retry_times if value <= 0

            value
          end

          def retryable?(_retry_config, error)
            error.is_a?(TeaError)
          end

          def boolean_true?(value)
            return false if value.nil?

            value == true || value.to_s.strip.downcase == 'true'
          end

          def timeout_in_seconds(milliseconds, default_seconds)
            return default_seconds if milliseconds.nil?

            ms = milliseconds.to_f
            return default_seconds if ms <= 0

            ms / 1000.0
          end
        end
      end
    end
  end
end
