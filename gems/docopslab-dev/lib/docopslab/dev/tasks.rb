# frozen_string_literal: true

require 'rake/tasklib'
require 'yaml'

module DocOpsLab
  module Dev
    # Rake task definitions for DocOps Lab development tools
    # Task structure defined in specs/data/tasks-def.yml
    class Tasks < Rake::TaskLib
      def initialize
        super
        load_task_definitions
        define_tasks
      end

      private

      attr_reader :task_defs

      def load_task_definitions
        tasks_def_path = File.join(__dir__, '../../../specs/data/tasks-def.yml')
        @task_defs = YAML.load_file(tasks_def_path)
      end

      # Look up task description from tasks-def.yml
      # Path format: 'check:env' looks up labdev.check.env._desc
      def desc_for task_path
        parts = task_path.split(':')
        node = task_defs.dig('labdev', *parts)
        return nil unless node.is_a?(Hash)

        node['_desc']
      end

      def define_tasks
        namespace :labdev do
          # ============================================================
          # CHECK tasks; Assess local repo and environment
          # ============================================================

          # Base task; show help for 'check' namespace
          task :check do
            Help.show_task_help('check')
          end

          namespace :check do
            desc desc_for('check:env')
            task :env do
              puts '🩺 DocOps Lab Environment Diagnostics'
              Dev.check_ruby_version
              puts "Gem version: #{VERSION}"
              Dev.check_config_structure
              Dev.check_standard_rake_tasks
            end

            desc desc_for('check:updates')
            task :updates do
              Dev.check_hook_updates
            end

            desc desc_for('check:all')
            task :all do
              Rake::Task['labdev:check:env'].invoke
              Rake::Task['labdev:check:updates'].invoke
            end
          end

          # ============================================================
          # INIT tasks; Bootstrap development environment
          # ============================================================

          desc desc_for('init')
          task :init do
            Help.show_task_help('init')
          end

          namespace :init do
            desc desc_for('init:all')
            task :all do
              Dev.bootstrap_project
            end

            desc desc_for('init:docs')
            task :docs do
              if Dev.sync_docs
                puts '✅ Agent docs synced'
              else
                puts '⚠️  Agent docs sync skipped or failed'
              end
            end
          end

          # ============================================================
          # RUN tasks; Execute tools with custom arguments
          # ============================================================

          namespace :run do
            desc desc_for('run:script')
            task :script, %i[script opts] => [] do |_t, args|
              script = args[:script]
              if script.nil?
                puts '❌ Script name is required.'
                puts 'Usage: bundle exec rake labdev:run:script[script]'
                puts 'Use labdev:show:scripts to see available scripts.'
                return
              end

              # Parse opts_string if provided
              extra_args = args[:opts] ? args[:opts].split : []
              Dev.run_script(script, extra_args)
            end

            desc desc_for('run:rubocop')
            task :rubocop, [:opts] => [] do |_t, args|
              opts = args[:opts] || ''
              # Strip quotes that Rake includes when arguments contain spaces
              opts = opts.gsub(/^["']|["']$/, '') if opts.include?(' ')
              success = Dev.run_rubocop(nil, opts)
              exit(1) unless success
            end

            desc desc_for('run:vale')
            task :vale, [:opts] => [] do |_t, args|
              opts = args[:opts] || ''
              Dev.run_vale(nil, opts)
            end

            # Removed from 0.1.0 for incongruent options between CLI and API
            # desc desc_for('run:htmlproofer')
            # task :htmlproofer, [:opts] => [] do |_t, args|
            #   opts = args[:opts] || ''
            #   puts '🔗 Running HTMLProofer...'
            #   Dev.run_htmlproofer(opts)
            # end

            desc desc_for('run:shellcheck')
            task :shellcheck, [:opts] => [] do |_t, args|
              opts = args[:opts] || ''
              Dev.run_shellcheck(nil, opts)
            end

            desc desc_for('run:actionlint')
            task :actionlint, [:opts] => [] do |_t, args|
              opts = args[:opts] || ''
              Dev.run_actionlint(opts)
            end
          end

          # ============================================================
          # SYNC tasks; Sync managed files from upstream
          # ============================================================

          namespace :sync do
            desc desc_for('sync:configs')
            task :configs do
              Dev.sync_config_files
            end

            desc desc_for('sync:scripts')
            task :scripts do
              Dev.sync_scripts
            end

            desc desc_for('sync:docs')
            task :docs do
              Dev.sync_docs(force: true)
            end

            namespace :styles do
              desc desc_for('sync:styles:local')
              task :local do
                Dev.sync_vale_styles(local: true)
              end

              desc desc_for('sync:styles:all')
              task :all do
                Dev.sync_vale_styles
              end
            end

            # Base task; show help for 'sync:styles' namespace
            task :styles do
              Help.show_task_help('sync:styles')
            end

            desc desc_for('sync:hooks')
            task :hooks do
              Dev.update_hooks_interactive
            end

            namespace :vale do
              desc desc_for('sync:vale:local')
              task :local do
                Dev.sync_config_files(:vale)
                Dev.sync_vale_styles(local: true)
              end

              desc desc_for('sync:vale:all')
              task :all do
                Dev.sync_config_files(:vale)
                Dev.sync_vale_styles
              end
            end

            # Base task; show help for 'sync:vale' namespace
            task :vale do
              Help.show_task_help('sync:vale')
            end

            desc desc_for('sync:all')
            task :all do
              Dev.sync_config_files
              Dev.sync_scripts
              Dev.sync_docs
              Dev.install_missing_hooks
              Dev.sync_vale_styles
            end
          end

          # Base task; show help for 'sync' namespace
          task :sync do
            Help.show_task_help('sync')
          end

          # ============================================================
          # LINT tasks; Run linters
          # ============================================================

          namespace :lint do
            desc desc_for('lint:ruby')
            task :ruby, %i[path rule opts] => [] do |_t, args|
              path = args[:path]
              rule = args[:rule]
              opts = args[:opts]

              if path || rule || opts
                # Specific file/rule mode
                cmd_opts = []
                cmd_opts << "--only #{rule}" if rule
                cmd_opts << opts if opts
                target = path || nil
                Dev.run_rubocop(target, cmd_opts.join(' '))
              else
                # Default: run on all Ruby files
                Dev.run_linter_group('Ruby', %w[rubocop])
              end
            end

            desc desc_for('lint:bash')
            task :bash, %i[path rule opts] => [] do |_t, args|
              path = args[:path]
              opts = args[:opts]

              if path || opts
                target = path || nil
                Dev.run_shellcheck(target, opts || '')
              else
                Dev.run_linter_group('shell script', %w[shellcheck])
              end
            end

            desc desc_for('lint:docs')
            task :docs, %i[path rule opts] => [] do |_t, args|
              path = args[:path]
              rule = args[:rule]
              opts = args[:opts]

              if path || rule || opts
                filter = rule ? ".Name==#{rule}" : nil
                target = path || nil
                Dev.run_vale(target, opts || '', filter: filter)
              else
                Dev.run_linter_group('AsciiDoc', %w[vale])
              end
            end

            desc desc_for('lint:html')
            task :html do
              Dev.run_linter_group('HTML', %w[htmlproofer])
            end

            desc desc_for('lint:adoc')
            task :adoc, %i[path rule opts] => [] do |_t, args|
              path = args[:path]
              rule = args[:rule]
              opts = args[:opts]

              if path || rule || opts
                filter = rule ? ".Name==#{rule}" : nil
                target = path || nil
                Dev.run_vale(target, opts || '', filter: filter, style_override: :adoc)
              else
                Dev.run_vale(style_override: :adoc)
              end
            end

            # Alias: labdev:lint:asciidoc -> labdev:lint:adoc
            task asciidoc: 'adoc'

            desc desc_for('lint:text')
            task :text, %i[path rule opts] => [] do |_t, args|
              path = args[:path]
              rule = args[:rule]
              opts = args[:opts]

              if path || rule || opts
                filter = rule ? ".Name==#{rule}" : nil
                target = path || nil
                Dev.run_vale(target, opts || '', filter: filter, style_override: :text)
              else
                Dev.run_vale(style_override: :text)
              end
            end

            desc desc_for('lint:workflows')
            task :workflows, %i[path opts] => [] do |_t, args|
              # path = args[:path]  # TODO: path not yet supported by run_actionlint
              opts = args[:opts]

              if opts
                Dev.run_actionlint(opts)
              else
                Dev.run_linter_group('GitHub Actions', %w[actionlint])
              end
            end

            desc desc_for('lint:spellcheck')
            task :spellcheck, %i[path opts] => [] do |_t, args|
              path = args[:path]
              SpellCheck.generate_spellcheck_report(path)
            end

            desc desc_for('lint:logs')
            task :logs, %i[type path outdir] => [] do |_t, args|
              log_type = args[:type]
              log_file = args[:path]
              output_dir = args[:outdir]

              unless log_type && log_file
                puts 'Usage: bundle exec rake labdev:lint:logs[type,path]'
                puts 'Example: bundle exec rake labdev:lint:logs[jekyll-asciidoc,.agent/build.log]'
                puts 'Supported log types: jekyll-asciidoc'
                next
              end

              case log_type.to_s.downcase
              when 'jekyll-asciidoc', 'jekyll_asciidoc', 'jekyll'
                LogParser.parse_jekyll_asciidoc_log(log_file, output_dir)
              else
                puts "❌ Unknown log type: #{log_type}"
                puts 'Supported types: jekyll-asciidoc'
                false
              end
            end

            desc desc_for('lint:all')
            task :all do
              Dev.run_all_linters
            end
          end

          # Base task; show help for 'lint' namespace
          task :lint do
            Help.show_task_help('lint')
          end

          # ============================================================
          # HEAL tasks; Auto-fix issues
          # ============================================================

          namespace :heal do
            desc desc_for('heal:ruby')
            task :ruby, [:path] => [] do |_t, args|
              Dev.run_rubocop_auto_fix(path: args[:path])
            end

            desc desc_for('heal:adoc')
            # Add an optional path argument that defaults to nil
            task :adoc, %i[path] => [] do |_t, args|
              Dev.run_adoc_auto_fix(args[:path])
            end

            desc desc_for('heal:all')
            task :all do
              # if the user passed an argument, we wan to tell them this task does not accept any arguments and we want to peaec out of this operation rather than running it
              if ARGV.any? { |arg| arg.include?('labdev:heal:all') && arg.include?('[') }
                puts '⚠️  labdev:heal:all does not accept any arguments. Exiting.'
                puts 'Use labdev:heal:ruby[path] or labdev:heal:adoc[path] to auto-fix specific files.'
                return
              end
              Dev.run_auto_fix
            end
          end

          # Base task; show help for 'heal' namespace
          task :heal do
            Help.show_task_help('heal')
          end

          # ============================================================
          # SHOW and HELP tasks; Display information
          # ============================================================

          namespace :show do
            desc desc_for('show:scripts')
            task :scripts do
              Dev.list_script_templates
            end

            desc desc_for('show:hooks')
            task :hooks do
              Dev.list_hook_templates
            end

            desc desc_for('show:rule')
            task :rule, %i[tool rule] => [] do |_t, args|
              tool = args[:tool]
              rule = args[:rule]

              if tool.nil? || rule.nil?
                puts '❌ Tool and rule are required parameters.'
                puts 'Usage: bundle exec rake labdev:show:rule[tool,rule]'
                puts 'Example: bundle exec rake labdev:show:rule[vale,*.Spelling]'
                return
              end

              Dev.show_lint_rule(tool, rule)
            end
          end

          desc desc_for('help')
          task :help, [:task_string] => [] do |_t, args|
            Help.show_task_help(args[:task_string])
          end
        end
      end
    end
  end
end
