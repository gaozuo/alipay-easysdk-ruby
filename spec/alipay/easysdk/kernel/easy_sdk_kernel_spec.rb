# frozen_string_literal: true

require 'spec_helper'
require 'cgi'
require 'json'
require 'uri'

RSpec.describe Alipay::EasySDK::Kernel::EasySDKKernel do
  subject(:kernel) { described_class.new(config) }

  let(:config) do
    Alipay::EasySDK::Kernel::Config.new(
      protocol: 'https',
      gateway_host: 'openapi.alipay.com/gateway.do',
      app_id: 'app-id',
      merchant_private_key: SpecSupport::TestKeys::RSA_PRIVATE_KEY,
      alipay_public_key: SpecSupport::TestKeys::RSA_PUBLIC_KEY,
      notify_url: 'https://notify.example.com/callback'
    )
  end

  describe '#inject_text_param / #inject_biz_param' do
    it 'merges optional parameters into generated request payloads' do
      kernel.inject_text_param('auth_token', 'AUTH')
      kernel.inject_biz_param('seller_id', '2088')

      body = kernel.to_url_encoded_request_body({ 'subject' => 'Book' })
      decoded = CGI.parse(body)

      expect(decoded['biz_content'].first).to include('"seller_id":"2088"')
      expect(decoded['biz_content'].first).to include('"subject":"Book"')
      expect(decoded['auth_token'].first).to eq('AUTH')
    end
  end

  describe '#sign' do
    let(:signer) { instance_double(Alipay::EasySDK::Kernel::Util::Signer) }

    let(:system_params) do
      {
        'method' => 'alipay.trade.create',
        'timestamp' => '2024-01-01 12:00:00',
        'app_id' => 'app-id',
        'sign_type' => 'RSA2'
      }
    end

    let(:biz_params) { { 'subject' => 'Book', 'amount' => '10.00' } }
    let(:text_params) { { 'return_url' => 'https://example.com' } }

    before do
      allow(Alipay::EasySDK::Kernel::Util::Signer).to receive(:new).and_return(signer)
    end

    it 'builds the canonical sign content and delegates to Signer' do
      expect(signer).to receive(:sign) do |content, private_key|
        expect(content).to include('biz_content={"subject":"Book","amount":"10.00"}')
        expect(content).to include('method=alipay.trade.create')
        expect(content).to include('return_url=https://example.com')
        expect(private_key).to eq(config.merchant_private_key)
        'signed-content'
      end

      expect(kernel.sign(system_params, biz_params, text_params, config.merchant_private_key)).to eq('signed-content')
    end
  end

  describe '#generate_page' do
    let(:system_params) { { 'method' => 'foo' } }
    let(:text_params) { { 'return_url' => "https://example.com/with'special" } }

    it 'builds a POST auto-submit form with escaped values' do
      html = kernel.generate_page('POST', system_params, { 'subject' => 'Book' }, text_params, 'signature123')

      expect(html).to include("<form id='alipaysubmit'")
      expect(html).to include("name='return_url' value='https://example.com/with&apos;special'")
      expect(html).to include("name='sign' value='signature123'")
      expect(html).to include("action='https://openapi.alipay.com/gateway.do?charset=UTF-8'")
    end

    it 'builds a GET gateway url with sign appended' do
      expected_url = kernel.generate_payment_url(system_params, {}, {}, 'signature123')
      url = kernel.generate_page('GET', system_params, {}, {}, 'signature123')

      expect(url).to eq(expected_url)
      expect(url).to start_with('https://openapi.alipay.com/gateway.do?charset=UTF-8&')
      expect(url).to include('sign=signature123')
    end
  end

  describe '#generate_payment_url' do
    let(:system_params) { { 'method' => 'foo' } }

    it 'reuses the existing parameter assembly for gateway urls' do
      payment_url = kernel.generate_payment_url(system_params, { 'subject' => 'Book' }, { 'return_url' => 'https://example.com' }, 'signature123')
      query = CGI.parse(URI(payment_url).query)

      expect(query['sign'].first).to eq('signature123')
      expect(query['method'].first).to eq('foo')
      expect(query['return_url'].first).to eq('https://example.com')
      expect(query['biz_content'].first).to include('"subject":"Book"')
    end
  end

  describe '#verify' do
    let(:signer) { instance_double(Alipay::EasySDK::Kernel::Util::Signer, verify: true) }

    before do
      allow(Alipay::EasySDK::Kernel::Util::SignContentExtractor).to receive(:new).and_call_original
      allow(Alipay::EasySDK::Kernel::Util::Signer).to receive(:new).and_return(signer)
    end

    it 'delegates to Signer with extracted payload' do
      payload = {
        'body' => { 'alipay_trade_query_response' => { 'code' => '10000' }, 'sign' => 'abc' }.to_json,
        'method' => 'alipay.trade.query'
      }

      expect(signer).to receive(:verify) do |content, sign, public_key|
        expect(content).to include('"code":"10000"')
        expect(sign).to eq('abc')
        expect(public_key).to eq(SpecSupport::TestKeys::RSA_PUBLIC_KEY)
        true
      end

      expect(kernel.verify(payload, SpecSupport::TestKeys::RSA_PUBLIC_KEY)).to be(true)
    end
  end

  it 'exposes configuration values via get_config' do
    expect(kernel.get_config('appId')).to eq('app-id')
    expect(kernel.get_config('gatewayHost')).to eq('openapi.alipay.com/gateway.do')
    expect(kernel.get_config('signType')).to eq('RSA2')
    expect(kernel.get_config('notifyUrl')).to eq('https://notify.example.com/callback')
    expect(kernel.get_config('notify_url')).to eq('https://notify.example.com/callback')
    expect(kernel.get_config('unknown')).to be_nil
  end

  it 'concatenates strings via concat_str' do
    expect(kernel.concat_str('a', 'b')).to eq('ab')
  end
end
