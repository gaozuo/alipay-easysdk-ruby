# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Kernel::Util::JsonUtil do
  subject(:util) { described_class.new }

  describe '#to_json_string' do
    it 'serializes hashes using JSON.generate' do
      expect(util.to_json_string({ subject: 'Book' })).to eq('{"subject":"Book"}')
    end

    it 'returns strings untouched' do
      expect(util.to_json_string('raw-json')).to eq('raw-json')
    end

    it 'falls back to to_s for unsupported objects' do
      object = double(to_s: 'fallback')
      expect(util.to_json_string(object)).to eq('fallback')
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
