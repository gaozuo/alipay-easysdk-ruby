# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Wap::Models::AlipayTradeWapPayResponse do
  it 'stores the rendered form and payment url' do
    response = described_class.from_map(
      Alipay::EasySDK::Kernel::AlipayConstants::BODY_FIELD => '<form>body</form>',
      'payment_url' => 'https://example.com/pay'
    )

    expect(response.body).to eq('<form>body</form>')
    expect(response.payment_url).to eq('https://example.com/pay')
  end
end
