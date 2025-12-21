# frozen_string_literal: true

require 'yaml'
require 'time'
require 'fileutils'

module DocOpsLab
  module Dev
    # SpellCheck functionality for parsing Vale logs and managing spelling corrections
    module SpellCheck
      def self.spelling_config_path
        File.join(GEM_ROOT, 'assets', 'config-packs', 'vale', 'authoring', 'Spelling.yml')
      end

      class << self
        def generate_spellcheck_report file_path=nil
          puts '📝 Generating spellcheck report from Vale output...'

          manifest = DocOpsLab::Dev.load_manifest
          spellcheck_config = manifest['spellcheck'] || {}
          output_dir = spellcheck_config['output_dir'] || '.agent/reports/'
          FileUtils.mkdir_p(output_dir)
          output_file = spellcheck_config['output_file'] || nil
          prompt = spellcheck_config['prompt'] || nil

          unless defined?(output_file) && output_file
            timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
            output_file = "spellcheck-#{timestamp}.yml"
          end

          output_path = File.join(output_dir, output_file)

          # Run Vale with JSON output and spelling filter
          # Pass just the rule name; filter builder will add .Name== wrapper
          # If file_path specified, only check that file
          vale_json = DocOpsLab::Dev.run_vale(
            file_path,
            '',
            output_format: :json,
            filter: 'DocOpsLab-Authoring.Spelling')
          return false if vale_json.nil?

          # Parse JSON output for spelling issues
          spelling_issues = parse_vale_json_output(vale_json)

          if spelling_issues.empty?
            puts '✅ No spelling issues found!'
            return true
          end

          # Generate YAML report
          generate_yaml_report(spelling_issues, output_path, prompt)

          puts "📄 SpellCheck report generated: #{output_path}"
          puts "Found #{spelling_issues.length} spelling issues to review"
          true
        end

        private

        def parse_vale_json_output json_output
          require 'json'

          issues = []
          seen_terms = {}

          begin
            vale_data = JSON.parse(json_output)
          rescue JSON::ParserError => e
            puts "❌ Failed to parse Vale JSON output: #{e.message}"
            return []
          end

          # Vale JSON structure: { "file_path" => [{ "Check" => "rule", "Message" => "message", "Line" => num, "Span" => [start, end], "Severity" => "level", "Match" => "word" }] }
          vale_data.each do |file_path, file_issues|
            file_issues.each do |issue|
              rule = issue['Check']
              issue['Message']
              line_num = issue['Line']
              span = issue['Span']
              misspelled_word = issue['Match']

              # Only process spelling issues (should be filtered already, but double-check)
              next unless rule&.include?('Spelling')

              # Skip if no misspelled word found
              next unless misspelled_word && !misspelled_word.empty?

              term = misspelled_word
              col = span ? span[0] : 1

              # Get context around the issue
              context_text = get_line_context(file_path, line_num, col, term)

              issue_entry = {
                'term' => term,
                'path' => file_path,
                'text' => context_text,
                'line' => "#{line_num},#{col}",
                'fix?' => nil
              }

              # Add 'all?' field only for the first occurrence of each term
              unless seen_terms[term]
                issue_entry['all?'] = nil
                seen_terms[term] = true
              end

              issues << issue_entry
            end
          end

          issues
        end

        def get_line_context file_path, line_num, _col, term
          return '' unless File.exist?(file_path)

          begin
            lines = File.readlines(file_path)
            target_line = lines[line_num - 1]
            return '' unless target_line

            # Get some words around the term for context
            # Find the term in the line and extract surrounding words
            words = target_line.split(/\s+/)
            term_index = words.find_index { |word| word.include?(term) }

            if term_index
              # Get 3 words before and after the term
              start_idx = [term_index - 3, 0].max
              end_idx = [term_index + 3, words.length - 1].min
              context_words = words[start_idx..end_idx]
              context_words.join(' ')
            else
              # Fallback: just return the line trimmed
              target_line.strip[0..80] + (target_line.length > 80 ? '...' : '')
            end
          rescue StandardError => e
            puts "⚠️  Could not read context from #{file_path}: #{e.message}"
            ''
          end
        end

        def generate_yaml_report errors, output_file, agent_prompt=nil
          require 'erb'

          unless agent_prompt
            template_path = File.join(TEMPLATES_DIR, 'spellcheck.prompt.yml')
            agent_prompt = File.read(template_path) if File.exist?(template_path)
          end

          # Create the YAML content with ERB templating for better formatting
          template = ERB.new(yaml_template)

          yaml_content = template.result_with_hash(errors: errors, agent_prompt: agent_prompt)

          File.write(output_file, yaml_content)
        end

        def yaml_template
          <<~TEMPLATE
            # SpellCheck Report
            #
            # User Instructions:
            # For each entry, enter a fix?: value of:
            # 'no' or 'n' to skip fixing for now (deleting the entry is more efficient)
            # 'add' or 'd' for add to dictionary
            # use add("[cC]orrected term") to indicate verbatim text to add
            # use docops("term") or nontech("term") to better organize additions
            # 'fix' if it's a typo to be corrected
            # 'fix("corrected")' where corrected is the intended text
            # 'pass' will wrap in <!-- vale off -->', '<!-- vale on -->'
            #
            # After editing this file, use an AI agent to process the fixes.
            #
            ---
            <% errors.each do |issue| %>
            - term: "<%= issue['term'] %>"
              path: <%= issue['path'] %>
              text: |
                <%= issue['text'] %>
              line: [<%= issue['line'] %>]
              fix?:#{' '}
            <% end %>
            #
            # AI Agent Instructions:
            <%= agent_prompt %>
          TEMPLATE
        end
      end
    end
  end
end
