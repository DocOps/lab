# frozen_string_literal: true

module DocOpsLab
  module Dev
    module Checkers
      class << self
        def lab_dev_mode?
          # Detect if we are running inside the DocOps/lab monorepo
          Dir.exist?('gems/docopslab-dev')
        end

        def gem_sourced_locally?
          # Check if the gem is being used via a path dependency (development mode)
          # This is true when running from issuer, releasehx, etc. with path: '../lab/gems/docopslab-dev'
          # The GEM_ROOT will point to a local filesystem path rather than a gem installation
          !GEM_ROOT.include?('/gems/') || GEM_ROOT.include?('/lab/gems/docopslab-dev')
        end

        def check_ruby_version
          expected_version = RUBY_TARGET
          current_version = RUBY_VERSION

          puts "Ruby version: #{current_version}"

          if current_version == expected_version
            puts "✅ Ruby version matches DocOps Lab standard (#{expected_version})"
          else
            puts "⚠️  Ruby version differs from DocOps Lab standard (#{expected_version})"
          end

          if File.exist?('.ruby-version')
            file_version = File.read('.ruby-version').strip
            puts "📄 .ruby-version file specifies: #{file_version}"

            if file_version == expected_version
              puts '✅ .ruby-version matches DocOps Lab standard'
            else
              puts '⚠️  .ruby-version differs from DocOps Lab standard'
            end
          else
            puts 'ℹ️  No .ruby-version file found'
          end
        end

        def check_config_structure context
          puts "\n📋 Configuration Status:"

          manifest = context.load_manifest

          if manifest
            puts '✅ Manifest found: .config/docopslab-dev.yml'
          else
            puts "❌ No manifest found; run 'labdev:init:all' to create one"
            return
          end

          # Check configs for each tool in manifest
          manifest['tools']&.each do |tool_entry|
            tool_slug = tool_entry['tool']
            tool_meta = context.get_tool_metadata(tool_slug)
            tool_name = tool_meta ? tool_meta['name'] : tool_slug
            tool_enabled = tool_entry.fetch('enabled', true)

            unless tool_enabled
              puts "⏭️  #{tool_name}: disabled in manifest"
              next
            end

            files = context.get_tool_files(tool_slug)

            unless files[:project]
              puts "⚠️  #{tool_name}: no project config defined in manifest"
              next
            end

            project_path = files[:project][:local]
            unless project_path && File.exist?(project_path)
              puts "❌ No #{tool_name} project config found; run 'labdev:init:all' to create one"
              next
            end

            # Check for base config if tool uses vendor base
            if files[:base] && tool_meta && tool_meta['config']['uses_vendor_base']
              base_status = File.exist?(files[:base][:local]) ? '✅' : '❌'
              puts "✅ #{tool_name} project config: #{project_path} (base: #{base_status})"
            else
              puts "✅ #{tool_name} project config: #{project_path}"
            end
          end
        end

        def check_standard_rake_tasks
          # Checks local Rakefile for presence of standard (non-labdev) tasks
          standard_tasks = %w[rspec cli_test yaml_test pr_test install_local]
          missing_tasks = []
          standard_tasks.each do |task_name|
            missing_tasks << task_name unless Rake::Task.task_defined?(task_name)
          end
          if missing_tasks.empty?
            puts '✅ All standard Rake tasks are present'
          else
            puts "❌ Missing standard Rake tasks: #{missing_tasks.join(', ')}"
          end
        end
      end
    end
  end
end
