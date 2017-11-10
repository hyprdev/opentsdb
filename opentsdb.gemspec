# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opentsdb/version'

Gem::Specification.new do |spec|
  spec.name          = 'opentsdb'
  spec.version       = Opentsdb::VERSION
  spec.authors       = %w(aleksandr)
  spec.email         = ['aleksandr@hyper-dev.ru']

  spec.summary       = 'Ruby client for OpenTSDB HTTP Query API.'
  spec.description   = 'A ruby client library for working with OpenTSDB using HTTP API.'
  spec.homepage      = ''

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.licenses      = ''

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'faraday', '~> 0.10'
  spec.add_dependency 'httpclient', '~> 2.8'
  spec.add_dependency 'activesupport'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
