#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'optparse'

# Validator for DocOps Lab projects YAML file
class ProjectsYAMLValidator
  attr_reader :file_path, :errors, :warnings

  def initialize(file_path)
    @file_path = file_path
    @errors = []
    @warnings = []
    @data = nil
  end

  def validate
    load_file
    return false unless @data

    check_duplicate_tags
    check_missing_icons
    check_rule_7b_violations
    check_duplicate_slugs
    check_done_values
    check_live_property

    report_results
    errors.empty?
  end

  private

  def load_file
    unless File.exist?(@file_path)
      @errors << "File not found: #{@file_path}"
      return
    end

    begin
      @data = YAML.unsafe_load_file(@file_path)
    rescue => e
      @errors << "Failed to parse YAML: #{e.message}"
    end
  end

  def check_duplicate_tags
    return unless @data && @data['projects']

    @data['projects'].each do |project|
      next unless project['tags']

      tags = project['tags']
      if tags.uniq.length != tags.length
        duplicates = tags.select { |t| tags.count(t) > 1 }.uniq
        @errors << "#{project['slug']}: duplicate tags #{duplicates.inspect}"
      end
    end
  end

  def check_missing_icons
    return unless @data && @data['projects']

    @data['projects'].each do |project|
      unless project['icon']
        @warnings << "#{project['slug']}: missing icon (recommended)"
      end
    end
  end

  def check_rule_7b_violations
    return unless @data && @data['projects'] && @data['$meta'] && @data['$meta']['types']

    type_slugs = @data['$meta']['types'].map { |t| t['slug'] }
    
    @data['projects'].each do |project|
      next unless project['tags'] && project['type']

      project_type = project['type']
      
      # Check if any tag matches the project's type
      if project['tags'].include?(project_type)
        @errors << "#{project['slug']}: tag '#{project_type}' duplicates project type (Rule 7B violation)"
      end

      # Check for related type violations (e.g., "plugin" tag when type is "jekyll-ext")
      case project_type
      when 'jekyll-ext'
        violations = project['tags'] & ['plugin', 'extension', 'jekyll-ext']
        violations.each do |tag|
          @errors << "#{project['slug']}: tag '#{tag}' should not be used for jekyll-ext type (Rule 7B)"
        end
      when 'jekyll-theme'
        if project['tags'].include?('theme')
          @errors << "#{project['slug']}: tag 'theme' duplicates project type (Rule 7B)"
        end
      when 'framework'
        if project['tags'].include?('framework')
          @errors << "#{project['slug']}: tag 'framework' duplicates project type (Rule 7B)"
        end
      end
    end
  end

  def check_duplicate_slugs
    return unless @data && @data['projects']

    slugs = {}
    @data['projects'].each do |project|
      slug = project['slug']
      if slugs[slug]
        @errors << "Duplicate slug '#{slug}' found in projects"
      else
        slugs[slug] = true
      end
    end
  end

  def check_done_values
    return unless @data && @data['projects']

    @data['projects'].each do |project|
      done = project['done']
      next unless done

      # Check format: should be percentage string
      unless done =~ /^\d+%$/ || done =~ /^[0-9.]+$/
        @errors << "#{project['slug']}: invalid done value '#{done}' (should be percentage like '70%' or '100%')"
      end

      # Warn about old 'live' value
      if done == 'live'
        @errors << "#{project['slug']}: done='live' is deprecated, use done='100%' and live:true"
      end
    end
  end

  def check_live_property
    return unless @data && @data['projects']

    @data['projects'].each do |project|
      next unless project['live']

      # Live should be boolean
      unless [true, false].include?(project['live'])
        @errors << "#{project['slug']}: live property should be boolean (true/false), got #{project['live'].inspect}"
      end

      # If live is true, project should have done value
      if project['live'] && !project['done']
        @warnings << "#{project['slug']}: live:true but no done value specified"
      end
    end
  end

  def report_results
    puts "\n" + "=" * 60
    puts "Validation Report: #{@file_path}"
    puts "=" * 60

    if @data && @data['projects']
      puts "Total projects: #{@data['projects'].length}"
    end

    if @errors.empty? && @warnings.empty?
      puts "\n✓ All validations passed!"
    else
      if @errors.any?
        puts "\n❌ ERRORS (#{@errors.length}):"
        @errors.each { |error| puts "  - #{error}" }
      end

      if @warnings.any?
        puts "\n⚠  WARNINGS (#{@warnings.length}):"
        @warnings.each { |warning| puts "  - #{warning}" }
      end
    end

    puts "=" * 60 + "\n"
  end
end

# CLI handling
if __FILE__ == $PROGRAM_NAME
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: validate-projects-yaml.rb [options] FILE"
    opts.on("-h", "--help", "Show this help message") do
      puts opts
      exit
    end
  end.parse!

  if ARGV.empty?
    puts "Error: No file path provided"
    puts "Usage: validate-projects-yaml.rb FILE"
    exit 1
  end

  file_path = ARGV[0]
  validator = ProjectsYAMLValidator.new(file_path)
  
  exit(validator.validate ? 0 : 1)
end
