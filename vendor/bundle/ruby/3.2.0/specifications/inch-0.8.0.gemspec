# -*- encoding: utf-8 -*-
# stub: inch 0.8.0 ruby lib

Gem::Specification.new do |s|
  s.name = "inch".freeze
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ren\u00E9 F\u00F6hring".freeze]
  s.date = "2018-04-10"
  s.description = "Documentation measurement tool for Ruby, based on YARD.".freeze
  s.email = ["rf@bamaru.de".freeze]
  s.executables = ["inch".freeze]
  s.files = ["bin/inch".freeze]
  s.homepage = "http://trivelop.de/inch/".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Documentation measurement tool for Ruby".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.2"])
  s.add_runtime_dependency(%q<pry>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<sparkr>.freeze, [">= 0.2.0"])
  s.add_runtime_dependency(%q<term-ansicolor>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<yard>.freeze, ["~> 0.9.12"])
end
