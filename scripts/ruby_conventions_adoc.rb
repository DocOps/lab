# frozen_string_literal: true

require 'yaml'
require 'liquid'

module RubyConventionsAdoc
  REQUIRED_GROUP_KEYS = %w[id title summary].freeze
  REQUIRED_RULE_KEYS = %w[id group title rule rationale enforcement examples migration].freeze
  REQUIRED_ENFORCEMENT_KEYS = %w[mechanism status].freeze
  REQUIRED_EXAMPLE_KEYS = %w[summary source code].freeze
  ENFORCEMENT_MECHANISMS = %w[rubocop custom-cop spec doc-only].freeze
  DEFAULT_TEMPLATE_PATH = File.expand_path('../_docs/partials/_ruby-conventions.asciidoc', __dir__).freeze

  module_function

  def load_definition path
    definition = YAML.safe_load_file(path, aliases: false)
    validate_definition!(definition)
    definition
  end

  def validate_definition! definition
    raise ArgumentError, 'Convention definition must be a mapping' unless definition.is_a?(Hash)

    groups = definition['groups']
    unless groups.is_a?(Array) && groups.any?
      raise ArgumentError, 'Convention definition must contain a non-empty groups list'
    end

    groups.each { |group| validate_required_values!(group, REQUIRED_GROUP_KEYS, 'Convention group') }
    group_ids = groups.map { |group| group.fetch('id') }
    duplicate_group_ids = duplicate_values(group_ids)
    raise ArgumentError, "Duplicate convention group ids: #{duplicate_group_ids.join(', ')}" if duplicate_group_ids.any?

    rules = definition['rules']
    unless rules.is_a?(Array) && rules.any?
      raise ArgumentError, 'Convention definition must contain a non-empty rules list'
    end

    rules.each { |rule| validate_required_values!(rule, REQUIRED_RULE_KEYS, 'Convention rule') }
    duplicate_ids = duplicate_values(rules.map { |rule| rule.fetch('id') })
    raise ArgumentError, "Duplicate convention ids: #{duplicate_ids.join(', ')}" if duplicate_ids.any?

    rules.each { |rule| validate_rule!(rule, group_ids) }
  end

  def validate_rule! rule, group_ids
    rule_id = rule.fetch('id')
    group_id = rule.fetch('group')
    raise ArgumentError, "#{rule_id}: unknown convention group #{group_id.inspect}" unless group_ids.include?(group_id)

    enforcement = rule.fetch('enforcement')
    validate_required_values!(enforcement, REQUIRED_ENFORCEMENT_KEYS, "#{rule_id} enforcement")
    mechanism = enforcement.fetch('mechanism')
    unless ENFORCEMENT_MECHANISMS.include?(mechanism)
      raise ArgumentError, "#{rule_id}: unsupported enforcement mechanism #{mechanism.inspect}"
    end

    examples = rule.fetch('examples')
    validate_required_values!(examples, %w[good bad], "#{rule_id} examples")
    %w[good bad].each do |kind|
      example = examples.fetch(kind)
      validate_required_values!(example, REQUIRED_EXAMPLE_KEYS, "#{rule_id} #{kind} example")
      validate_rubocop_cops!(example, rule_id, kind)
    end
  end

  def validate_required_values! mapping, keys, label
    raise ArgumentError, "#{label} must be a mapping" unless mapping.is_a?(Hash)

    missing = keys.reject { |key| mapping.key?(key) }
    raise ArgumentError, "#{label} is missing: #{missing.join(', ')}" if missing.any?

    blank = keys.select { |key| blank_value?(mapping[key]) }
    raise ArgumentError, "#{label} has blank values: #{blank.join(', ')}" if blank.any?
  end

  def validate_rubocop_cops! example, rule_id, kind
    cops = example['rubocop_cops']
    return unless cops
    return if cops.is_a?(Array) && cops.any? && cops.all? { |cop| cop.is_a?(String) && !blank_value?(cop) }

    raise ArgumentError, "#{rule_id} #{kind} example rubocop_cops must be a non-empty list of strings"
  end

  def duplicate_values values
    values.tally.select { |_value, count| count > 1 }.keys
  end

  def blank_value? value
    value.nil? || (value.respond_to?(:empty?) && value.empty?) || (value.is_a?(String) && value.strip.empty?)
  end

  def render definition, template_path: DEFAULT_TEMPLATE_PATH
    source = File.read(template_path)
    template = Liquid::Template.parse(source, error_mode: :strict)
    template.render!({ 'definition' => definition }, strict_filters: true)
  end
end

if $PROGRAM_NAME == __FILE__
  source = ARGV.fetch(0, 'gems/docopslab-dev/specs/data/ruby-conventions-def.yml')
  print RubyConventionsAdoc.render(RubyConventionsAdoc.load_definition(source))
end
