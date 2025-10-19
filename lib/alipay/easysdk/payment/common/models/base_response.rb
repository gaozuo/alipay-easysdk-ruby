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

            def success?
              respond_to?('code') ? public_send('code') == '10000' : false
            end

            def error_message
              if respond_to?('sub_msg') && public_send('sub_msg')
                public_send('sub_msg')
              elsif respond_to?('msg')
                public_send('msg')
              else
                nil
              end
            end
          end
        end
      end
    end
  end
end
