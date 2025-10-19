require_relative '../alipay_constants'

module Alipay
  module EasySDK
    module Kernel
      module Util
        class SignContentExtractor
          def initialize
            @response_suffix = "_response"
            @error_response = "error_response"
          end

          # 完全复制PHP版本的getSignSourceData方法
          def get_sign_source_data(body, method)
            root_node_name = method.gsub(".", "_") + @response_suffix
            root_index = body.index(root_node_name)
            if root_index != body.rindex(root_node_name)
              raise '检测到响应报文中有重复的' + root_node_name + ',验签失败。'
            end
            error_index = body.index(@error_response)
            if root_index && root_index > 0
              return parser_json_source(body, root_node_name, root_index)
            elsif error_index && error_index > 0
              return parser_json_source(body, @error_response, error_index)
            else
              return nil
            end
          end

          # 完全复制PHP版本的parserJSONSource方法
          def parser_json_source(response_content, node_name, node_index)
            sign_data_start_index = node_index + node_name.length + 2
            if response_content.include?(AlipayConstants::ALIPAY_CERT_SN_FIELD)
              sign_index = response_content.rindex("\"" + AlipayConstants::ALIPAY_CERT_SN_FIELD + "\"")
            else
              sign_index = response_content.rindex("\"" + AlipayConstants::SIGN_FIELD + "\"")
            end
            # 签名前-逗号
            sign_data_end_index = sign_index - 1
            index_len = sign_data_end_index - sign_data_start_index
            if index_len < 0
              return nil
            end
            return response_content[sign_data_start_index, index_len]
          end
        end
      end
    end
  end
end
