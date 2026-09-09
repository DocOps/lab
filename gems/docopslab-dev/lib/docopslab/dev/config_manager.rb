# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module DocOpsLab
  module Dev
    module ConfigManager
      class << self
        def generate_vale_config _context, style_override: nil
          base_config = File.join(Paths.config_vendor_dir, 'vale.ini')
          project_config = '.config/vale.local.ini'
          generated_config = Paths::CONFIG_FILES[:vale]

          return false unless File.exist?(base_config)

          merged_content = if File.exist?(project_config)
                             merge_ini_configs(base_config, project_config)
                           else
                             File.read(base_config)
                           end

          # Apply runtime style override if specified
          merged_content = apply_vale_style_override(merged_content, style_override) if style_override

          # Write generated config
          if !File.exist?(generated_config) || File.read(generated_config) != merged_content
            File.write(generated_config, merged_content)
            override_msg = style_override ? " (#{style_override} styles)" : ''
            puts "  📝 Generated #{generated_config} from base#{if File.exist?(project_config)
                                                                 ' + local'
                                                               end}#{override_msg}"
            true
          else
            false
          end
        end

        def generate_htmlproofer_config _context
          base_config = File.join(Paths.config_vendor_dir, 'htmlproofer.yml')
          project_config = '.config/htmlproofer.local.yml'
          generated_config = Paths::CONFIG_FILES[:htmlproofer]

          return false unless File.exist?(base_config)

          merged_content = if File.exist?(project_config)
                             merge_yaml_configs(base_config, project_config)
                           else
                             File.read(base_config)
                           end

          if !File.exist?(generated_config) || File.read(generated_config) != merged_content
            File.write(generated_config, merged_content)
            puts "  📝 Generated #{generated_config} from base#{' + local' if File.exist?(project_config)}"
            true
          else
            false
          end
        end

        def generate_git_lint_config _context
          default_config = load_git_lint_defaults
          return false unless default_config

          base_config = File.join(Paths.config_vendor_dir, 'git-lint.yml')
          project_config = '.config/git-lint.local.yml'
          generated_config = Paths::CONFIG_FILES[:git_lint]

          merged_content = default_config
          if File.exist?(base_config)
            merged_content = deep_merge_configs(merged_content, YAML.load_file(base_config) || {})
          end
          if File.exist?(project_config)
            merged_content = deep_merge_configs(merged_content, YAML.load_file(project_config) || {})
          end

          conventions = load_commit_conventions
          merged_content = apply_commit_conventions_to_git_lint(merged_content, conventions) if conventions

          rendered = YAML.dump(merged_content)
          FileUtils.mkdir_p(File.dirname(generated_config))

          if !File.exist?(generated_config) || File.read(generated_config) != rendered
            File.write(generated_config, rendered)
            puts "  📝 Generated #{generated_config} from git-lint defaults + DocOps Lab conventions"
            true
          else
            false
          end
        end

        def load_commit_conventions
          base_path = File.join(Paths.config_vendor_dir, 'commit-conventions.yml')
          local_path = '.config/commit-conventions.yml'

          if File.exist?(local_path)
            load_inheritable_yaml_config(local_path)
          elsif File.exist?(base_path)
            YAML.load_file(base_path) || {}
          end
        rescue StandardError => e
          warn "⚠️  Failed to load commit conventions: #{e.message}"
          nil
        end

        def load_htmlproofer_config config_path=nil, policy: 'merge'
          config_paths = if config_path && File.exist?(config_path)
                           [config_path]
                         else
                           [Paths::CONFIG_FILES[:htmlproofer]]
                         end
          config_paths << File.join(Paths.config_vendor_dir, 'htmlproofer.yml') unless policy == 'replace'
          config_path = config_paths.find { |path| File.exist?(path) }

          return unless config_path

          puts "📋 Using HTMLProofer config: #{config_path}"
          begin
            config = YAML.load_file(config_path)
            # Convert string patterns to regex for ignore_urls and ignore_files
            process_htmlproofer_patterns(config)
          rescue StandardError => e
            puts "⚠️  Failed to load #{config_path}: #{e.message}"
          end
        end

        def process_htmlproofer_patterns config
          # Convert string patterns to regex for ignore_urls
          if config['ignore_urls'].is_a?(Array)
            config['ignore_urls'] = config['ignore_urls'].map do |pattern|
              if pattern.is_a?(String) && pattern.start_with?('/') && pattern.end_with?('/')
                Regexp.new(pattern[1..-2])
              else
                pattern
              end
            end
          end

          # Convert string patterns to regex for ignore_files
          if config['ignore_files'].is_a?(Array)
            config['ignore_files'] = config['ignore_files'].map do |pattern|
              pattern.is_a?(String) ? Regexp.new(pattern) : pattern
            end
          end

          # Convert string keys to symbols for HTMLProofer
          config.transform_keys(&:to_sym)
        end

        def load_git_lint_defaults
          spec = Gem.loaded_specs['git-lint'] || Gem::Specification.find_all_by_name('git-lint').first
          unless spec
            warn "⚠️  git-lint is not installed. Run 'bundle install'."
            return nil
          end

          YAML.load_file(File.join(spec.full_gem_path, 'lib/git/lint/configuration/defaults.yml')) || {}
        rescue StandardError => e
          warn "⚠️  Failed to load git-lint defaults: #{e.message}"
          nil
        end

        def apply_commit_conventions_to_git_lint config, conventions
          types = convention_slugs(conventions, 'types')
          scopes = convention_slugs(conventions, 'scopes')
          separator = conventions.dig('rules', 'subject', 'allowed_scope_separator') || '+'
          max_length = conventions.dig('rules', 'subject', 'maximum')
          body_max = conventions.dig('rules', 'body', 'maximum_line_length')

          subject = config.dig('commits', 'subject')
          if subject && types.any?
            scope_pattern = git_lint_scope_pattern(scopes, separator)
            subject['prefix']['includes'] = types.sort.map { |type| "#{Regexp.escape(type)}#{scope_pattern}: " }
          end

          subject['length']['maximum'] = max_length if subject && max_length
          body = config.dig('commits', 'body')
          body['line_length']['maximum'] = body_max if body&.dig('line_length') && body_max

          config
        end

        def git_lint_scope_pattern scopes, separator
          return '(?:\\([a-z0-9_-]+\\))?' if scopes.empty?

          escaped_scopes = scopes.sort.map { |scope| Regexp.escape(scope) }
          escaped_separator = Regexp.escape(separator)
          "(?:\\((?:#{escaped_scopes.join('|')})(?:#{escaped_separator}(?:#{escaped_scopes.join('|')}))*\\))?"
        end

        def convention_slugs conventions, key
          values = conventions.dig('conventions', key)
          case values
          when Hash
            values.keys
          else
            Array(values).filter_map { |entry| entry['slug'] if entry.is_a?(Hash) }
          end
        end

        def load_inheritable_yaml_config path
          local = YAML.load_file(path) || {}
          inherit_from = local.delete('inherit_from')
          return local unless inherit_from

          base_path = File.expand_path(inherit_from, File.dirname(path))
          base = File.exist?(base_path) ? YAML.load_file(base_path) || {} : {}
          deep_merge_configs(base, local)
        end

        def merge_yaml_configs base_path, local_path
          # Implement RuboCop-style inheritance for YAML files
          require 'yaml'

          base_config = YAML.load_file(base_path) || {}
          project_config = YAML.load_file(local_path) || {}

          # Merge with RuboCop semantics
          merged_config = deep_merge_configs(base_config, project_config)

          # Convert back to YAML
          YAML.dump(merged_config)
        end

        def deep_merge_configs base, local
          return local if base.nil?
          return base if local.nil?

          case local
          when Hash
            result = base.is_a?(Hash) ? base.dup : {}
            local.each do |key, value|
              if value.nil? # YAML null (~) cancels the setting
                result.delete(key)
              else
                result[key] = deep_merge_configs(result[key], value)
              end
            end
            result
          else
            # Non-hash values: local completely overrides base (including arrays)
            local
          end
        end

        def generate_simple_ini config
          lines = []

          # Global section first
          if config['global'] && !config['global'].empty?
            config['global'].each do |key, value|
              lines << "#{key} = #{value}"
            end
            lines << ''
          end

          # Other sections
          config.each do |section_name, section_data|
            next if section_name == 'global'
            next if section_data.empty?

            lines << "[#{section_name}]"
            section_data.each do |key, value|
              lines << "#{key} = #{value}"
            end
            lines << ''
          end

          "#{lines.join("\n").strip}\n"
        end

        def get_path_config tool_slug, context
          tool_meta = context.get_tool_metadata(tool_slug)
          default_config = tool_meta&.dig('paths') || {}

          manifest = context.load_manifest
          project_config = manifest&.dig('tools')&.find { |t| t['tool'] == tool_slug }&.dig('paths') || {}

          git_tracked_only = if project_config.key?('git_tracked_only')
                               project_config['git_tracked_only']
                             else
                               default_config.fetch('git_tracked_only', true)
                             end

          # Project-level 'lint'/'skip' overrides gem-level 'patterns'/'ignored_paths'
          lint_paths = project_config['lint'] || default_config['patterns']
          skip_paths = (project_config['skip'] || []) + (default_config['ignored_paths'] || [])

          {
            lint: lint_paths,
            skip: skip_paths.uniq,
            exts: project_config['exts'] || default_config['exts'],
            git_tracked_only: git_tracked_only
          }
        end

        def merge_ini_configs base_path, local_path
          # Simple but working INI merger; good enough for our needs
          base_config = parse_simple_ini(File.read(base_path))
          project_config = parse_simple_ini(File.read(local_path))

          # Merge with RuboCop semantics: local overrides base, sections merge
          merged_config = deep_merge_configs(base_config, project_config)

          # Convert back to INI format
          generate_simple_ini(merged_config)
        end

        def parse_simple_ini content
          config = { 'global' => {} }
          current_section = 'global'

          content.lines.each do |line|
            line = line.strip
            next if line.empty? || line.start_with?('#')

            if line =~ /^\[(.+)\]$/
              current_section = ::Regexp.last_match(1)
              config[current_section] = {}
            elsif line =~ /^([^=]+)\s*=\s*(.*)$/
              key = ::Regexp.last_match(1).strip
              value = ::Regexp.last_match(2).strip
              config[current_section][key] = value
            end
          end

          config
        end

        def apply_vale_style_override content, override_type
          # Parse the INI content
          config = parse_simple_ini(content)

          # Apply the override to the [*.adoc] section
          if config['*.adoc']
            case override_type
            when :text
              config['*.adoc']['BasedOnStyles'] = 'RedHat, DocOpsLab-Authoring'
            when :adoc
              config['*.adoc']['BasedOnStyles'] = 'AsciiDoc, DocOpsLab-AsciiDoc'
            end
          end

          # Convert back to INI format
          generate_simple_ini(config)
        end
      end
    end
  end
end
