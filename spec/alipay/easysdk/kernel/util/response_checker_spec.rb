# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Kernel::Util::ResponseChecker do
  subject(:checker) { described_class.new }

  def build_response(attrs = {})
    Struct.new(*attrs.keys.map(&:to_sym)).new(*attrs.values)
  end

  it 'returns true when response code equals 10000' do
    response = build_response(code: '10000', msg: 'Success')

    expect(checker.success?(response)).to be(true)
  end

  it 'returns true when both code and sub_code are blank' do
    response = build_response(body: 'ok')

    expect(checker.success?(response)).to be(true)
  end

  it 'returns false when sub_code is present' do
    response = build_response(code: '40004', sub_code: 'BUSINESS_FAILED')

    expect(checker.success?(response)).to be(false)
  end

  it 'treats camelCase subCode as failure' do
    response = Struct.new(:code, :subCode).new(nil, 'BUSINESS_FAILED')

    expect(checker.success?(response)).to be(false)
  end

  it 'aliases #success to #success?' do
    response = build_response(code: '10000')

    expect(checker.success(response)).to be(true)
  end
end
