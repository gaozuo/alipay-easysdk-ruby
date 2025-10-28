# frozen_string_literal: true

require 'spec_helper'

$LOAD_PATH.unshift(File.expand_path('../../../../../../lib', __dir__)) unless $LOAD_PATH.include?(File.expand_path('../../../../../../lib', __dir__))
require 'alipay/easysdk/payment/app/models/alipay_trade_app_pay_response'

RSpec.describe 'Alipay::EasySDK::Payment::App::Models::AlipayTradeAppPayResponse' do
  let(:described_class) { Alipay::EasySDK::Payment::App::Models::AlipayTradeAppPayResponse }

  it 'stores the generated order string in body' do
    response = described_class.from_map(
      Alipay::EasySDK::Kernel::AlipayConstants::BODY_FIELD => 'order-string'
    )

    expect(response.body).to eq('order-string')
  end
end
