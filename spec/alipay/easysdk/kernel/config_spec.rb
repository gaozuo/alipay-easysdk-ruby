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

  it 'defaults to the documented values' do
    expect(config.protocol).to eq('https')
    expect(config.gateway_host).to eq('openapi.alipay.com/gateway.do')
    expect(config.sign_type).to eq('RSA2')
    expect(config.charset).to eq('UTF-8')
    expect(config.format).to eq('json')
    expect(config.version).to eq('1.0')
  end

  it 'builds the expected gateway url' do
    expect(config.gateway_url).to eq('https://openapi.alipay.com/gateway.do')
  end

  it 'allows overriding configuration values' do
    override = described_class.new(options.merge(protocol: 'http', gateway_host: 'example.com'))

    expect(override.protocol).to eq('http')
    expect(override.gateway_host).to eq('example.com')
    expect(override.gateway_url).to eq('http://example.com')
  end

  describe '#validate' do
    it 'raises when required keys are missing' do
      config = described_class.new

      expect { config.validate }.to raise_error('app_id is required')
    end

    it 'raises when merchant_private_key is blank' do
      config = described_class.new(app_id: 'a', merchant_private_key: '', alipay_public_key: 'pub')

      expect { config.validate }.to raise_error('merchant_private_key is required')
    end

    it 'raises when alipay_public_key is blank' do
      config = described_class.new(app_id: 'a', merchant_private_key: 'key')

      expect { config.validate }.to raise_error('alipay_public_key is required')
    end

    it 'passes when all mandatory keys are provided' do
      expect { config.validate }.not_to raise_error
    end
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
