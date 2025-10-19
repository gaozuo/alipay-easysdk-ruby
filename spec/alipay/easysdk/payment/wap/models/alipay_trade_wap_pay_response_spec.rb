# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Wap::Models::AlipayTradeWapPayResponse do
  let(:response) { described_class.from_map('body' => '<form>body</form>') }

  it 'exposes the raw HTML form' do
    expect(response.body).to eq('<form>body</form>')
    expect(response.form).to eq('<form>body</form>')
    expect(response.to_s).to eq('<form>body</form>')
  end

  it 'is successful when body is present' do
    expect(response).to be_success
  end

  it 'returns nil as error message, matching PHP parity behaviour' do
    expect(response.error_message).to be_nil
  end
end
