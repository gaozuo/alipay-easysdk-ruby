# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Common::Models::BaseResponse do
  describe '.from_map' do
    it 'hydrates a dynamic response object while keeping the raw body' do
      map = {
        'code' => '10000',
        'msg' => 'Success',
        'order_id' => '202401010001',
        'body' => '{"code":"10000"}'
      }

      response = described_class.from_map(map)

      expect(response.code).to eq('10000')
      expect(response.msg).to eq('Success')
      expect(response.order_id).to eq('202401010001')
      expect(response.body).to eq('{"code":"10000"}')
    end
  end

  describe '#success?' do
    it 'is successful when code equals 10000' do
      response = described_class.from_map('code' => '10000')

      expect(response).to be_success
    end

    it 'is unsuccessful for other codes' do
      response = described_class.from_map('code' => '40004')

      expect(response).not_to be_success
    end
  end

  describe '#error_message' do
    it 'prefers sub_msg when present' do
      response = described_class.from_map('sub_msg' => 'Detailed error', 'msg' => 'Error')

      expect(response.error_message).to eq('Detailed error')
    end

    it 'falls back to msg' do
      response = described_class.from_map('msg' => 'Generic error')

      expect(response.error_message).to eq('Generic error')
    end
  end
end
