module Alipay
  module EasySDK
    module Payment
      module Common
        module Models
          class PresetPayToolInfo
            attr_accessor :amount, :assert_type_code

            def self.from_map(map = {})
              map ||= {}
              new.tap do |instance|
                amount_value = map['amount']
                instance.amount = amount_value unless amount_value.nil? || (amount_value.respond_to?(:empty?) && amount_value.empty?)
                instance.assert_type_code = map['assert_type_code']
              end
            end

            def to_map
              result = {}
              result['amount'] = amount unless amount.nil?
              result['assert_type_code'] = assert_type_code unless assert_type_code.nil?
              result
            end
          end
        end
      end
    end
  end
end
