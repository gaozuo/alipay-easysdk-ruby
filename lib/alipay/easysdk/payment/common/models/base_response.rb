module Alipay
  module EasySDK
    module Payment
      module Common
        module Models
          class BaseResponse
            attr_accessor :body

            def self.from_map(map = {})
              new.tap do |instance|
                map.each do |key, value|
                  method_name = key.to_s
                  method_name = method_name.gsub(/[^a-zA-Z0-9_]/, '_')
                  unless instance.respond_to?(method_name)
                    instance.singleton_class.class_eval do
                      attr_accessor method_name
                    end
                  end
                  instance.public_send("#{method_name}=", value)
                end
              end
            end
          end
        end
      end
    end
  end
end
