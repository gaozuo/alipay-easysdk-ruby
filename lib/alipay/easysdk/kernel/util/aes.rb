require 'openssl'
require 'base64'

module Alipay
  module EasySDK
    module Kernel
      module Util
        class AES
          def aes_encrypt(plain_text, key)
            raise encryption_error(plain_text, key) if key.to_s.empty?

            secret_key = Base64.decode64(key)
            padded = add_pkcs7_padding(plain_text.to_s)

            cipher = OpenSSL::Cipher.new('AES-128-CBC')
            cipher.encrypt
            cipher.key = secret_key
            cipher.iv = "\0" * 16
            cipher.padding = 0

            encrypted = cipher.update(padded) + cipher.final
            Base64.strict_encode64(encrypted)
          rescue StandardError => e
            raise StandardError, "AES加密失败，plainText=#{plain_text}，keySize=#{key.to_s.length}。#{e.message}"
          end

          def aes_decrypt(cipher_text, key)
            raise decryption_error(cipher_text, key) if key.to_s.empty?

            secret_key = Base64.decode64(key)
            encrypted = Base64.decode64(cipher_text)

            decipher = OpenSSL::Cipher.new('AES-128-CBC')
            decipher.decrypt
            decipher.key = secret_key
            decipher.iv = "\0" * 16
            decipher.padding = 0

            decrypted = decipher.update(encrypted) + decipher.final
            strip_pkcs7_padding(decrypted)
          rescue StandardError => e
            raise StandardError, "AES解密失败，cipherText=#{cipher_text}，keySize=#{key.to_s.length}。#{e.message}"
          end

          private

          def add_pkcs7_padding(source)
            str = source.to_s.strip
            block = 16
            pad = block - (str.bytesize % block)
            pad = block if pad.zero?
            str + (pad.chr * pad)
          end

          def strip_pkcs7_padding(source)
            return source if source.nil? || source.empty?

            char = source[-1]
            num = char.ord
            return source if num == 62
            source[0...-num]
          end

          def encryption_error(plain_text, key)
            StandardError.new("AES加密失败，plainText=#{plain_text}，AES密钥为空。")
          end

          def decryption_error(cipher_text, key)
            StandardError.new("AES解密失败，cipherText=#{cipher_text}，AES密钥为空。")
          end
        end
      end
    end
  end
end
