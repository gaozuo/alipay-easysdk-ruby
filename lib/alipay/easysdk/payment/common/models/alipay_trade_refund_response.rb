require_relative 'base_response'
require_relative 'trade_fund_bill'
require_relative 'preset_pay_tool_info'

module Alipay
  module EasySDK
    module Payment
      module Common
        module Models
          class AlipayTradeRefundResponse < BaseResponse
            attr_accessor :http_body, :code, :msg, :sub_code, :sub_msg,
                          :trade_no, :out_trade_no, :buyer_logon_id, :fund_change,
                          :refund_fee, :refund_currency, :gmt_refund_pay, :refund_detail_item_list,
                          :store_name, :buyer_user_id, :refund_preset_paytool_list,
                          :refund_settlement_id, :present_refund_buyer_amount,
                          :present_refund_discount_amount, :present_refund_mdiscount_amount

            def self.from_map(map = {})
              map ||= {}
              new.tap do |instance|
                instance.http_body = map['http_body']
                instance.body = map['http_body'] if instance.respond_to?(:body=)
                instance.code = map['code']
                instance.msg = map['msg']
                instance.sub_code = map['sub_code']
                instance.sub_msg = map['sub_msg']
                instance.trade_no = map['trade_no']
                instance.out_trade_no = map['out_trade_no']
                instance.buyer_logon_id = map['buyer_logon_id']
                instance.fund_change = map['fund_change']
                instance.refund_fee = map['refund_fee']
                instance.refund_currency = map['refund_currency']
                instance.gmt_refund_pay = map['gmt_refund_pay']
                instance.refund_detail_item_list = build_refund_detail_items(map['refund_detail_item_list'])
                instance.store_name = map['store_name']
                instance.buyer_user_id = map['buyer_user_id']
                instance.refund_preset_paytool_list = build_preset_paytool_list(map['refund_preset_paytool_list'])
                instance.refund_settlement_id = map['refund_settlement_id']
                instance.present_refund_buyer_amount = map['present_refund_buyer_amount']
                instance.present_refund_discount_amount = map['present_refund_discount_amount']
                instance.present_refund_mdiscount_amount = map['present_refund_mdiscount_amount']
              end
            end

            def to_map
              result = {}
              result['http_body'] = http_body unless http_body.nil?
              result['code'] = code unless code.nil?
              result['msg'] = msg unless msg.nil?
              result['sub_code'] = sub_code unless sub_code.nil?
              result['sub_msg'] = sub_msg unless sub_msg.nil?
              result['trade_no'] = trade_no unless trade_no.nil?
              result['out_trade_no'] = out_trade_no unless out_trade_no.nil?
              result['buyer_logon_id'] = buyer_logon_id unless buyer_logon_id.nil?
              result['fund_change'] = fund_change unless fund_change.nil?
              result['refund_fee'] = refund_fee unless refund_fee.nil?
              result['refund_currency'] = refund_currency unless refund_currency.nil?
              result['gmt_refund_pay'] = gmt_refund_pay unless gmt_refund_pay.nil?
              if refund_detail_item_list
                result['refund_detail_item_list'] = refund_detail_item_list.map do |item|
                  item.respond_to?(:to_map) ? item.to_map : item
                end
              end
              result['store_name'] = store_name unless store_name.nil?
              result['buyer_user_id'] = buyer_user_id unless buyer_user_id.nil?
              if refund_preset_paytool_list
                result['refund_preset_paytool_list'] = refund_preset_paytool_list.map do |item|
                  item.respond_to?(:to_map) ? item.to_map : item
                end
              end
              result['refund_settlement_id'] = refund_settlement_id unless refund_settlement_id.nil?
              result['present_refund_buyer_amount'] = present_refund_buyer_amount unless present_refund_buyer_amount.nil?
              result['present_refund_discount_amount'] = present_refund_discount_amount unless present_refund_discount_amount.nil?
              result['present_refund_mdiscount_amount'] = present_refund_mdiscount_amount unless present_refund_mdiscount_amount.nil?
              result
            end

            def self.build_refund_detail_items(items)
              return nil unless items.is_a?(Array)

              items.map do |item|
                item.nil? ? nil : TradeFundBill.from_map(item)
              end
            end
            private_class_method :build_refund_detail_items

            def self.build_preset_paytool_list(items)
              return nil unless items.is_a?(Array)

              items.map do |item|
                item.nil? ? nil : PresetPayToolInfo.from_map(item)
              end
            end
            private_class_method :build_preset_paytool_list
          end
        end
      end
    end
  end
end
