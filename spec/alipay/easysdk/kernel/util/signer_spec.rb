# frozen_string_literal: true

require 'spec_helper'
require 'base64'

RSpec.describe Alipay::EasySDK::Kernel::Util::Signer do
  subject(:signer) { described_class.new }

  let(:content) { 'subject=Book&amount=10.00' }
  let(:private_key) { SpecSupport::TestKeys::RSA_PRIVATE_KEY }
  let(:public_key) { SpecSupport::TestKeys::RSA_PUBLIC_KEY }

  describe '#sign / #verify' do
    it 'creates an RSA2 signature that can be verified with the matching public key' do
      signature = signer.sign(content, private_key)

      expect(signature).to be_a(String)
      expect(Base64.strict_decode64(signature)).not_to be_empty
      expect(signer.verify(content, signature, public_key)).to be(true)
    end

    it 'returns false when the payload changes' do
      signature = signer.sign(content, private_key)

      expect(signer.verify('tampered', signature, public_key)).to be(false)
    end

    it 'raises a helpful error when the private key format is invalid' do
      expect { signer.sign(content, 'invalid') }.to raise_error('您使用的私钥格式错误，请检查RSA私钥配置')
    end
  end

  describe '#verify_params' do
    it 'ignores sign and sign_type fields when building the string to verify' do
      parameters = { 'biz_content' => 'value', 'sign' => 'abc', 'sign_type' => 'RSA2' }

      expect(signer.verify_params(parameters.merge('sign' => signer.sign('biz_content=value', private_key)), public_key)).to be(true)
    end

    it 'handles symbol keyed hashes by normalizing keys like PHP implementation' do
      parameters = {
        biz_content: 'value',
        sign_type: 'RSA2'
      }
      content = signer.get_sign_content(parameters.merge(sign: 'tmp'))
      signature = signer.sign(content, private_key)

      expect(signer.verify_params(parameters.merge(sign: signature), public_key)).to be(true)
    end
  end

  describe '#get_sign_content' do
    it 'sorts keys alphabetically and removes sign/sign_type' do
      params = { 'b' => '2', 'a' => '1', 'sign' => 'sig', 'sign_type' => 'RSA2' }

      expect(signer.get_sign_content(params)).to eq('a=1&b=2')
    end

    it 'converts symbol keys to strings before sorting like PHP ksort' do
      params = { b: '2', a: '1', sign: 'sig', sign_type: 'RSA2' }

      expect(signer.get_sign_content(params)).to eq('a=1&b=2')
    end
  end
end
