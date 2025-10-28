require_relative 'alipay_constants'
require_relative 'config'
require_relative 'cert_environment'
require_relative 'easy_sdk_kernel'
require_relative '../payment/wap/client'
require_relative '../payment/page/client'
require_relative '../payment/common/client'

module Alipay
  module EasySDK
    module Kernel
      class Factory
        class ConfigurationNotSetError < StandardError; end

        class << self
          def set_options(options = nil)
            config = normalize_config(options)
            initialize_context(config)
            @instance
          end

          alias setOptions set_options

          def config(options = nil)
            return set_options(options) if options
            ensure_context_set!
            @config
          end

          def payment
            ensure_context_set!
            @payment
          end

          def wap
            payment.wap
          end

          def page
            payment.page
          end

          def common
            payment.common
          end

          def kernel
            ensure_context_set!
            @kernel
          end

          def get_sdk_version
            Alipay::EasySDK::Kernel::AlipayConstants::SDK_VERSION
          end

          private

          def normalize_config(options)
            raise ArgumentError, '配置参数不能为空' if options.nil?
            options.is_a?(Config) ? options : Config.new(options)
          end

          def initialize_context(config)
            apply_cert_environment(config)
            config.validate
            @config = config
            @kernel = EasySDKKernel.new(config)
            @payment = Payment.new(@kernel)
            @instance = self
          end

          def ensure_context_set!
            raise ConfigurationNotSetError, '请先调用Factory.set_options(config)设置SDK配置' unless @config
          end

          def apply_cert_environment(config)
            return if config.alipay_cert_path.nil? || config.alipay_cert_path.to_s.strip.empty?

            cert_env = CertEnvironment.new
            cert_env.setup(config.merchant_cert_path, config.alipay_cert_path, config.alipay_root_cert_path)
            config.merchant_cert_sn = cert_env.merchant_cert_sn
            config.alipay_root_cert_sn = cert_env.root_cert_sn
            config.alipay_public_key ||= cert_env.cached_alipay_public_key
          end
        end

        class Payment
          def initialize(kernel)
            @kernel = kernel
          end

          def wap
            @wap ||= Alipay::EasySDK::Payment::Wap::Client.new(@kernel)
          end

          def page
            @page ||= Alipay::EasySDK::Payment::Page::Client.new(@kernel)
          end

          def common
            @common ||= Alipay::EasySDK::Payment::Common::Client.new(@kernel)
          end
        end
      end
    end
  end
end
