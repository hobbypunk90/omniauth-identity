# -*- encoding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/omniauth-identity/version'

Gem::Specification.new do |gem|
  gem.add_runtime_dependency 'omniauth', '~> 1.9'
  gem.add_runtime_dependency 'bcrypt', '~> 3.1'

  gem.add_development_dependency 'maruku', '~> 0.6'
  gem.add_development_dependency 'simplecov', '~> 0.16'
  gem.add_development_dependency 'rack-test', '~> 1.1'
  gem.add_development_dependency 'rake', '~> 12.3'
  gem.add_development_dependency 'rspec', '~> 3.8'
  gem.add_development_dependency 'activerecord', '~> 5.1'
  gem.add_development_dependency 'mongoid'
  gem.add_development_dependency 'mongo_mapper'
  gem.add_development_dependency 'datamapper'
  gem.add_development_dependency 'bson_ext'
  gem.add_development_dependency 'couch_potato'

  gem.name = 'omniauth-identity'
  gem.version = OmniAuth::Identity::VERSION
  gem.description = %q{Internal authentication handlers for OmniAuth.}
  gem.summary = gem.description
  gem.email = ['michael@intridea.com']
  gem.homepage = 'http://github.com/intridea/omniauth-identity'
  gem.authors = ['Michael Bleigh']
  gem.license     = 'MIT'
  gem.executables = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ['lib']
  gem.required_rubygems_version = Gem::Requirement.new('>= 1.3.6') if gem.respond_to? :required_rubygems_version=
end
