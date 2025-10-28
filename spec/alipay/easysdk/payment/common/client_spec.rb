# frozen_string_literal: true

require 'spec_helper'
require 'json'

RSpec.describe Alipay::EasySDK::Payment::Common::Client do
  let(:config) do
    Alipay::EasySDK::Kernel::Config.new(
      protocol: 'https',
      gateway_host: 'openapi.alipay.com/gateway.do',
      app_id: 'app-id',
      merchant_private_key: SpecSupport::TestKeys::RSA_PRIVATE_KEY,
      alipay_public_key: SpecSupport::TestKeys::RSA_PUBLIC_KEY
    )
  end

  let(:kernel) { Alipay::EasySDK::Kernel::EasySDKKernel.new(config) }
  let(:client) { described_class.new(kernel) }
  let(:signer) { Alipay::EasySDK::Kernel::Util::Signer.new }

  def build_signed_response(method, payload)
    content = payload.to_json
    signature = signer.sign(content, SpecSupport::TestKeys::RSA_PRIVATE_KEY)

    { "#{method.tr('.', '_')}_response" => payload, 'sign' => signature }.to_json
  end

  describe '#create' do
    it 'performs the API call and hydrates a typed response model' do
      body = build_signed_response('alipay.trade.create', 'code' => '10000', 'trade_no' => '20240101000001')
      http_response = double(body: body)

      expect(client).to receive(:perform_http_request) do |uri, request|
        expect(uri.host).to eq('openapi.alipay.com')
        expect(uri.path).to eq('/gateway.do')
        expect(uri.query).to include('method=alipay.trade.create')
        expect(request.body).to include('biz_content')
        http_response
      end

      response = client.create('Subject', 'ORDER-1', '9.00', '2088')

      expect(response).to be_a(Alipay::EasySDK::Payment::Common::Models::AlipayTradeCreateResponse)
      expect(response).to be_success
      expect(response.trade_no).to eq('20240101000001')
      expect(response.body).to eq(body)
    end
  end

  describe 'state management' do
    it 'clears optional parameters after each request' do
      client.optional('extra', 'value')
      client.async_notify('https://notify.example.com')

      allow(client).to receive(:perform_http_request).and_return(double(body: build_signed_response('alipay.trade.close', 'code' => '10000')))

      client.close('ORDER-1')

      expect(kernel.optional_biz_params).to be_empty
      expect(kernel.optional_text_params).to be_empty
    end
  end

  describe '#perform_http_request' do
    let(:uri) { URI('https://openapi.alipay.com/gateway.do?foo=bar') }
    let(:request) { Net::HTTP::Post.new(uri.request_uri) }

    it 'respects proxy and ignore_ssl configuration' do
      config.http_proxy = 'http://proxy.example.com:8080'
      config.ignore_ssl = true

      http_double = instance_double(Net::HTTP)
      expect(Net::HTTP).to receive(:new).with('openapi.alipay.com', 443, 'proxy.example.com', 8080, nil, nil).and_return(http_double)
      expect(http_double).to receive(:use_ssl=).with(true)
      allow(http_double).to receive(:use_ssl?).and_return(true)
      expect(http_double).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      expect(http_double).to receive(:open_timeout=).with(15)
      expect(http_double).to receive(:read_timeout=).with(15)
      expect(http_double).to receive(:request).with(request).and_return(double(body: build_signed_response('alipay.trade.query', 'code' => '10000')))

      client.send(:perform_http_request, uri, request)
    end
  end

  describe '#verify_notify' do
    it 'verifies notifications using the configured public key in key mode' do
      params = { 'biz_content' => 'value' }

      expect(kernel).to receive(:verify_params).with(params, SpecSupport::TestKeys::RSA_PUBLIC_KEY).and_return(true)

      expect(client.verify_notify(params)).to be(true)
    end

    it 'uses certificate mode when merchant_cert_sn is present' do
      config.merchant_cert_sn = 'cert-sn'
      allow(kernel).to receive(:extract_alipay_public_key).and_return('cert-public-key')
      allow(kernel).to receive(:get_alipay_cert_sn).and_return('alipay-cert-sn')

      expect(kernel).to receive(:verify_params).with({ 'biz_content' => 'value' }, 'cert-public-key').and_return(true)

      expect(client.verify_notify('biz_content' => 'value')).to be(true)
    end
  end
end
