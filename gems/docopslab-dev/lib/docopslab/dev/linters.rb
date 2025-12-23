# frozen_string_literal: true

require 'open3'

module DocOpsLab
  module Dev
    module Linters
      class << self
        def run_rubocop context, file_path=nil, opts_string=''
          context.generate_rubocop_config if context.respond_to?(:generate_rubocop_config)

          rubocop_config_file = CONFIG_PATHS[:rubocop]
          unless File.exist?(rubocop_config_file)
            rubocop_config_file = RUBOCOP_CONFIG_PATH # Fallback to vendor config
          end

          unless File.exist?(rubocop_config_file)
            puts "❌ No RuboCop config found. Run 'labdev:init' to create one."
            return false
          end

          puts "📄 Using config: #{rubocop_config_file}"

          path_config = context.get_path_config('rubocop')

          if path_config[:skip] && !path_config[:skip].empty?
            puts "⚠️  RuboCop does not support command-line exclusion. Use the 'Exclude' " \
                 "property in '.config/rubocop.yml' to ignore files or directories."
          end

          paths_to_check = if file_path
                             [file_path]
                           else
                             path_config[:lint]
                           end

          cmd = "bundle exec rubocop --config #{rubocop_config_file}"
          if paths_to_check.nil? || paths_to_check.empty?
            puts '📄 No paths configured to check for RuboCop, running on entire project.'
          else
            puts "👮 Running RuboCop on paths: #{paths_to_check.join(' ')}"
            cmd += " #{paths_to_check.join(' ')}"
          end

          # Append additional options if provided
          cmd += " #{opts_string}" unless opts_string.empty?

          success = system(cmd)

          if success
            puts '✅ RuboCop passed'
          else
            puts '❌ RuboCop found issues'
          end

          success
        end

        def run_rubocop_with_filter _context, filter_name
          rubocop_config_file = CONFIG_PATHS[:rubocop]
          unless File.exist?(rubocop_config_file)
            rubocop_config_file = RUBOCOP_CONFIG_PATH # Fallback to vendor config
          end

          unless File.exist?(rubocop_config_file)
            puts "❌ No RuboCop config found. Run 'labdev:init' to create one."
            return false
          end

          puts "📄 Using config: #{rubocop_config_file}"
          puts "🔍 Running RuboCop with filter: #{filter_name}"

          cmd = "bundle exec rubocop --config #{rubocop_config_file} --only #{filter_name}"
          success = system(cmd)

          if success
            puts '✅ RuboCop passed'
          else
            puts '❌ RuboCop found issues'
          end

          success
        end

        def run_shellcheck context, file_path=nil, opts_string=''
          scope = file_path ? :file : :project
          running_on = file_path || 'entire project'
          puts "🐚 Running ShellCheck on #{running_on}"

          shell_scripts = if scope == :file
                            File.exist?(file_path) ? [file_path] : []
                          else
                            context.find_shell_scripts
                          end

          if shell_scripts.empty?
            puts '📄 No shell scripts found to check'
            return true
          end

          puts "📄 Found #{shell_scripts.length} shell script(s) to check" if scope == :project
          success = true
          shell_scripts.each do |script|
            puts "🔍 Checking #{script}..."
            passed = true
            shebang_status = check_shebang(script)
            unless shebang_status
              puts "❌ Faulty shebang in #{script}; must be: #!/usr/bin/env bash"
              success = false
              passed = false
            end
            cmd = "shellcheck --severity=warning #{opts_string} --rcfile=.config/shellcheckrc #{script}".strip
            shellcheck = context.run_with_fallback('shellcheck', cmd)
            unless shellcheck
              success = false
              passed = false
              puts "❌ ShellCheck found issues in #{script}"
            end
            puts "✅ ShellCheck passed for #{script}" if passed
          end

          if success
            puts '✅ ShellCheck passed'
          else
            puts '❌ ShellCheck found issues'
          end
          success
        end

        def run_actionlint context, opts_string=''
          puts '⚙️  Running actionlint...'
          workflows_dir = '.github/workflows'
          unless Dir.exist?(workflows_dir)
            puts '📄 No GitHub Actions workflows found (.github/workflows/ not present)'
            return true
          end
          workflow_files = Dir.glob("#{workflows_dir}/**/*.{yml,yaml}")
          if workflow_files.empty?
            puts '📄 No workflow files found in .github/workflows/'
            return true
          end
          puts "📄 Found #{workflow_files.length} workflow file(s) to check"
          config_file = '.config/actionlint.yml'
          cmd = if File.exist?(config_file)
                  puts "📄 Using config: #{config_file}"
                  [
                    'actionlint',
                    '-config-file', config_file,
                    '-shellcheck=',  # Disable shellcheck integration (empty value)
                    opts_string,
                    *workflow_files
                  ].reject(&:empty?)
                else
                  [
                    'actionlint',
                    '-shellcheck=',  # Disable shellcheck integration (empty value)
                    opts_string,
                    *workflow_files
                  ].reject(&:empty?)
                end
          success = context.run_with_fallback('actionlint', cmd)
          if success
            puts '✅ actionlint passed'
          else
            puts '❌ actionlint found issues'
          end
          success
        end

        def run_vale context, file_path=nil, opts_string='', output_format: :cli, filter: nil, style_override: nil
          scope = file_path ? :file : :project
          running_on = file_path ? "file: #{file_path}" : scope.to_s

          override_label = case style_override
                           when :adoc then ' (AsciiDoc syntax)'
                           when :text then ' (prose/text)'
                           else ''
                           end

          puts "📝 Running Vale on #{running_on}#{override_label}"

          # Generate runtime config from base + local with optional style override
          puts '  ✅ Vale config up to date' unless context.generate_vale_config(style_override: style_override)

          # Use the generated config file
          config_file = CONFIG_PATHS[:vale]

          unless File.exist?(config_file)
            puts "❌ No Vale config found. Run 'labdev:sync:all' to generate one."
            return false
          end

          puts "📄 Using config: #{config_file}"

          # Check if Vale is available natively or via Docker
          unless context.tool_available?('vale')
            if context.docker_available?
              puts '⚠️  Vale not found natively, using Docker fallback'
            else
              puts '⚠️  Vale not found. Install options:'
              puts '   • macOS: brew install vale'
              puts '   • Linux: https://vale.sh/docs/vale-cli/installation/'
              puts '   • Docker: docker pull docopslab/dev'
              return false
            end
          end

          # Find AsciiDoc files to check, excluding vendor/ignored directories
          if scope == :file
            asciidoc_files = [file_path]
          else
            asciidoc_files = context.find_asciidoc_files
            if asciidoc_files.empty?
              puts '📄 No AsciiDoc files found to check'
              return true
            end
            puts "📄 Found #{asciidoc_files.length} AsciiDoc file(s) to check"
          end

          # Run Vale on specific files instead of scanning everything
          cmd = ['vale', '--config', config_file]

          # Add output format if not default CLI
          cmd << "--output=#{output_format.to_s.upcase}" unless output_format == :cli

          # Add filter if specified; Vale requires: --filter='.Name=="RuleName"'
          if filter
            # Accept either 'RuleName' or '.Name==RuleName' or '.Name=="RuleName"'
            # Vale filter syntax: .Name=="RuleName" (expr-lang syntax, needs double quotes)

            # Extract just the rule name, stripping any existing .Name== prefix and quotes
            filter_expr = if filter.start_with?('.Name==')
                            # Strip .Name== prefix and any surrounding quotes
                            filter.sub(/^\.Name==/, '').gsub(/^["']|["']$/, '')
                          else
                            # Just the rule name, remove any quotes if present
                            filter.gsub(/^["']|["']$/, '')
                          end

            # Pass as two separate args to avoid shell quoting issues
            cmd << '--filter'
            cmd << ".Name==\"#{filter_expr}\""
          end

          # Add additional options if provided
          cmd += opts_string.split unless opts_string.empty?

          # Add files to check
          cmd += asciidoc_files

          if output_format == :json
            # For JSON output, capture stdout
            # Use array form to preserve argument boundaries (esp. for --filter)
            stdout, stderr, status = Open3.capture3(*cmd)

            # Vale returns 1 for found issues, >1 for actual problems
            if status.exitstatus > 1
              puts "❌ Vale command failed: #{stderr}"
              return nil
            end

            stdout
          else
            # Standard execution for CLI output
            success = context.run_with_fallback('vale', cmd)

            if success
              puts '✅ Vale passed'
            else
              puts '❌ Vale found issues'
            end

            success
          end
        end

        def run_htmlproofer context
          require 'html-proofer'

          context.generate_htmlproofer_config

          config_options = context.load_htmlproofer_config
          return (puts '⚠️ No HTMLProofer config found; skipping') && true unless config_options.is_a?(Hash)

          path_config = context.get_path_config('htmlproofer')
          lint_path = path_config[:lint]
          site_dir = lint_path.is_a?(Array) ? lint_path.first : lint_path

          # Fallback to old check_directory for backward compatibility
          site_dir ||= config_options.delete(:check_directory)

          unless site_dir
            msg = '⚠️ No directory to check for HTMLProofer specified in manifest or config file; skipping'
            return (puts msg) && true
          end

          unless Dir.exist?(site_dir)
            return (puts "⚠️ Directory '#{site_dir}' does not exist; skipping HTMLProofer") && true
          end

          puts "📂 Checking #{site_dir} directory..."

          # Add ignored files from path config
          ignore_files = path_config[:skip] || []
          if ignore_files.any?
            config_options[:ignore_files] ||= []
            config_options[:ignore_files].concat(ignore_files.map { |p| /#{p}/ })
          end

          puts "🐛 [DEBUG] Final config_options: #{config_options.inspect}" if ENV['LABDEV_DEBUG'] == 'true'

          begin
            HTMLProofer.check_directory(site_dir, config_options).run
            puts '✅ HTMLProofer passed'
            true
          rescue StandardError => e
            puts "❌ HTMLProofer failed: #{e.message}"
            false
          end
        end

        def run_auto_fix context
          puts '🔧 Auto-fixing safe linting issues...'

          success = true

          # Auto-fix RuboCop issues
          success &= run_rubocop_auto_fix(context)

          if success
            puts '✅ Auto-fix complete'
          else
            puts '❌ Some auto-fixes failed'
          end

          success
        end

        def run_all_linters context
          puts '🧹 Running all linters...'

          results = {}

          results[:rubocop] = run_rubocop(context)
          results[:vale] = run_vale(context)
          results[:shellcheck] = run_shellcheck(context)
          results[:actionlint] = run_actionlint(context)
          results[:htmlproofer] = run_htmlproofer(context)

          # Summary
          passed = results.values.count(true)
          total = results.size

          if passed == total
            puts '✅ All linting complete'
          else
            puts "⚠️  #{passed}/#{total} linters passed"
            results.each do |linter, result|
              status = result ? '✅' : '❌'
              puts "   #{status} #{linter}"
            end
          end

          results.values.all?
        end

        def run_rubocop_auto_fix _context, path: nil
          puts '👮 Running RuboCop auto-correction...'

          unless File.exist?(RUBOCOP_CONFIG_PATH)
            puts "❌ No RuboCop config found. Run 'labdev:init' to create one."
            return false
          end

          puts "📄 Using config: #{RUBOCOP_CONFIG_PATH}"

          # Build command with optional path
          cmd = "bundle exec rubocop --config #{RUBOCOP_CONFIG_PATH} --autocorrect-all"
          if path
            cmd += " #{path}"
            puts "📄 Targeting path: #{path}"
          end
          puts "🔧 Running: #{cmd}"

          success = system(cmd)

          if success
            puts '✅ RuboCop auto-correction completed'
          else
            puts '❌ RuboCop auto-correction encountered issues'
          end

          success
        end

        def run_linter_group context, group_name, linters
          puts "Running #{group_name} linting..."

          results = {}
          linters.each do |linter|
            method_name = "run_#{linter}"
            if respond_to?(method_name, true)
              results[linter.to_sym] = send(method_name, context)
            else
              puts "⚠️  Unknown linter: #{linter}"
              results[linter.to_sym] = false
            end
          end

          passed = results.values.count(true)
          total = results.size

          if passed == total
            puts "✅ #{group_name} linting complete"
          else
            puts "❌ #{passed}/#{total} #{group_name} linters passed"
          end

          results.values.all?
        end

        def lint_file context, file_path
          ext = File.extname(file_path).downcase
          case ext
          when '.adoc', '.asciidoc', '.asc'
            run_vale(context, file_path)
          when '.rb', '.gemspec', ''
            run_rubocop(context, file_path)
          when '.sh'
            run_shellcheck(context, file_path)
          else
            puts "⚠️  No linter configured for file type: #{ext}"
            false
          end
        end

        def check_shebang file_path
          return false unless File.exist?(file_path)

          first_line = File.open(file_path, &:readline).strip
          first_line == '#!/usr/bin/env bash'
        rescue EOFError
          false
        rescue StandardError => e
          puts "⚠️  Error checking shebang for #{file_path}: #{e.message}"
          false
        end
      end
    end
  end
end
