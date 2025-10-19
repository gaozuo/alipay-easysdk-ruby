module FactoryHelpers
  def reset_factory!
    factory = Alipay::EasySDK::Kernel::Factory
    %i[@config @kernel @payment @instance].each do |ivar|
      factory.instance_variable_set(ivar, nil)
    end
  end
end

RSpec.configure do |config|
  config.include FactoryHelpers

  config.before(:each) { reset_factory! }
end
