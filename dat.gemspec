# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dat/version'

Gem::Specification.new do |spec|
  spec.name          = "dat"
  spec.version       = Dat::VERSION
  spec.authors       = ["Matt Zumwalt"]
  spec.email         = ["matt@databindery.com"]

  spec.summary       = %q{Ruby wrapper for the dat command line API}
  spec.description   = %q{gives you object oriented read/write access to dat repositories (http://dat-data.com) via Ruby}
  spec.homepage      = "http://github.com/databindery/dat-data"
  spec.license       = "Apache2"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency('activesupport', '>=3.0')

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "byebug"

end
