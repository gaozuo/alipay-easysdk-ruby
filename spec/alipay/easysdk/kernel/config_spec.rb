# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Kernel::Config do
  subject(:config) { described_class.new(options) }

  let(:options) do
    {
      app_id: 'app-id',
      merchant_private_key: SpecSupport::TestKeys::RSA_PRIVATE_KEY,
      alipay_public_key: SpecSupport::TestKeys::RSA_PUBLIC_KEY
    }
  end

  it 'stores only the provided attributes without applying defaults' do
    expect(config.protocol).to be_nil
    expect(config.gateway_host).to be_nil
    expect(config.sign_type).to be_nil
  end

  it 'assigns values verbatim when provided' do
    override = described_class.new(options.merge(protocol: 'http', gatewayHost: 'example.com'))

    expect(override.protocol).to eq('http')
    expect(override.gateway_host).to eq('example.com')
  end

  it 'supports extended configuration fields and camelCase aliases' do
    config = described_class.new(
      options.merge(
        notifyUrl: 'https://notify.example.com',
        httpProxy: '127.0.0.1:8080',
        ignoreSSL: 'true',
        merchantCertPath: '/path/to/merchantCert.crt',
        alipayCertPath: '/path/to/alipayCert.crt',
        alipayRootCertPath: '/path/to/rootCert.crt',
        encryptKey: 'base64key=='
      )
    )

    expect(config.notify_url).to eq('https://notify.example.com')
    expect(config.http_proxy).to eq('127.0.0.1:8080')
    expect(config.ignore_ssl).to eq('true')
    expect(config.merchant_cert_path).to eq('/path/to/merchantCert.crt')
    expect(config.alipay_cert_path).to eq('/path/to/alipayCert.crt')
    expect(config.alipay_root_cert_path).to eq('/path/to/rootCert.crt')
    expect(config.encrypt_key).to eq('base64key==')
  end
end
