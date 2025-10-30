module Alipay
  module EasySDK
    module Payment
      module Common
        module Models
          class TradeFundBill
            attr_accessor :fund_channel, :bank_code, :amount, :real_amount, :fund_type

            def self.from_map(map = {})
              map ||= {}
              new.tap do |instance|
                instance.fund_channel = map['fund_channel']
                instance.bank_code = map['bank_code']
                instance.amount = map['amount']
                instance.real_amount = map['real_amount']
                instance.fund_type = map['fund_type']
              end
            end

            def to_map
              {
                'fund_channel' => fund_channel,
                'bank_code' => bank_code,
                'amount' => amount,
                'real_amount' => real_amount,
                'fund_type' => fund_type
              }.delete_if { |_key, value| value.nil? }
            end
          end
        end
      end
    end
  end
end
