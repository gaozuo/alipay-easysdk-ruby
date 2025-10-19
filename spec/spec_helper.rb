# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'
WebMock.disable_net_connect!(allow_localhost: true)

# 加载 EasySDK 主入口
require_relative '../lib/alipay/easysdk'

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end
