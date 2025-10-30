# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Page::Client do
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

  it 'generates a page payment form via the kernel' do
    expected_system_params = hash_including('method' => 'alipay.trade.page.pay')
    expected_biz_params = hash_including('product_code' => 'FAST_INSTANT_TRADE_PAY')
    expected_text_params = hash_including('return_url' => 'https://return.example.com')

    expect(kernel).to receive(:sign).with(expected_system_params, expected_biz_params, expected_text_params, SpecSupport::TestKeys::RSA_PRIVATE_KEY).and_return('signature')
    expect(kernel).to receive(:generate_page).with('POST', expected_system_params, expected_biz_params, expected_text_params, 'signature').and_return('<form>page</form>')
    expect(kernel).to receive(:generate_payment_url).with(expected_system_params, expected_biz_params, expected_text_params, 'signature').and_return('https://example.com/gateway?foo=bar')

    response = client.pay('Subject', 'ORDER-1', '9.00', 'https://return.example.com')

    expect(response.body).to eq('<form>page</form>')
    expect(response.payment_url).to eq('https://example.com/gateway?foo=bar')
  end

  it 'pipes helper methods through to the kernel' do
    expect(kernel).to receive(:inject_text_param).with('app_auth_token', 'token')
    expect(kernel).to receive(:inject_text_param).with('auth_token', 'auth')
    expect(kernel).to receive(:inject_text_param).with('notify_url', 'https://notify')
    expect(kernel).to receive(:inject_text_param).with('ws_service_url', 'https://route')
    expect(kernel).to receive(:inject_biz_param).with('promo_params', 'value')

    client.agent('token')
          .auth('auth')
          .async_notify('https://notify')
          .route('https://route')
          .optional('promo_params', 'value')
  end
end
