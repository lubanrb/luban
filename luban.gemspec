# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'luban/deployment/version'

Gem::Specification.new do |spec|
  spec.name          = "luban"
  spec.version       = Luban::Deployment::VERSION
  spec.authors       = ["Rubyist Lei"]
  spec.email         = ["rubyist.chi@gmail.com"]

  spec.summary       = %q{Ruby framework for server automation and application deployment}
  spec.description   = %q{Luban is a framework to manage server automation and application deployment}
  spec.homepage      = "https://github.com/lubanrb/luban"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1.0"
  spec.add_dependency 'luban-cli'
  spec.add_dependency 'sshkit'
  
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
