require_relative 'easysdk/version'
require_relative 'easysdk/kernel/factory'
require_relative 'easysdk/kernel/util/response_checker'

module Alipay
  module EasySDK
    class Error < StandardError; end

    class << self
      def config(options = {})
        Kernel::Factory.config(options)
      end

      alias configure config

      def payment
        Kernel::Factory.payment
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
    end
  end
end
