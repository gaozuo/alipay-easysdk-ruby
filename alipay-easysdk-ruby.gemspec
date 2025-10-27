# frozen_string_literal: true

require_relative "lib/alipay/easysdk/version"

Gem::Specification.new do |spec|
  spec.name = "alipay-easysdk-ruby"
  spec.version = Alipay::EasySDK::VERSION
  spec.authors = ["Alipay EasySDK Team"]
  spec.email = ["easysdk@alipay.com"]

  spec.summary = "支付宝开放平台Alipay EasySDK的Ruby版本实现"
  spec.description = "Alipay EasySDK Ruby版本 - 提供完整的支付宝支付功能支持，包括当面付、手机网站支付、APP支付、花呗分期等。简化API调用，提供链式调用支持，支持证书模式和公钥模式。"
  spec.homepage = "https://github.com/gaozuo/alipay-easysdk-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "#{spec.homepage}.git"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/main/README.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # 运行时依赖
  # spec.add_dependency "openssl-cms", "~> 0.2"  # 暂时注释，可选依赖

  # 开发依赖
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 3.0"

  # 元数据
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["wiki_uri"] = "#{spec.homepage}/wiki"
end
