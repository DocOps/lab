# -*- encoding: utf-8 -*-
# stub: kramdown-asciidoc 2.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "kramdown-asciidoc".freeze
  s.version = "2.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/asciidoctor/kramdown-asciidoc/issues", "changelog_uri" => "https://github.com/asciidoctor/kramdown-asciidoc/blob/master/CHANGELOG.adoc", "mailing_list_uri" => "http://discuss.asciidoctor.org", "source_code_uri" => "https://github.com/asciidoctor/kramdown-asciidoc" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dan Allen".freeze]
  s.date = "2025-09-04"
  s.description = "A kramdown extension for converting Markdown documents to AsciiDoc.".freeze
  s.email = ["dan.j.allen@gmail.com".freeze]
  s.executables = ["kramdoc".freeze]
  s.files = ["bin/kramdoc".freeze]
  s.homepage = "https://github.com/asciidoctor/kramdown-asciidoc".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.19".freeze
  s.summary = "A Markdown to AsciiDoc converter based on kramdown".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<kramdown>.freeze, ["~> 2.4.0"])
  s.add_runtime_dependency(%q<kramdown-parser-gfm>.freeze, ["~> 1.1.0"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0.0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.11.0"])
end
