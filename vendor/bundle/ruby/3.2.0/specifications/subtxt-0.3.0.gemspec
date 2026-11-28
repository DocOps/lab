# -*- encoding: utf-8 -*-
# stub: subtxt 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "subtxt".freeze
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Dominick".freeze]
  s.date = "2020-04-27"
  s.description = "A simple text conversion utility using regular expressions for searching and replacing multiple strings across multiple files, for conversion projects.".freeze
  s.email = ["badominick@gmail.com".freeze]
  s.executables = ["subtxt".freeze]
  s.files = ["bin/subtxt".freeze]
  s.homepage = "https://github.com/DocOps/subtxt".freeze
  s.rubygems_version = "3.4.19".freeze
  s.summary = "A simple utility for converting multiple strings across multiple files, for conversion projects.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.16"])
  s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
end
