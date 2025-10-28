# frozen_string_literal: true

require 'spec_helper'
require 'base64'

RSpec.describe Alipay::EasySDK::Kernel::Util::AES do
  subject(:aes) { described_class.new }

  let(:key_bytes) { '0123456789abcdef' }
  let(:base64_key) { Base64.strict_encode64(key_bytes) }

  it 'encrypts and decrypts symmetrically' do
    cipher_text = aes.aes_encrypt('plain-text', base64_key)
    expect(cipher_text).not_to be_empty

    plain = aes.aes_decrypt(cipher_text, base64_key)
    expect(plain).to eq('plain-text')
  end

  it 'raises when key is blank' do
    expect { aes.aes_encrypt('data', '') }.to raise_error(StandardError, /AES加密失败/)
    expect { aes.aes_decrypt('cipher', '') }.to raise_error(StandardError, /AES解密失败/)
  end
end
