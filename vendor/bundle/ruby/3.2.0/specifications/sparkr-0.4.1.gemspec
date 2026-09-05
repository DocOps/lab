# -*- encoding: utf-8 -*-
# stub: sparkr 0.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "sparkr".freeze
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ren\u00E9 F\u00F6hring".freeze]
  s.date = "2014-02-04"
  s.description = "ASCII Sparklines in Ruby".freeze
  s.email = ["rf@bamaru.de".freeze]
  s.executables = ["sparkr".freeze]
  s.files = ["bin/sparkr".freeze]
  s.homepage = "http://trivelop.de/sparkr/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "[\"ASCII\", \"Sparklines\", \"in\", \"Ruby\"]".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
