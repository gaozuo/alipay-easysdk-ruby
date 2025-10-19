# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Alipay::EasySDK::Kernel::Util::SignContentExtractor do
  subject(:extractor) { described_class.new }

  let(:body) do
    {
      'alipay_trade_query_response' => { 'code' => '10000', 'msg' => 'Success' },
      'sign' => 'abc123'
    }.to_json
  end

  it 'extracts the response node content for a successful response' do
    content = extractor.get_sign_source_data(body, 'alipay.trade.query')

    expect(content).to include('"code":"10000"')
    expect(content).not_to include('"sign":"')
  end

  it 'switches to error response when present' do
    error_body = {
      'error_response' => { 'code' => '40004', 'msg' => 'Business Failed' },
      'sign' => 'abc123'
    }.to_json

    content = extractor.get_sign_source_data(error_body, 'alipay.trade.query')

    expect(content).to include('"msg":"Business Failed"')
  end

  it 'raises when duplicate response nodes exist' do
    duplicated = body.sub('alipay_trade_query_response', 'alipay_trade_query_response.alipay_trade_query_response')

    expect do
      extractor.get_sign_source_data(duplicated, 'alipay.trade.query')
    end.to raise_error('检测到响应报文中有重复的alipay_trade_query_response,验签失败。')
  end
end
