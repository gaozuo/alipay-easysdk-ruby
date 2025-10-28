# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Kernel::Util::JsonUtil do
  subject(:util) { described_class.new }

  describe '#to_json_string' do
    it 'recursively converts hashes and arrays with underscored keys' do
      payload = {
        'CamelCaseKey' => [{ 'InnerKey' => 'Value' }],
        subject: 'Book'
      }

      expect(util.to_json_string(payload)).to eq(
        'camel_case_key' => [{ 'inner_key' => 'Value' }],
        'subject' => 'Book'
      )
    end

    it 'returns empty hash when payload is nil' do
      expect(util.to_json_string(nil)).to eq({})
    end

    it 'raises when payload is not a hash' do
      expect { util.to_json_string('raw-json') }.to raise_error(ArgumentError)
    end
  end

  describe '.from_json_string' do
    it 'parses valid JSON strings' do
      expect(described_class.from_json_string('{"foo":"bar"}')).to eq('foo' => 'bar')
    end

    it 'returns the original string when parsing fails' do
      expect(described_class.from_json_string('invalid json')).to eq('invalid json')
    end

    it 'returns nil for blank strings' do
      expect(described_class.from_json_string(nil)).to be_nil
      expect(described_class.from_json_string('')).to be_nil
    end
  end
end
