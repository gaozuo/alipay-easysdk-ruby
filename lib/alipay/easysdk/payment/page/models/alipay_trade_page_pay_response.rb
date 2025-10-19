module Alipay
  module EasySDK
    module Payment
      module Page
        module Models
          class AlipayTradePagePayResponse
            attr_accessor :body

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
