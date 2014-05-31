# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'xlive_services/version'

Gem::Specification.new do |spec|
  spec.name          = 'XLiveServices'
  spec.version       = XLiveServices::VERSION
  spec.authors       = ['Dāvis']
  spec.email         = ['davispuh@gmail.com']
  spec.summary       = 'Interact with Xbox LIVE and Games for Windows LIVE services.'
  spec.description   = 'A library to consume Xbox LIVE and Games for Windows LIVE services.'
  spec.homepage      = 'https://github.com/davispuh/XLiveServices'
  spec.license       = 'UNLICENSE'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'httpi'
  spec.add_runtime_dependency 'multi_xml'
  spec.add_runtime_dependency 'LiveIdentity', '>= 0.0.2'
  spec.add_runtime_dependency 'savon'
  spec.add_runtime_dependency 'builder'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
