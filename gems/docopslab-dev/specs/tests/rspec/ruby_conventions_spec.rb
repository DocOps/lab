# frozen_string_literal: true

require 'rspec'
require 'rubocop'
require 'yaml'
require_relative 'spec_helper'
require File.expand_path('../../scripts/ruby_conventions_adoc', GEM_ROOT_TEST)

RUBY_CONVENTIONS_PATH = File.join(GEM_ROOT_TEST, 'specs/data/ruby-conventions-def.yml').freeze
BASE_RUBOCOP_CONFIG_PATH = File.join(GEM_ROOT_TEST, 'assets/config-packs/rubocop/base.yml').freeze

def singleton_module_assignments
  assignments = Dir.glob(File.join(GEM_ROOT_TEST, 'lib/**/*.rb')).flat_map do |path|
    source = RuboCop::ProcessedSource.from_file(path, RUBY_VERSION.to_f)
    next [] unless source.ast

    source.ast.each_descendant(:ivasgn).filter_map do |assignment|
      ancestors = assignment.each_ancestor.to_a
      container_index = ancestors.index { |node| %i[class module].include?(node.type) }
      next unless container_index

      container = ancestors.fetch(container_index)
      local_ancestors = ancestors.take(container_index)
      singleton_context = local_ancestors.none? { |node| node.type == :def } ||
                          local_ancestors.any? { |node| %i[defs sclass].include?(node.type) }
      next unless container.module_type? && singleton_context

      {
        'path' => path.delete_prefix("#{GEM_ROOT_TEST}/"),
        'variable' => assignment.children.first.to_s
      }
    end
  end
  assignments.uniq.sort_by { |entry| [entry.fetch('path'), entry.fetch('variable')] }
end

def rubocop_offenses code, cop_names
  loaded_config = RuboCop::ConfigLoader.load_file(BASE_RUBOCOP_CONFIG_PATH)
  config = RuboCop::ConfigLoader.merge_with_default(loaded_config, BASE_RUBOCOP_CONFIG_PATH)
  cops = cop_names.map do |cop_name|
    cop_class = RuboCop::Cop::Registry.global.find_by_cop_name(cop_name)
    raise ArgumentError, "Unknown RuboCop cop: #{cop_name}" unless cop_class

    cop_class.new(config, nil)
  end
  source = RuboCop::ProcessedSource.new(code, config.target_ruby_version)
  RuboCop::Cop::Commissioner.new(cops, [], raise_error: true).investigate(source).offenses
end

RSpec.describe RubyConventionsAdoc do
  let(:definition) { described_class.load_definition(RUBY_CONVENTIONS_PATH) }

  it 'renders every rule into the AsciiDoc partial' do
    rendered = described_class.render(definition)

    definition.fetch('rules').each do |rule|
      expect(rendered).to include("[[ruby-convention-#{rule.fetch('id')}]]")
      expect(rendered).to include(rule.fetch('rule'))
    end
  end

  it 'keeps generated AsciiDoc structure in a Liquid template' do
    template = File.read(described_class::DEFAULT_TEMPLATE_PATH)

    expect(template).to include('{% for group in definition.groups %}')
    expect(template).to include('[[ruby-convention-{{ rule.id }}]]')
  end

  it 'documents a good and bad example for every rule' do
    definition.fetch('rules').each do |rule|
      expect(rule.dig('examples', 'good', 'code')).not_to be_empty
      expect(rule.dig('examples', 'bad', 'code')).not_to be_empty
    end
  end

  it 'passes the declared RuboCop checks for marked good examples' do
    definition.fetch('rules').each do |rule|
      example = rule.dig('examples', 'good')
      cops = example['rubocop_cops']
      next unless cops

      failure_message = "#{rule.fetch('id')} good example failed #{cops.join(', ')}"
      expect(rubocop_offenses(example.fetch('code'), cops)).to be_empty, failure_message
    end
  end

  it 'rejects malformed nested convention records' do
    malformed = Marshal.load(Marshal.dump(definition))
    malformed.fetch('rules').first.fetch('examples').fetch('good').delete('source')

    expect { described_class.validate_definition!(malformed) }
      .to raise_error(ArgumentError, /good example is missing: source/)
  end

  it 'rejects non-string RuboCop example checks' do
    malformed = Marshal.load(Marshal.dump(definition))
    malformed.fetch('rules').first.fetch('examples').fetch('good')['rubocop_cops'] = [123]

    expect { described_class.validate_definition!(malformed) }
      .to raise_error(ArgumentError, /rubocop_cops must be a non-empty list of strings/)
  end

  it 'allows enforcement details to be omitted' do
    without_details = Marshal.load(Marshal.dump(definition))
    rule = without_details.fetch('rules').first
    rule.fetch('enforcement').delete('details')

    expect { described_class.validate_definition!(without_details) }.not_to raise_error
    section = described_class.render(without_details).split('[[ruby-convention-visible-module-state]]').first
    expect(section).not_to include("\n+\n")
  end

  it 'rejects unlisted mutable singleton-module state' do
    rule = definition.fetch('rules').find { |entry| entry.fetch('id') == 'visible-module-state' }
    allowlist = rule.dig('enforcement', 'allow').map { |entry| entry.slice('path', 'variable') }
                    .sort_by { |entry| [entry.fetch('path'), entry.fetch('variable')] }

    expect(singleton_module_assignments).to eq(allowlist)
  end
end
