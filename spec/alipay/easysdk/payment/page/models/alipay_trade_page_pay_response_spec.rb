# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Page::Models::AlipayTradePagePayResponse do
  let(:response) { described_class.from_map('body' => '<form>page</form>') }

  it 'returns the generated form through convenience helpers' do
    expect(response.body).to eq('<form>page</form>')
    expect(response.form).to eq('<form>page</form>')
    expect(response.to_s).to eq('<form>page</form>')
  end

  it 'is successful whenever a body is present' do
    expect(response).to be_success
  end

  it 'never reports error messages for form responses' do
    expect(response.error_message).to be_nil
  end
end
