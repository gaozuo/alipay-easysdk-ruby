# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Wap::Client do
  let(:kernel) do
    instance_double(
      Alipay::EasySDK::Kernel::EasySDKKernel,
      get_config: nil,
      get_timestamp: '2024-01-01 00:00:00',
      get_sdk_version: 'alipay-easysdk-ruby-1.0.0',
      get_merchant_cert_sn: nil,
      get_alipay_root_cert_sn: nil
    )
  end

  subject(:client) { described_class.new(kernel) }

  before do
    allow(kernel).to receive(:get_config).with('appId').and_return('app-id')
    allow(kernel).to receive(:get_config).with('signType').and_return('RSA2')
    allow(kernel).to receive(:get_config).with('merchantPrivateKey').and_return(SpecSupport::TestKeys::RSA_PRIVATE_KEY)
  end

  describe '#pay' do
    it 'builds the request, signs it and wraps the generated form' do
      expected_system_params = hash_including(
        'method' => 'alipay.trade.wap.pay',
        'app_id' => 'app-id',
        'sign_type' => 'RSA2'
      )
      expected_biz_params = hash_including(
        'subject' => 'Subject',
        'total_amount' => '9.00',
        'product_code' => 'QUICK_WAP_WAY'
      )
      expected_text_params = hash_including('return_url' => 'https://return.example.com')

      expect(kernel).to receive(:sign).with(expected_system_params, expected_biz_params, expected_text_params, SpecSupport::TestKeys::RSA_PRIVATE_KEY).and_return('signature')
      expect(kernel).to receive(:generate_page).with('POST', expected_system_params, expected_biz_params, expected_text_params, 'signature').and_return('<form></form>')

      response = client.pay('Subject', 'ORDER-1', '9.00', 'https://quit.example.com', 'https://return.example.com')

      expect(response).to be_success
      expect(response.form).to eq('<form></form>')
    end
  end

  describe 'optional parameter helpers' do
    it 'delegates text params helpers to the kernel' do
      expect(kernel).to receive(:inject_text_param).with('app_auth_token', 'token')
      expect(kernel).to receive(:inject_text_param).with('auth_token', 'auth')
      expect(kernel).to receive(:inject_text_param).with('notify_url', 'https://notify')
      expect(kernel).to receive(:inject_text_param).with('ws_service_url', 'https://route')

      client.agent('token').auth('auth').async_notify('https://notify').route('https://route')
    end

    it 'delegates biz param helpers to the kernel' do
      expect(kernel).to receive(:inject_biz_param).with('seller_id', '2088')
      expect(kernel).to receive(:inject_biz_param).with('foo', 'bar')

      client.optional('seller_id', '2088').batch_optional('foo' => 'bar')
    end
  end
end
