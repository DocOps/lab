# -*- encoding: utf-8 -*-
# stub: asciisourcerer 0.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "asciisourcerer".freeze
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["DocOps Lab".freeze]
  s.date = "2026-04-02"
  s.description = "AsciiSourcerer provides APIs for specialized use of AsciiDoc (attribute extraction, special conversions), YAML (tag handling), and Liquid (Jekyll-based rendering, custom tags, etc).".freeze
  s.email = ["docopslab@protonmail.com".freeze]
  s.homepage = "https://github.com/DocOps/asciisourcerer".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "APIs for specialized handling of AsciiDoc, YAML, and Liquid documents.".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<asciidoctor>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<asciidoctor-html5s>.freeze, ["~> 0.5"])
  s.add_runtime_dependency(%q<jekyll>.freeze, ["~> 4.4"])
  s.add_runtime_dependency(%q<jekyll-asciidoc>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<kramdown-asciidoc>.freeze, ["~> 2.1"])
  s.add_runtime_dependency(%q<liquid>.freeze, ["~> 4.0"])
  s.add_runtime_dependency(%q<reverse_markdown>.freeze, ["~> 2.1"])
end
