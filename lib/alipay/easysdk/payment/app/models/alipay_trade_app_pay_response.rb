module Alipay
  module EasySDK
    module Payment
      module App
        module Models
          class AlipayTradeAppPayResponse
            attr_accessor :body

            def self.from_map(response)
              new.tap do |instance|
                instance.body = response[Alipay::EasySDK::Kernel::AlipayConstants::BODY_FIELD]
              end
            end
          end
        end
      end
    end
  end
end
