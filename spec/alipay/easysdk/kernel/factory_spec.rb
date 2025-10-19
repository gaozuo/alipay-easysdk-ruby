# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Kernel::Factory do
  let(:options) do
    {
      protocol: 'https',
      gateway_host: 'openapi.alipay.com/gateway.do',
      app_id: 'app-id',
      merchant_private_key: SpecSupport::TestKeys::RSA_PRIVATE_KEY,
      alipay_public_key: SpecSupport::TestKeys::RSA_PUBLIC_KEY
    }
  end

  describe '.set_options' do
    it 'initializes the SDK context and returns the factory class' do
      expect(described_class.set_options(options)).to eq(described_class)
      expect(described_class.config).to be_a(Alipay::EasySDK::Kernel::Config)
    end

    it 'accepts an already built config instance' do
      config = Alipay::EasySDK::Kernel::Config.new(options)

      expect(described_class.set_options(config)).to eq(described_class)
      expect(described_class.config).to be(config)
    end
  end

  describe 'accessors' do
    before { described_class.set_options(options) }

    it 'provides a payment facade with the three payment client families' do
      expect(described_class.payment).to be_a(described_class::Payment)
      expect(described_class.payment.wap).to be_a(Alipay::EasySDK::Payment::Wap::Client)
      expect(described_class.payment.page).to be_a(Alipay::EasySDK::Payment::Page::Client)
      expect(described_class.payment.common).to be_a(Alipay::EasySDK::Payment::Common::Client)
    end

    it 'exposes convenience shortcuts on the factory class itself' do
      expect(described_class.wap).to be_a(Alipay::EasySDK::Payment::Wap::Client)
      expect(described_class.page).to be_a(Alipay::EasySDK::Payment::Page::Client)
      expect(described_class.common).to be_a(Alipay::EasySDK::Payment::Common::Client)
      expect(described_class.kernel).to be_a(Alipay::EasySDK::Kernel::EasySDKKernel)
    end
  end

  describe 'error handling' do
    it 'raises when accessing config before initialization' do
      expect { described_class.config }.to raise_error(described_class::ConfigurationNotSetError)
    end

    it 'raises when accessing payment before initialization' do
      expect { described_class.payment }.to raise_error(described_class::ConfigurationNotSetError)
    end
  end

  describe '.get_sdk_version' do
    it 'delegates to the SDK constant' do
      expect(described_class.get_sdk_version).to start_with('alipay-easysdk-ruby-')
    end
  end
end
