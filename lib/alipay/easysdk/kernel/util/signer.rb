require 'base64'
require 'openssl'

module Alipay
  module EasySDK
    module Kernel
      module Util
        class Signer
          # 完全复制PHP版本的sign方法
          def sign(content, private_key_pem)
            begin
              pri_key = private_key_pem

              # 完全按照PHP的逻辑：wordwrap($priKey, 64, "\n", true)
              res = "-----BEGIN RSA PRIVATE KEY-----\n" +
                    wordwrap(pri_key, 64, "\n", true) +
                    "\n-----END RSA PRIVATE KEY-----"

              if res.nil? || res.empty?
                raise '您使用的私钥格式错误，请检查RSA私钥配置'
              end

              # 使用SHA256算法签名，完全模仿PHP的openssl_sign
              private_key = OpenSSL::PKey::RSA.new(res)
              digest = OpenSSL::Digest::SHA256.new
              sign = private_key.sign(digest, content)

            # 使用标准Base64编码，完全模仿PHP的base64_encode
            Base64.strict_encode64(sign)
            rescue
              raise '您使用的私钥格式错误，请检查RSA私钥配置'
            end
          end

          # 完全复制PHP版本的verify方法
          def verify(content, sign, public_key_pem)
            begin
              pub_key = public_key_pem

              # 完全按照PHP的逻辑：wordwrap($pubKey, 64, "\n", true)
              res = "-----BEGIN PUBLIC KEY-----\n" +
                    wordwrap(pub_key, 64, "\n", true) +
                    "\n-----END PUBLIC KEY-----"

              if res.nil? || res.empty?
                raise '支付宝RSA公钥错误。请检查公钥文件格式是否正确'
              end

              # 调用openssl内置方法验签，完全模仿PHP的openssl_verify
              public_key = OpenSSL::PKey::RSA.new(res)
              digest = OpenSSL::Digest::SHA256.new
              decoded_sign = Base64.decode64(sign)

              result = public_key.verify(digest, decoded_sign, content)
              return result
            rescue
              return false
            end
          end

          def verify_params(parameters, public_key)
            sign = parameters['sign']
            content = get_sign_content(parameters)
            return verify(content, sign, public_key)
          end

          def get_sign_content(params)
            # 模拟PHP的ksort
            sorted_params = params.sort_by { |k, _| k.to_s }.to_h

            # 移除sign和sign_type字段
            sorted_params.delete('sign')
            sorted_params.delete('sign_type')

            string_to_be_signed = ""
            i = 0
            sorted_params.each do |k, v|
              if v.to_s[0] != "@"
                if i == 0
                  string_to_be_signed += "#{k}=#{v}"
                else
                  string_to_be_signed += "&#{k}=#{v}"
                end
                i += 1
              end
            end
            return string_to_be_signed
          end

          private

          # 完全复制PHP的wordwrap函数
          def wordwrap(str, width = 75, break_str = "\n", cut = false)
            if str.nil? || str.empty?
              return str
            end

            if cut
              # 如果cut为true，强制在指定宽度处断开
              str.scan(/.{1,#{width}}/).join(break_str)
            else
              # 默认行为，不在单词中间断开
              result = []
              current_line = ""

              str.split.each do |word|
                if current_line.empty?
                  current_line = word
                elsif current_line.length + 1 + word.length <= width
                  current_line += " " + word
                else
                  result << current_line
                  current_line = word
                end
              end

              result << current_line unless current_line.empty?
              result.join(break_str)
            end
          end
        end
      end
    end
  end
end
