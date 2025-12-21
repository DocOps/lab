# frozen_string_literal: true

require 'fileutils'

module DocOpsLab
  module Dev
    module GitHooks
      class << self
        def install_missing_hooks
          return unless Dir.exist?(hooks_dir)

          Dir.glob("#{hooks_template_dir}/*.sh").each do |template_path|
            hook_name = File.basename(template_path, '.sh')
            hook_path = File.join(hooks_dir, hook_name)

            next if File.exist?(hook_path)

            puts "🪝 Installing #{hook_name} hook..."
            FileUtils.cp(template_path, hook_path)
            File.chmod(0o755, hook_path)
            puts "✅ #{hook_name} hook installed"
          end
        end

        def check_hook_updates
          return puts 'ℹ️  No .git directory found' unless Dir.exist?(hooks_dir)

          updates_available = false

          Dir.glob("#{hooks_template_dir}/*.sh").each do |template_path|
            hook_name = File.basename(template_path, '.sh')
            hook_path = File.join(hooks_dir, hook_name)

            if File.exist?(hook_path)
              template_content = File.read(template_path)
              current_content = File.read(hook_path)

              if template_content != current_content
                puts "🔄 Update available for #{hook_name} hook"
                updates_available = true
              end
            else
              puts "➕ New hook template available: #{hook_name}"
              updates_available = true
            end
          end

          if updates_available
            puts "Run 'rake labdev:sync:hooks' to update hooks interactively"
          else
            puts '✅ All hooks are up to date'
          end
        end

        def update_hooks_interactive
          return puts 'ℹ️  No .git directory found' unless Dir.exist?(hooks_dir)

          Dir.glob("#{hooks_template_dir}/*.sh").each do |template_path|
            hook_name = File.basename(template_path, '.sh')
            hook_path = File.join(hooks_dir, hook_name)

            if File.exist?(hook_path)
              template_content = File.read(template_path)
              current_content = File.read(hook_path)

              next if template_content == current_content

              puts "🔄 #{hook_name} hook has updates available"
              puts "Current file exists at: #{hook_path}"

              print "Update #{hook_name} hook? [y/N]: "
              response = $stdin.gets.chomp.downcase

              if %w[y yes].include?(response)
                File.write(hook_path, template_content)
                File.chmod(0o755, hook_path)
                puts "✅ #{hook_name} hook updated"
              else
                puts "⏭️  Skipped #{hook_name} hook"
              end
            else
              puts "➕ New hook template: #{hook_name}"
              print "Install #{hook_name} hook? [Y/n]: "
              response = $stdin.gets.chomp.downcase

              if response != 'n' && response != 'no'
                FileUtils.cp(template_path, hook_path)
                File.chmod(0o755, hook_path)
                puts "✅ #{hook_name} hook installed"
              else
                puts "⏭️  Skipped #{hook_name} hook"
              end
            end
          end
        end

        def list_hook_templates
          puts '📋 Available git hook templates:'
          puts ''

          Dir.glob("#{hooks_template_dir}/*.sh").each do |template_path|
            hook_name = File.basename(template_path, '.sh')
            hook_path = File.join(hooks_dir, hook_name)

            status = nil
            if File.exist?(hook_path)
              template_content = File.read(template_path)
              current_content = File.read(hook_path)
              status = template_content == current_content ? '✅ installed' : '🔄 update available'
            else
              status = '➕ not installed'
            end

            description = case hook_name
                          when 'pre-commit'
                            'Advisory checks & syntax validation (non-blocking)'
                          when 'pre-push'
                            'Comprehensive linting & quality gate (blocking)'
                          else
                            ''
                          end

            puts "  #{hook_name}: #{status}"
            puts "    #{description}" unless description.empty?
          end
        end

        private

        def hooks_template_dir
          HOOKS_SOURCE_DIR
        end

        def hooks_dir
          HOOKS_DIR
        end
      end
    end
  end
end
