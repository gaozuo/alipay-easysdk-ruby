# frozen_string_literal: true

require 'spec_helper'

$LOAD_PATH.unshift(File.expand_path('../../../../../lib', __dir__)) unless $LOAD_PATH.include?(File.expand_path('../../../../../lib', __dir__))
require 'alipay/easysdk/payment/app/client'

RSpec.describe 'Alipay::EasySDK::Payment::App::Client' do
  let(:described_class) { Alipay::EasySDK::Payment::App::Client }
  let(:kernel) do
    instance_double(
      Alipay::EasySDK::Kernel::EasySDKKernel,
      get_config: nil,
      get_timestamp: '2024-01-01 00:00:00',
      get_sdk_version: 'alipay-easysdk-ruby-1.0.4',
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

  it 'generates the order string via the kernel' do
    expected_system_params = hash_including('method' => 'alipay.trade.app.pay')
    expected_biz_params = hash_including('total_amount' => '9.00')

    expect(kernel).to receive(:sign).with(expected_system_params, expected_biz_params, {}, SpecSupport::TestKeys::RSA_PRIVATE_KEY).and_return('signature')
    expect(kernel).to receive(:generate_order_string).with(expected_system_params, expected_biz_params, {}, 'signature').and_return('order-string')

    response = client.pay('Subject', 'ORDER-1', '9.00')

    expect(response.body).to eq('order-string')
  end

  it 'pipes helper methods through to the kernel' do
    expect(kernel).to receive(:inject_text_param).with('app_auth_token', 'token')
    expect(kernel).to receive(:inject_text_param).with('auth_token', 'auth')
    expect(kernel).to receive(:inject_text_param).with('notify_url', 'https://notify')
    expect(kernel).to receive(:inject_text_param).with('ws_service_url', 'https://route')
    expect(kernel).to receive(:inject_biz_param).with('timeout_express', '30m')

    client.agent('token')
          .auth('auth')
          .async_notify('https://notify')
          .route('https://route')
          .optional('timeout_express', '30m')
  end
end
