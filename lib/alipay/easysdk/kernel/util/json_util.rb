require 'json'

module Alipay
  module EasySDK
    module Kernel
      module Util
        class JsonUtil
          # 完全复制PHP版本的toJsonString方法
          def to_json_string(obj)
            return {} if obj.nil?
            raise ArgumentError, 'to_json_string expects a Hash' unless obj.is_a?(Hash)
            convert_map(obj)
          end

          def self.from_json_string(json_string)
            return nil if json_string.nil? || json_string.empty?
            JSON.parse(json_string)
          rescue JSON::ParserError
            json_string
          end

          private

          def convert_map(hash)
            return hash unless hash.is_a?(Hash)

            hash.each_with_object({}) do |(key, value), result|
              result[underscore_key(key)] = convert_value(value)
            end
          end

          def convert_value(value)
            case value
            when Hash
              convert_map(value)
            when Array
              value.map { |item| convert_value(item) }
            else
              convert_object(value)
            end
          end

          def convert_object(value)
            return value if primitive?(value)

            if value.respond_to?(:to_h)
              convert_map(value.to_h)
            elsif value.respond_to?(:to_hash)
              convert_map(value.to_hash)
            else
              value
            end
          end

          def underscore_key(key)
            str = key.to_s
            underscored = str.gsub(/([A-Z]+)/) { "_#{$1.downcase}" }
            underscored.gsub(/__+/, '_').sub(/^_/, '')
          end

          def primitive?(value)
            value.is_a?(String) ||
              value.is_a?(Numeric) ||
              value == true ||
              value == false ||
              value.nil?
          end
        end
      end
    end
  end
end
