#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'time'
require 'fileutils'
require 'erb'

# Jekyll-AsciiDoc Log Parser
#
# Parses Jekyll verbose build logs to extract Asciidoctor warnings and errors.
# Associates each issue with the source file being processed.
#
# Usage:
#   bundle exec jekyll build --verbose > .agent/jekyll-build.log 2>&1
#   bundle exec rake 'labdev:lint:logs[jekyll-asciidoc,.agent/jekyll-build.log]'

module JekyllAsciiDocLogParser
  COLORS = {
    red: 31,
    yellow: 33,
    green: 32,
    blue: 34,
    cyan: 36
  }.freeze

  # Represents a single log issue
  class LogIssue
    attr_accessor :type, :kind, :file, :path, :with, :from, :line, :note, :code, :fix, :attr

    def initialize type:, kind:, file:, line:, note:, **options
      @type = type
      @kind = kind
      @file = file
      @line = line
      @note = note
      @attr = options[:attr]

      # Handle optional parameters
      reported_file_path = options[:reported_file_path]
      is_excerpt = options[:is_excerpt] || false
      @fix = nil

      process_context(reported_file_path, is_excerpt)
      process_error_specifics(reported_file_path, file, line)
    end

    def to_h
      hash = {
        'type' => @type,
        'kind' => @kind,
        'file' => @file,
        'line' => @line,
        'note' => @note,
        'fix?' => @fix
      }

      # Add optional fields only if they have values
      hash['path'] = @path if @path
      hash['with'] = @with if @with
      hash['from'] = @from if @from
      hash['code'] = @code if @code && !@code.empty?
      hash['attr'] = @attr if @attr

      hash
    end

    private

    def process_context reported_file_path, is_excerpt
      @from = '#excerpt' if reported_file_path == '#excerpt' || is_excerpt
    end

    def process_error_specifics reported_file_path, source_file, line_number
      if @kind == 'include_file_not_found'
        extract_missing_path
      else
        set_problem_file(reported_file_path, source_file)
        extract_code_line(line_number)
      end
    end

    def extract_missing_path
      return unless @note =~ /include file not found: (.+)$/

      missing_path = Regexp.last_match(1)

      # Try to convert absolute path back to relative path
      if missing_path =~ %r{/home/[^/]+/[^/]+/work/[^/]+/(.+)$} ||
         missing_path =~ %r{/([^/]+/[^/]+\.adoc)$}
        @path = Regexp.last_match(1)
      end
    end

    def set_problem_file reported_file_path, source_file
      problem_file = JekyllAsciiDocLogParser.normalize_problem_path(reported_file_path, source_file)
      @with = problem_file unless problem_file == source_file
    end

    def extract_code_line line_number
      return unless @with

      code_line = JekyllAsciiDocLogParser.get_code_line_from_problem_file(@with, line_number)
      @code = code_line if code_line && !code_line.empty?
    end
  end

  class << self
    def parse_log_file log_file, output_dir='.agent/reports'
      unless File.exist?(log_file)
        puts "❌ Log file not found: #{log_file}"
        return false
      end

      content = File.read(log_file)
      parse_log_content(content, output_dir, log_file)
    end

    def parse_log_content content, output_dir='.agent/reports', source_name='stdin'
      puts '📝 Parsing Jekyll AsciiDoctor log for warnings and errors...'

      FileUtils.mkdir_p(output_dir)

      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      output_file = "jekyll-asciidoc-issues-#{timestamp}.yml"
      output_path = File.join(output_dir, output_file)

      issues = parse_issues(content)

      if issues.empty?
        puts '✅ No AsciiDoctor issues found!'
        return true
      end

      generate_yaml_report(issues, output_path, source_name)

      severity = summarize_severity(issues)
      icon = severity[:has_error] ? '❌' : '⚠️'
      total_files = issues.length
      total_issues = count_total_issues(issues)
      files_text = colorize(total_files, :cyan)
      issues_color = severity[:has_error] ? :red : :yellow
      issues_text = colorize(total_issues, issues_color)

      puts "📄 Jekyll AsciiDoc issues report generated: #{output_path}"
      puts "#{icon} Found #{issues_text} #{pluralize(total_issues, 'total issue')} across #{files_text} " \
           "#{pluralize(total_files, 'source file')} to review"
      true
    end

    # Public helper methods accessible to LogIssue class

    def normalize_source_path source_file
      normalized = source_file.gsub(/#excerpt$/, '').gsub(%r{/$}, '')
      normalized.gsub(%r{^\./}, '')
    end

    def normalize_problem_path reported_path, source_file
      case reported_path
      when '#excerpt'
        # Special case: excerpt errors are in the source file itself
        source_file
      when %r{^/}
        # Absolute path; try to make relative to project root
        if reported_path.include?('/home/')
          # Extract the project-relative portion
          if reported_path =~ %r{/home/[^/]+/[^/]+/work/([^/]+)/(.+)$}
            project = Regexp.last_match(1)
            path = Regexp.last_match(2)
            "#{project}/#{path}"
          else # Fallback
            File.basename(reported_path)
          end
        else
          reported_path
        end
      when %r{^\.\./}
        # Resolve relative path from source file directory
        source_dir = File.dirname(source_file)
        resolved = File.expand_path(reported_path, source_dir)
        # Make it relative to project root
        resolved.gsub(%r{^/.*?/work/[^/]+/}, '')
      else
        # Already relative or simple filename
        reported_path
      end
    end

    def categorize_error_type message
      case message
      when /include file not found/
        'include_file_not_found'
      when /section title out of sequence/
        'section_title_out_of_sequence'
      when /unterminated listing block/
        'unterminated_listing_block'
      when /invalid reference/
        'invalid_reference'
      when /attribute '([^']+)' (?:is|not) defined/
        'missing_attribute'
      else
        'other'
      end
    end

    def get_code_line_from_problem_file problem_file, line_number
      return '' unless problem_file && line_number.positive?

      # Try various paths where the file might exist
      possible_paths = [
        problem_file,
        "./#{problem_file}",
        File.expand_path(problem_file)
      ]

      # Also try in common Jekyll source directories
      %w[_docs _blog _pages content].each do |dir|
        unless problem_file.start_with?(dir)
          possible_paths << "#{dir}/#{problem_file}"
          possible_paths << "#{dir}/#{File.basename(problem_file)}"
        end
      end

      possible_paths.each do |path|
        next unless File.exist?(path)

        begin
          lines = File.readlines(path)
          line_content = lines[line_number - 1]&.chomp
          return line_content if line_content && !line_content.empty?
        rescue StandardError => e
          puts "⚠️  Could not read line #{line_number} from #{path}: #{e.message}"
        end
      end

      '' # Return empty string if we can't find/read the file
    end

    private

    def parse_issues content
      lines = content.split("\n")
      issues = []
      current_source_file = nil

      lines.each do |line|
        line = line.strip

        # Track what file Jekyll is currently rendering (this is our source file)
        current_source_file = Regexp.last_match(1) if line =~ /Rendering Markup: (.+\.adoc.*)/

        # Extract asciidoctor warnings and errors with explicit file/line
        missing_attr = nil
        if line =~ /^asciidoctor: (WARNING|ERROR): (.+): line (\d+): (.+)$/
          issue_type = Regexp.last_match(1) == 'ERROR' ? 'ERROR' : 'warning'
          reported_file_path = Regexp.last_match(2) # Keep exactly as AsciiDoctor reports it
          line_number = Regexp.last_match(3).to_i
          message = Regexp.last_match(4)
        elsif line =~ /^asciidoctor: (WARNING|ERROR): skipping reference to missing attribute: (.+)$/
          issue_type = Regexp.last_match(1) == 'ERROR' ? 'ERROR' : 'warning'
          reported_file_path = current_source_file
          line_number = 0
          missing_attr = Regexp.last_match(2).strip
          message = "attribute '#{missing_attr}' not defined"
        else
          next
        end

        next unless current_source_file

        # Normalize the source file path (relative to project root)
        source_file = normalize_source_path(current_source_file)
        is_excerpt = current_source_file.include?('#excerpt')

        error_category = categorize_error_type(message)
        attr_name = nil
        if error_category == 'missing_attribute'
          if message =~ /attribute '([^']+)' (?:is|not) defined/
            attr_name = Regexp.last_match(1)
          elsif missing_attr
            attr_name = missing_attr
          end
        end

        # Create LogIssue object
        log_issue = LogIssue.new(
          type: issue_type,
          kind: error_category,
          file: source_file,
          line: line_number,
          note: message,
          attr: attr_name,
          reported_file_path: reported_file_path,
          is_excerpt: is_excerpt)

        issues << log_issue.to_h
      end

      # Group issues by source file for organized output
      issues.group_by { |issue| issue['file'] }.map do |file, file_issues|
        {
          'source_file' => file,
          'issues' => file_issues
        }
      end
    end

    def count_total_issues file_issues
      file_issues.sum { |file_data| file_data['issues'].length }
    end

    def generate_yaml_report file_issues, output_file, source_name
      template = ERB.new(yaml_template)
      yaml_content = template.result_with_hash(
        file_issues: file_issues,
        source_name: source_name,
        timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        total_files: file_issues.length,
        total_issues: count_total_issues(file_issues))

      # Post-process to remove unwanted blank lines
      cleaned_content = clean_yaml_whitespace(yaml_content)
      File.write(output_file, cleaned_content)
    end

    def clean_yaml_whitespace yaml_content
      lines = yaml_content.lines
      cleaned_lines = []

      lines.each_with_index do |line, index|
        if line.strip.empty?
          # Keep empty line only if the next line starts with # or -
          next_line = lines[index + 1]
          cleaned_lines << line if next_line && (next_line.strip.start_with?('#') || next_line.strip.start_with?('-'))
        else
          cleaned_lines << line
        end
      end

      cleaned_lines.join
    end

    def ai_prompt agent_prompt=nil
      return agent_prompt if agent_prompt

      template_path = File.join(TEMPLATES_DIR, 'jekyll-asciidoc-fix.prompt.yml')
      File.read(template_path) if File.exist?(template_path)
    end

    def yaml_template
      <<~TEMPLATE
        # Jekyll AsciiDoc Issues Report
        #
        # Generated: <%= timestamp %>
        # Source: <%= source_name %>
        # Files with issues: <%= total_files %>
        # Total issues: <%= total_issues %>
        #
        # User Instructions:
        # For each issue, enter a fix?: value of:
        # 'no' or 'skip' to ignore for now
        # 'fix' to mark for correction
        # 'fix("corrected text")' to specify exact correction
        # 'fix(include)' to fix missing include files
        # 'fix(leveloffset)' fix section level issues at the include
        # 'fix(sectionlevel)' fix section level issues in the included file
        # 'ignore' to add to permanent ignore list (not yet implemented)
        #
        # Data Structure:
        # - file: The Jekyll file being rendered (needs fixing)
        # - path: Missing include file path (for include_file_not_found only)
        # - with: The file containing the actual issue (when different from file)
        # - from: Context like "#excerpt" when relevant
        # - kind: Error type classification
        ##{' '}
        # After editing this file, use an AI agent to process the fixes.
        #
        ---
        <% file_issues.each do |file_data| %>
        # <%= file_data['source_file'] %>
        <% file_data['issues'].each do |issue| %>
        - type: <%= issue['type'] %>
          kind: <%= issue['kind'] %>
          file: <%= issue['file'] %>
        <% if issue['path'] %>
          path: <%= issue['path'] %>
        <% end %>
        <% if issue['with'] %>
          with: <%= issue['with'] %>
        <% end %>
        <% if issue['from'] %>
          from: "<%= issue['from'] %>"
        <% end %>
        <% if issue['line'] && issue['line'] > 0 %>
          line: <%= issue['line'] %>
        <% end %>
          note: "<%= issue['note'] %>"
        <% if issue['attr'] %>
          attr: <%= issue['attr'] %>
        <% end %>
        <% if issue['code'] && !issue['code'].empty? %>
          code: |
            <%= issue['code'] %>
        <% end %>
          fix?:#{' '}
        <% end %>

        <% end %>
        #
        # AI Agent Instructions:
        <%= ai_prompt %>
      TEMPLATE
    end

    def colorize value, color
      text = value.to_s
      return text unless $stdout.tty?

      code = COLORS[color]
      return text unless code

      "\e[#{code}m#{text}\e[0m"
    end

    def pluralize count, singular, plural=nil
      plural ||= "#{singular}s"
      count == 1 ? singular : plural
    end

    def summarize_severity file_issues
      has_error = false
      has_warning = false

      file_issues.each do |file_data|
        file_data['issues'].each do |issue|
          if issue['type'] == 'ERROR'
            has_error = true
          else
            has_warning = true
          end
        end
      end

      { has_error: has_error, has_warning: has_warning }
    end
  end
end

# CLI usage when run directly
if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    puts 'Usage: parse_jekyll_asciidoc_logs.rb <log_file> [output_dir]'
    puts '   or: cat log.txt | parse_jekyll_asciidoc_logs.rb'
    exit 1
  end

  if ARGV[0] == '-'
    # Read from stdin
    content = $stdin.read
    output_dir = ARGV[1] || '.agent/reports'
    JekyllAsciiDocLogParser.parse_log_content(content, output_dir, 'stdin')
  else
    log_file = ARGV[0]
    output_dir = ARGV[1] || '.agent/reports'
    JekyllAsciiDocLogParser.parse_log_file(log_file, output_dir)
  end
end
