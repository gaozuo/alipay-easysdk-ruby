# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alipay::EasySDK do
  it "has a version number" do
    expect(Alipay::EasySDK::VERSION).not_to be nil
  end

  it "configures SDK through Factory" do
    config = Alipay::EasySDK.config(
      protocol: 'https',
      gateway_host: 'openapi.alipay.com',
      app_id: 'test_app_id',
      merchant_private_key: 'test_private_key',
      alipay_public_key: 'test_public_key'
    )

    expect(config).to eq(Alipay::EasySDK::Kernel::Factory)
  end

  it "exposes payment wap client" do
    Alipay::EasySDK.config(
      protocol: 'https',
      gateway_host: 'openapi.alipay.com',
      app_id: 'test_app_id',
      merchant_private_key: 'test_private_key',
      alipay_public_key: 'test_public_key'
    )

    expect(Alipay::EasySDK.payment.wap).to respond_to(:pay)
    expect(Alipay::EasySDK.wap).to respond_to(:pay)
    expect(Alipay::EasySDK.payment.page).to respond_to(:pay)
    expect(Alipay::EasySDK.page).to respond_to(:pay)
    expect(Alipay::EasySDK.payment.common).to respond_to(:create)
    expect(Alipay::EasySDK.common).to respond_to(:create)
  end
end
