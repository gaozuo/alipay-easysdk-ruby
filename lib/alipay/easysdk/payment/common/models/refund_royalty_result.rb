module Alipay
  module EasySDK
    module Payment
      module Common
        module Models
          class RefundRoyaltyResult
            attr_accessor :refund_amount, :royalty_type, :result_code,
                          :trans_out, :trans_out_email, :trans_in, :trans_in_email

            def self.from_map(map = {})
              map ||= {}
              new.tap do |instance|
                instance.refund_amount = map['refund_amount']
                instance.royalty_type = map['royalty_type']
                instance.result_code = map['result_code']
                instance.trans_out = map['trans_out']
                instance.trans_out_email = map['trans_out_email']
                instance.trans_in = map['trans_in']
                instance.trans_in_email = map['trans_in_email']
              end
            end

            def to_map
              {
                'refund_amount' => refund_amount,
                'royalty_type' => royalty_type,
                'result_code' => result_code,
                'trans_out' => trans_out,
                'trans_out_email' => trans_out_email,
                'trans_in' => trans_in,
                'trans_in_email' => trans_in_email
              }.delete_if { |_key, value| value.nil? }
            end
          end
        end
      end
    end
  end
end
