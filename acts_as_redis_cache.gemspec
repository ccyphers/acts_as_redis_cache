# -*- encoding: utf-8 -*-

require './lib/version'

Gem::Specification.new do |s|
  s.name = %q{acts_as_redis_cache}
  s.version = VERSION
  s.authors = [""]
  s.email = %q{}
  s.license = ""
  s.extra_rdoc_files = [ ]
  s.files = Dir["**/*"] - Dir["*.gem"] - ["Gemfile.lock"]
  s.homepage = %q{}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  #s.rubyforge_project = %q{}
  #s.rubygems_version = %q{1.3.7}
  s.summary = %q{}
  s.add_dependency "redis", ">= 3.1"
end

