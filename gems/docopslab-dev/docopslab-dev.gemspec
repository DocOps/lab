# frozen_string_literal: true

require_relative 'lib/docopslab/dev/version'

Gem::Specification.new do |spec|
  spec.name = 'docopslab-dev'
  spec.version = DocOpsLab::Dev::VERSION
  spec.authors = ['DocOps Lab']
  spec.email = ['codewriting@protonmail.com']

  spec.summary = 'Internal development tooling for DocOps Lab projects'
  spec.description = 'Centralized configuration management, linting, and development ' \
                     'workflows for DocOps Lab repositories'
  spec.homepage = 'https://github.com/DocOps/lab'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/DocOps/lab/tree/main/gems/docopslab-dev'
  spec.metadata['changelog_uri'] = 'https://github.com/DocOps/lab/blob/main/gems/docopslab-dev/README.adoc'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('{lib,config-packs,hooks,docs,assets}/**/*') +
               %w[README.adoc LICENSE docopslab-dev.gemspec] +
               Dir.glob('specs/data/*')

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Core runtime dependencies
  spec.add_dependency 'asciidoctor', '~> 2.0'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'yaml', '~> 0.2'

  # Code quality and linting
  spec.add_dependency 'debride',        '~> 1.13'
  spec.add_dependency 'fasterer',       '~> 0.11'
  spec.add_dependency 'flog',           '~> 4.8'
  spec.add_dependency 'reek',           '~> 6.5'
  spec.add_dependency 'rubocop',        '~> 1.80'
  spec.add_dependency 'rubocop-rake',   '~> 0.7'
  spec.add_dependency 'rubocop-rspec',  '~> 3.7'
  spec.add_dependency 'subtxt',         '~> 0.3'

  # Security analysis
  spec.add_dependency 'brakeman',       '~> 7.1'
  spec.add_dependency 'bundler-audit',  '~> 0.9'

  # Testing and coverage
  spec.add_dependency 'html-proofer',   '~> 5.0'
  spec.add_dependency 'inch',           '~> 0.8'
  spec.add_dependency 'simplecov',      '~> 0.22'

  # Development dependencies should be in Gemfile, not gemspec
end
