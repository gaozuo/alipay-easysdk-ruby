require 'json'

module Alipay
  module EasySDK
    module Kernel
      module Util
        class JsonUtil
          # 完全复制PHP版本的toJsonString方法
          def to_json_string(obj)
            case obj
            when Hash, Array
              JSON.generate(obj)
            when String
              obj
            else
              obj.to_s
            end
          end

          def self.from_json_string(json_string)
            return nil if json_string.nil? || json_string.empty?
            JSON.parse(json_string)
          rescue JSON::ParserError
            json_string
          end
        end
      end
    end
  end
end
