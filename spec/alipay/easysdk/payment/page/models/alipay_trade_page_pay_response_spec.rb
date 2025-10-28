# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Page::Models::AlipayTradePagePayResponse do
  let(:response) do
    described_class.from_map(
      Alipay::EasySDK::Kernel::AlipayConstants::BODY_FIELD => '<form>page</form>'
    )
  end

  it 'returns the generated form through convenience helpers' do
    expect(response.body).to eq('<form>page</form>')
  end

  it 'exposes payment_url when provided' do
    response = described_class.from_map(
      Alipay::EasySDK::Kernel::AlipayConstants::BODY_FIELD => '<form>page</form>',
      'payment_url' => 'https://example.com'
    )

    expect(response.payment_url).to eq('https://example.com')
  end
end
