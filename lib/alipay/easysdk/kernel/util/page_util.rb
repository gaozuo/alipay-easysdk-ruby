module Alipay
  module EasySDK
    module Kernel
      module Util
        class PageUtil
          def build_form(action_url, parameters)
            charset = Alipay::EasySDK::Kernel::AlipayConstants::DEFAULT_CHARSET
            form = "<form id='alipaysubmit' name='alipaysubmit' action='#{action_url}?charset=#{charset}' method='POST'>"
            params_enum(parameters).each do |key, val|
              next if check_empty(val)

              escaped = val.to_s.gsub("'", "&apos;")
              form += "<input type='hidden' name='#{key}' value='#{escaped}'/>"
            end
            form += "<input type='submit' value='ok' style='display:none;'></form>"
            form += "<script>document.forms['alipaysubmit'].submit();</script>"
            form
          end

          private

          def params_enum(parameters)
            return [] if parameters.nil?
            parameters.to_a
          end

          def check_empty(value)
            !value || value.to_s.strip == ''
          end
        end
      end
    end
  end
end
