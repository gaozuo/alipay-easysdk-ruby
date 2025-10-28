require 'openssl'
require 'digest/md5'

module Alipay
  module EasySDK
    module Kernel
      module Util
        class AntCertificationUtil
          SUPPORTED_SIGNATURES = %w[sha1WithRSAEncryption sha256WithRSAEncryption].freeze

          def cert_sn(cert_path)
            cert = load_certificate(cert_path)
            signature_digest(cert.issuer.to_a, cert.serial)
          end

          def public_key(cert_path)
            cert = load_certificate(cert_path)
            key_pem = cert.public_key.to_pem
            key_pem.gsub(/-----BEGIN PUBLIC KEY-----/, '')
                   .gsub(/-----END PUBLIC KEY-----/, '')
                   .gsub(/\s+/, '')
                   .strip
          end

          def root_cert_sn(cert_path)
            certs = load_cert_chain(cert_path)
            sns = certs.each_with_object([]) do |cert, acc|
              next unless SUPPORTED_SIGNATURES.include?(cert.signature_algorithm)

              acc << signature_digest(cert.issuer.to_a, cert.serial)
            end
            sns.join('_')
          end

          private

          def load_certificate(path)
            raise ArgumentError, '证书路径不能为空' if path.nil? || path.to_s.strip.empty?

            OpenSSL::X509::Certificate.new(File.read(path))
          rescue Errno::ENOENT => e
            raise RuntimeError, "无法读取证书文件: #{path} - #{e.message}"
          end

          def load_cert_chain(path)
            pem = File.read(path)
            pem.split(/(?=-----BEGIN CERTIFICATE-----)/)
               .reject(&:empty?)
               .map { |chunk| OpenSSL::X509::Certificate.new(chunk) }
          rescue Errno::ENOENT => e
            raise RuntimeError, "无法读取证书链文件: #{path} - #{e.message}"
          end

          def signature_digest(issuer_array, serial)
            issuer_str = issuer_array.reverse.map { |name, data, _| "#{name}=#{data}" }.join(',')
            serial_str = serial.to_i.to_s
            Digest::MD5.hexdigest("#{issuer_str}#{serial_str}")
          end
        end
      end
    end
  end
end
