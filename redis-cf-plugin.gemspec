# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "redis-cf-plugin"
  spec.version       = "0.1.0"
  spec.authors       = ["Dr Nic Williams"]
  spec.email         = ["drnicwilliams@gmail.com"]
  spec.description   = %q{Create & bind dedicated Redis to Cloud Foundry apps using Bosh}
  spec.summary       = %q{Create & bind dedicated Redis to Cloud Foundry apps using Bosh}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "cf", "~> 4.1"
  spec.add_runtime_dependency "bosh_cli", "~> 1.5.0.pre"
  spec.add_runtime_dependency "rake"

  spec.add_development_dependency "bundler", "~> 1.3"
end
