module Alipay
  module EasySDK
    module Payment
      module Wap
        module Models
          class AlipayTradeWapPayResponse
            attr_accessor :body, :code, :sub_code

            def self.from_map(response)
              new.tap do |instance|
                instance.body = response['body']
              end
            end

            def success?
              !body.nil? && !body.to_s.empty?
            end

            def form
              body
            end

            def error_message
              nil
            end

            def to_s
              body || ''
            end
          end
        end
      end
    end
  end
end
