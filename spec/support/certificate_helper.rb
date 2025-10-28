require 'tmpdir'
require 'fileutils'
require 'openssl'

module SpecSupport
  module CertificateHelper
    module_function

    def with_certificate_suite
      Dir.mktmpdir('alipay_easysdk_cert_suite') do |dir|
        suite = build_suite(dir)
        yield suite
      end
    end

    def build_suite(dir)
      root_key = OpenSSL::PKey::RSA.new(2048)
      root_cert = build_root_certificate(root_key)

      alipay_key = OpenSSL::PKey::RSA.new(2048)
      alipay_cert = build_leaf_certificate(
        key: alipay_key,
        subject: '/C=CN/O=Alipay/CN=AlipayPublicKey',
        issuer_cert: root_cert,
        issuer_key: root_key,
        serial: 2
      )

      merchant_key = OpenSSL::PKey::RSA.new(2048)
      merchant_cert = build_leaf_certificate(
        key: merchant_key,
        subject: '/C=CN/O=Merchant/CN=MerchantApp',
        issuer_cert: root_cert,
        issuer_key: root_key,
        serial: 3
      )

      root_path = File.join(dir, 'alipayRootCert.crt')
      File.write(root_path, root_cert.to_pem)

      alipay_path = File.join(dir, 'alipayCert.crt')
      File.write(alipay_path, alipay_cert.to_pem)

      merchant_path = File.join(dir, 'merchantCert.crt')
      File.write(merchant_path, merchant_cert.to_pem)

      util = Alipay::EasySDK::Kernel::Util::AntCertificationUtil.new

      {
        merchant_cert_path: merchant_path,
        alipay_cert_path: alipay_path,
        alipay_root_cert_path: root_path,
        merchant_cert_sn: util.cert_sn(merchant_path),
        alipay_root_cert_sn: util.root_cert_sn(root_path),
        alipay_public_key: util.public_key(alipay_path)
      }
    end

    def build_root_certificate(key)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1
      cert.subject = OpenSSL::X509::Name.parse('/C=CN/O=RootCA/CN=AlipayRoot')
      cert.issuer = cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.now - 3600
      cert.not_after = Time.now + 3600 * 24 * 365

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = cert
      cert.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
      cert.add_extension(ef.create_extension('keyUsage', 'keyCertSign,cRLSign', true))
      cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))

      cert.sign(key, OpenSSL::Digest::SHA256.new)
      cert
    end

    def build_leaf_certificate(key:, subject:, issuer_cert:, issuer_key:, serial:)
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = serial
      cert.subject = OpenSSL::X509::Name.parse(subject)
      cert.issuer = issuer_cert.subject
      cert.public_key = key.public_key
      cert.not_before = Time.now - 3600
      cert.not_after = Time.now + 3600 * 24 * 365

      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = cert
      ef.issuer_certificate = issuer_cert
      cert.add_extension(ef.create_extension('basicConstraints', 'CA:FALSE', true))
      cert.add_extension(ef.create_extension('keyUsage', 'digitalSignature,keyEncipherment', true))
      cert.add_extension(ef.create_extension('extendedKeyUsage', 'serverAuth,clientAuth', false))
      cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))

      cert.sign(issuer_key, OpenSSL::Digest::SHA256.new)
      cert
    end
  end
end
