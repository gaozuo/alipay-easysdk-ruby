# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK::Payment::Common::Models::BaseResponse do
  describe '.from_map' do
    it 'hydrates a dynamic response object while keeping the raw body' do
      map = {
        'code' => '10000',
        'msg' => 'Success',
        'order_id' => '202401010001',
        'http_body' => '{"code":"10000"}'
      }

      response = described_class.from_map(map)

      expect(response.code).to eq('10000')
      expect(response.msg).to eq('Success')
      expect(response.order_id).to eq('202401010001')
      expect(response.http_body).to eq('{"code":"10000"}')
    end
  end

  it 'allows direct access to fields without additional helpers' do
    response = described_class.from_map('code' => '10000', 'msg' => 'Success')

    expect(response.code).to eq('10000')
    expect(response.msg).to eq('Success')
  end
end
