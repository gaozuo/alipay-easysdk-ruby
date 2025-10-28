module Alipay
  module EasySDK
    module Payment
      module Wap
        module Models
          class AlipayTradeWapPayResponse
            attr_accessor :body, :code, :sub_code, :payment_url

            def self.from_map(response)
              new.tap do |instance|
                instance.body = response[Alipay::EasySDK::Kernel::AlipayConstants::BODY_FIELD]
                instance.payment_url = response['payment_url']
              end
            end
          end
        end
      end
    end
  end
end
