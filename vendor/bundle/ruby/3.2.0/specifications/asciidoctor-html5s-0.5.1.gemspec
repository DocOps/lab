# -*- encoding: utf-8 -*-
# stub: asciidoctor-html5s 0.5.1 ruby lib

Gem::Specification.new do |s|
  s.name = "asciidoctor-html5s".freeze
  s.version = "0.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jakub Jirutka".freeze]
  s.date = "2021-07-21"
  s.description = "Semantic HTML5 backend (converter) for Asciidoctor\n\nThis converter focuses on correct semantics, accessibility and compatibility\nwith common typographic CSS styles.\n".freeze
  s.email = "jakub@jirutka.cz".freeze
  s.homepage = "https://github.com/jirutka/asciidoctor-html5s".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Semantic HTML5 backend (converter) for Asciidoctor".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<asciidoctor>.freeze, [">= 1.5.7", "< 3.0"])
  s.add_runtime_dependency(%q<thread_safe>.freeze, ["~> 0.3.4"])
  s.add_development_dependency(%q<asciidoctor-doctest>.freeze, ["= 2.0.0.beta.7"])
  s.add_development_dependency(%q<asciidoctor-templates-compiler>.freeze, ["~> 0.6.0"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.6"])
  s.add_development_dependency(%q<pandoc-ruby>.freeze, ["~> 2.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<slim>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<slim-htag>.freeze, ["~> 0.1.0"])
end
