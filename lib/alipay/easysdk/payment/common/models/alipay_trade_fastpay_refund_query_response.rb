require_relative 'base_response'
require_relative 'trade_fund_bill'
require_relative 'refund_royalty_result'

module Alipay
  module EasySDK
    module Payment
      module Common
        module Models
          class AlipayTradeFastpayRefundQueryResponse < BaseResponse
            attr_accessor :http_body, :code, :msg, :sub_code, :sub_msg,
                          :error_code, :gmt_refund_pay, :industry_sepc_detail,
                          :out_request_no, :out_trade_no, :present_refund_buyer_amount,
                          :present_refund_discount_amount, :present_refund_mdiscount_amount,
                          :refund_amount, :refund_charge_amount, :refund_detail_item_list,
                          :refund_reason, :refund_royaltys, :refund_settlement_id,
                          :refund_status, :send_back_fee, :total_amount, :trade_no

            def self.from_map(map = {})
              map ||= {}
              new.tap do |instance|
                instance.http_body = map['http_body']
                instance.body = map['http_body'] if instance.respond_to?(:body=)
                instance.code = map['code']
                instance.msg = map['msg']
                instance.sub_code = map['sub_code']
                instance.sub_msg = map['sub_msg']
                instance.error_code = map['error_code']
                instance.gmt_refund_pay = map['gmt_refund_pay']
                instance.industry_sepc_detail = map['industry_sepc_detail']
                instance.out_request_no = map['out_request_no']
                instance.out_trade_no = map['out_trade_no']
                instance.present_refund_buyer_amount = map['present_refund_buyer_amount']
                instance.present_refund_discount_amount = map['present_refund_discount_amount']
                instance.present_refund_mdiscount_amount = map['present_refund_mdiscount_amount']
                instance.refund_amount = map['refund_amount']
                instance.refund_charge_amount = map['refund_charge_amount']
                instance.refund_detail_item_list = build_refund_detail_items(map['refund_detail_item_list'])
                instance.refund_reason = map['refund_reason']
                instance.refund_royaltys = build_refund_royaltys(map['refund_royaltys'])
                instance.refund_settlement_id = map['refund_settlement_id']
                instance.refund_status = map['refund_status']
                instance.send_back_fee = map['send_back_fee']
                instance.total_amount = map['total_amount']
                instance.trade_no = map['trade_no']
              end
            end

            def to_map
              result = {}
              result['http_body'] = http_body unless http_body.nil?
              result['code'] = code unless code.nil?
              result['msg'] = msg unless msg.nil?
              result['sub_code'] = sub_code unless sub_code.nil?
              result['sub_msg'] = sub_msg unless sub_msg.nil?
              result['error_code'] = error_code unless error_code.nil?
              result['gmt_refund_pay'] = gmt_refund_pay unless gmt_refund_pay.nil?
              result['industry_sepc_detail'] = industry_sepc_detail unless industry_sepc_detail.nil?
              result['out_request_no'] = out_request_no unless out_request_no.nil?
              result['out_trade_no'] = out_trade_no unless out_trade_no.nil?
              result['present_refund_buyer_amount'] = present_refund_buyer_amount unless present_refund_buyer_amount.nil?
              result['present_refund_discount_amount'] = present_refund_discount_amount unless present_refund_discount_amount.nil?
              result['present_refund_mdiscount_amount'] = present_refund_mdiscount_amount unless present_refund_mdiscount_amount.nil?
              result['refund_amount'] = refund_amount unless refund_amount.nil?
              result['refund_charge_amount'] = refund_charge_amount unless refund_charge_amount.nil?
              if refund_detail_item_list
                result['refund_detail_item_list'] = refund_detail_item_list.map do |item|
                  item.respond_to?(:to_map) ? item.to_map : item
                end
              end
              result['refund_reason'] = refund_reason unless refund_reason.nil?
              if refund_royaltys
                result['refund_royaltys'] = refund_royaltys.map do |item|
                  item.respond_to?(:to_map) ? item.to_map : item
                end
              end
              result['refund_settlement_id'] = refund_settlement_id unless refund_settlement_id.nil?
              result['refund_status'] = refund_status unless refund_status.nil?
              result['send_back_fee'] = send_back_fee unless send_back_fee.nil?
              result['total_amount'] = total_amount unless total_amount.nil?
              result['trade_no'] = trade_no unless trade_no.nil?
              result
            end

            def self.build_refund_detail_items(items)
              return nil unless items.is_a?(Array)

              items.map do |item|
                item.nil? ? nil : TradeFundBill.from_map(item)
              end
            end
            private_class_method :build_refund_detail_items

            def self.build_refund_royaltys(items)
              return nil unless items.is_a?(Array)

              items.map do |item|
                item.nil? ? nil : RefundRoyaltyResult.from_map(item)
              end
            end
            private_class_method :build_refund_royaltys
          end
        end
      end
    end
  end
end
