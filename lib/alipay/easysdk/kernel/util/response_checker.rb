module Alipay
  module EasySDK
    module Kernel
      module Util
        class ResponseChecker
          def success?(response)
            return true if response.respond_to?(:code) && response.code.to_s == '10000'

            code_blank = !response.respond_to?(:code) || blank?(response.code)
            sub_code_value = if response.respond_to?(:subCode)
                               response.subCode
                             elsif response.respond_to?(:sub_code)
                               response.sub_code
                             end
            sub_code_blank = blank?(sub_code_value)

            code_blank && sub_code_blank
          end

          def success(response)
            success?(response)
          end

          private

          def blank?(value)
            value.nil? || value.to_s.strip.empty?
          end
        end
      end
    end
  end
end
