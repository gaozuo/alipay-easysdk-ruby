require 'openssl'
require 'digest/md5'

require_relative 'util/ant_certification_util'

module Alipay
  module EasySDK
    module Kernel
      class CertEnvironment
        attr_reader :root_cert_sn, :merchant_cert_sn

        def initialize
          @cert_util = Util::AntCertificationUtil.new
          @root_cert_sn = nil
          @merchant_cert_sn = nil
          @cached_alipay_public_key = nil
        end

        def setup(merchant_cert_path, alipay_cert_path, alipay_root_cert_path)
          if [merchant_cert_path, alipay_cert_path, alipay_root_cert_path].any? { |path| path.nil? || path.to_s.strip.empty? }
            raise RuntimeError, '证书参数merchantCertPath、alipayCertPath或alipayRootCertPath设置不完整。'
          end

          @root_cert_sn = @cert_util.root_cert_sn(alipay_root_cert_path)
          @merchant_cert_sn = @cert_util.cert_sn(merchant_cert_path)
          @cached_alipay_public_key = @cert_util.public_key(alipay_cert_path)
        end

        def cached_alipay_public_key
          @cached_alipay_public_key
        end
      end
    end
  end
end
