# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baumwandler/version'

Gem::Specification.new do |spec|
  spec.name          = "baumwandler"
  spec.version       = Baumwandler::VERSION
  spec.authors       = ["Bernhard Weichel"]
  spec.email         = ["github.com@nospam.weichel21.de"]
  spec.description   = %q{Baumwandler - a german phrase which could be translated to
    tree walker - an approach to navigate within a tree
    tree transformer - an approch to convert one tree to another
  }
  spec.summary       = %q{Tree walking and morphing engine}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'wortsammler'
end
