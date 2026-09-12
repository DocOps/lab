# -*- encoding: utf-8 -*-
# stub: dry-monads 1.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-monads".freeze
  s.version = "1.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/dry-rb/dry-monads/issues", "changelog_uri" => "https://github.com/dry-rb/dry-monads/blob/main/CHANGELOG.md", "funding_uri" => "https://github.com/sponsors/hanami", "source_code_uri" => "https://github.com/dry-rb/dry-monads" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hanakai team".freeze]
  s.bindir = "exe".freeze
  s.date = "1980-01-02"
  s.description = "Common monads for Ruby".freeze
  s.email = ["info@hanakai.org".freeze]
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "LICENSE".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-monads".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "Common monads for Ruby".freeze

  s.installed_by_version = "3.4.19" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 1.1"])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6"])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<debug_inspector>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
end
