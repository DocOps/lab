# scripts/rubocop_config_styles.rb
# !/usr/bin/env ruby
# frozen_string_literal: true

# Purpose:
#   Generate an AsciiDoc style guide that lists ONLY your customizations
#   relative to RuboCop defaults. For everything else, readers should use
#   the standard RuboCop docs.
#
# Output rules:
#   - No department sections. One section per customized cop:
#       == <Department>: <Pretty Cop Name>
#   - Within each section, print only the project's value (no defaults).
#   - Keys are prettified (CamelCase -> "Camel Case").
#   - Values stay inline unless an Array has > 1 items, which is printed
#     as a bulleted list.
#   - Includes AllCops diffs as a single "== All Cops" section.
#
# Usage:
#   bundle exec ruby scripts/rubocop_config_styles.rb [.config/rubocop.yml] > STYLE_GUIDE.adoc

require 'rubocop'
require 'json'

def load_default_config
  RuboCop::ConfigLoader.default_configuration
end

def load_effective_config path
  cfg = RuboCop::ConfigLoader.load_file(path)
  RuboCop::ConfigLoader.merge_with_default(cfg, path)
end

def known_cop_classes_by_name
  RuboCop::Cop::Registry.global.each_with_object({}) { |klass, h| h[klass.cop_name] = klass }
end

def docs_url cop_klass, config
  RuboCop::Cop::Documentation.url_for(cop_klass, config)
rescue StandardError
  nil
end

def diff_hash default_h, effective_h
  dk = default_h || {}
  ek = effective_h || {}
  keys = (dk.keys | ek.keys)
  keys.each_with_object({}) do |k, acc|
    dv = dk.key?(k) ? dk[k] : :__missing__
    ev = ek.key?(k) ? ek[k] : :__missing__
    acc[k] = ev unless dv == ev
  end
end

def pretty_camel str
  s = str.to_s.gsub('_', ' ')
  # split CamelCase but keep ALLCAPS groups intact
  s = s.gsub(/(?<=[a-z])(?=[A-Z])/, ' ')
  s.gsub(/\s+/, ' ').strip
end

def cop_title dept, cop_name
  # cop_name like "Layout/LineLength" -> "Layout: Line Length"
  d = dept.to_s
  c = cop_name.split('/').last
  "#{d}: #{pretty_camel(c)}"
end

def key_title key
  pretty_camel(key.to_s)
end

# rubocop:disable Lint/DuplicateBranch
def inline_value val
  case val
  when NilClass
    '`nil`'
  when TrueClass, FalseClass, Numeric
    "`#{val}`"
  when String, Symbol
    # show raw string/symbol without quotes
    "`#{val}`"
  when Array
    if val.length <= 1
      if val.empty?
        '`[]`'
      else
        item = val.first
        inline_value(item)
      end
    else
      :as_list # sentinel for list rendering
    end
  when Hash
    # compact JSON one-liner for readability
    "`#{JSON.generate(val)}'"
  else
    "`#{val.inspect}`"
  end
end
# rubocop:enable Lint/DuplicateBranch

def print_header config_path
  puts '= Project Ruby Style Guide (Customizations Only)'
  puts
  puts 'This document lists only deviations from the standard RuboCop defaults.'
  puts 'For everything else, consult:'
  puts 'link:https://docs.rubocop.org/rubocop/cops.html[RuboCop Style Guide (All Cops)]'
  puts
  puts "Generated from `#{config_path}` compared to built-in defaults."
  puts
end

def print_all_cops_section default_cfg, effective_cfg
  d = default_cfg['AllCops'] || {}
  e = effective_cfg['AllCops'] || {}
  diff = diff_hash(d, e)
  return if diff.empty?

  puts '[.dl-horizontal]'
  puts '== All Cops'
  puts
  diff.keys.sort.each do |key|
    val = diff[key]
    title = key_title(key)
    rendered = inline_value(val)
    if rendered == :as_list
      puts "#{title}::"
      val.each { |item| puts "* `#{item}`" }
    else
      puts "#{title}:: #{rendered}"
    end
    puts
  end
end

def department_of cop_class
  if cop_class.respond_to?(:department) && cop_class.department
    cop_class.department.to_s
  else
    cop_class.cop_name.split('/').first
  end
end

def generate config_path
  default_cfg   = load_default_config
  effective_cfg = load_effective_config(config_path)
  classes_by    = known_cop_classes_by_name

  print_header(config_path)
  print_all_cops_section(default_cfg, effective_cfg)

  # Consider all known cops; filter to those with diffs
  cop_names = (classes_by.keys | default_cfg.keys | effective_cfg.keys)
  cop_names.delete('AllCops')

  entries = []

  cop_names.each do |name|
    next unless classes_by.key?(name)

    klass = classes_by[name]

    d = begin
      default_cfg.for_cop(name)
    rescue StandardError
      {}
    end
    e = begin
      effective_cfg.for_cop(name)
    rescue StandardError
      {}
    end

    changes = diff_hash(d, e)
    next if changes.empty?

    dept = department_of(klass)
    url  = docs_url(klass, effective_cfg)

    entries << { dept: dept, name: name, url: url, changes: changes }
  end

  # Flatten: print each cop as its own "== <Dept>: <Pretty Name>" section
  entries.sort_by { |h| [h[:dept], h[:name]] }.each do |entry|
    puts '[.dl-horizontal]'
    puts "== #{cop_title(entry[:dept], entry[:name])}"
    puts
    puts "link:#{entry[:url]}[Cop documentation]" if entry[:url]
    puts
    entry[:changes].keys.sort.each do |key|
      val = entry[:changes][key]
      title = key_title(key)
      rendered = inline_value(val)
      if rendered == :as_list
        puts "#{title}::"
        val.each { |item| puts "* `#{item}`" }
      else
        puts "#{title}:: #{rendered}"
      end
      puts
    end
  end

  return unless entries.empty? && diff_hash(default_cfg['AllCops'] || {}, effective_cfg['AllCops'] || {}).empty?

  puts '_No customizations detected; project uses RuboCop defaults._'
end

config_path = ARGV[0] || '.rubocop.yml'
generate(config_path)
