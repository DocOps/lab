# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'pathname'

module DocOpsLab
  module Dev
    # rubocop:disable Metrics/ModuleLength
    module SyncOps
      # rubocop:disable Metrics/ClassLength
      class << self
        def install_vale_styles context
          return unless File.exist?(Paths::CONFIG_FILES[:vale]) && context.tool_available?('vale')

          puts "📚 Syncing Vale styles using Packages key in #{Paths::CONFIG_FILES[:vale]} (local and remote packages)"
          context.run_with_fallback('vale', "vale --config=#{Paths::CONFIG_FILES[:vale]} sync")
        end

        def sync_vale_styles context, local: false
          puts '📚 Syncing Vale styles...'

          unless Library.available?
            puts '❌ Library not available; run `labdev:sync:library` to fetch.'
            return false
          end
          styles_source_root = Library.resolve('config-packs/vale')
          unless styles_source_root
            puts '❌ config-packs/vale not found in library; run `labdev:sync:library` to fetch.'
            return false
          end
          styles_dest_root = '.config/.vendor/vale/styles'
          FileUtils.mkdir_p(styles_dest_root)

          # Get the list of local styles from tools.yml
          begin
            tools_yml_path = Dev.tools_def_path

            style_paths_array = YAML.load_file(tools_yml_path)
                                    .find { |t| t['slug'] == 'vale' }['packaging']['packages']

            synced_styles = 0
            style_paths_array.each do |package|
              vale_name = package['target']
              src_name = package['source']
              source_style_dir = File.join(styles_source_root, src_name)
              dest_style_dir = File.join(styles_dest_root, vale_name)

              next unless File.directory?(source_style_dir)

              # Copy style directory
              FileUtils.rm_rf(dest_style_dir)
              FileUtils.cp_r(source_style_dir, dest_style_dir)
              puts "  ✓ Synced custom style: #{vale_name}"
              synced_styles += 1
            end

            # copy style scripts directory
            scripts_source = File.join(styles_source_root, 'config', 'scripts')
            scripts_dest = File.join(styles_dest_root, 'config', 'scripts')
            if File.directory?(scripts_source)
              FileUtils.rm_rf(scripts_dest)
              FileUtils.mkdir_p(File.dirname(scripts_dest))
              FileUtils.cp_r(scripts_source, scripts_dest)
              puts '  ✓ Synced style scripts directory'
            else
              puts "  ⚠️  No style scripts directory found at #{scripts_source}; skipping"
            end

            puts "  ✅ Synced #{synced_styles} custom Vale style(s)" if synced_styles.positive?
          rescue StandardError => e
            puts "  ⚠️  Error syncing local Vale styles: #{e.message}"
            false
          end

          # If not local-only, also run Vale sync for remote styles
          unless local
            puts '📦 Syncing remote Vale packages...'
            vale_config = Paths::CONFIG_FILES[:vale]
            context.generate_vale_config unless File.exist?(vale_config)
            context.run_with_fallback('vale', "vale --config=#{vale_config} sync")
          end

          true
        end

        def sync_docs context, force: false
          manifest = context.load_manifest
          return false unless manifest

          docs_entries = manifest['docs']
          return false unless docs_entries.is_a?(Array)

          lib_root = Library.root
          unless lib_root
            puts '❌ Library not available; run `labdev:sync:library` to fetch.'
            return false
          end

          puts '📚 Syncing documentation files...'

          synced_count = 0
          skipped_count = 0
          sources_checked = []
          excluded_files = Set.new

          # First pass: collect all explicitly excluded files (synced: false)
          docs_entries.each do |entry|
            source_pattern = entry['source']
            synced = entry.fetch('synced', false)

            next unless source_pattern
            next if synced # Only collect exclusions

            # Resolve source file path relative to library root
            if source_pattern.include?('*')
              source_glob = File.join(lib_root, source_pattern)
              Dir.glob(source_glob).each do |source_file|
                excluded_files.add(source_file) if File.file?(source_file)
              end
            else
              source_file = File.join(lib_root, source_pattern)
              excluded_files.add(source_file) if File.exist?(source_file)
            end
          end

          # rubocop:disable Style/CombinableLoops
          # Second pass: process inclusions, respecting exclusions
          # These loops cannot be combined as they implement different phases of a two-pass algorithm
          docs_entries.each do |entry|
            source_pattern = entry['source']
            target_path = entry['target']
            synced = entry.fetch('synced', false)

            next unless source_pattern && target_path
            next unless synced # Only process inclusions

            # Check if source is a glob pattern
            if source_pattern.include?('*')
              source_glob = File.join(lib_root, source_pattern)
              matching_files = Dir.glob(source_glob)

              if matching_files.empty?
                puts "  ⚠️  No files matched pattern: #{source_pattern}"
                next
              end

              matching_files.each do |source_file|
                next unless File.file?(source_file)
                next if sources_checked.include?(source_file)

                if excluded_files.include?(source_file)
                  puts "  ⏭️  Skipped #{File.basename(source_file)} (explicitly excluded)"
                  next
                end

                # Guard: docs/agent/AGENTS.md was relocated to templates/AGENTS.markdown.
                if source_file.end_with?('docs/agent/AGENTS.md')
                  puts '  ⏭️  Skipped docs/agent/AGENTS.md \
                        (relocated to templates/AGENTS.markdown; remove from manifest)'
                  next
                end

                filename = File.basename(source_file)
                target_file = File.join(target_path, filename)

                sources_checked << source_file
                result = copy_doc_file(source_file, target_file, synced: synced, force: force)
                synced_count += 1 if result == :copied
                skipped_count += 1 if result == :skipped
              end
            else # Single file
              source_file = File.join(lib_root, source_pattern)

              unless File.exist?(source_file)
                puts "  ❌ Source file not found: #{source_file}"
                puts "     Run 'bundle exec rake labdev:sync:library` then 'labdev:sync:docs' to refresh"
                next
              end

              next if sources_checked.include?(source_file)

              # Skip if explicitly excluded (shouldn't happen for inclusions, but safety check)
              if excluded_files.include?(source_file)
                puts "  ⏭️  Skipped #{File.basename(source_file)} (explicitly excluded)"
                next
              end

              # Guard: docs/agent/AGENTS.md was relocated to templates/AGENTS.markdown.
              if source_file.end_with?('docs/agent/AGENTS.md')
                puts '  ⏭️  Skipped docs/agent/AGENTS.md (relocated to templates/AGENTS.markdown; remove from manifest)'
                next
              end

              sources_checked << source_file

              result = copy_doc_file(source_file, target_path, synced: synced, force: force)
              synced_count += 1 if result == :copied
              skipped_count += 1 if result == :skipped
            end
          end
          # rubocop:enable Style/CombinableLoops

          puts "✅ Synced #{synced_count} doc files" if synced_count.positive?
          puts "ℹ️  Skipped #{skipped_count} existing files (use --force to overwrite)" if skipped_count.positive?

          synced_count.positive? || skipped_count.positive?
        end

        def sync_scripts _context
          ScriptManager.sync_scripts
        end

        def sync_templates context, force: false
          manifest = context.load_manifest
          return false unless manifest

          template_entries = manifest['templates']
          return false unless template_entries.is_a?(Array)

          lib_root = Library.root
          unless lib_root
            puts '❌ Library not available; run `labdev:sync:library` to fetch.'
            return false
          end

          puts '📄 Syncing template files...'

          synced_count = 0
          skipped_count = 0

          template_entries.each do |entry|
            source_rel = entry['source']
            target_path = entry['target']
            synced = entry.fetch('synced', false)

            next unless source_rel && target_path

            source_file = File.join(lib_root, source_rel)

            unless File.exist?(source_file)
              puts "  \u274c Template source not found: #{source_rel}"
              puts '     Run `bundle exec rake labdev:sync:library` to fetch the latest library.'
              next
            end

            result = copy_doc_file(source_file, target_path, synced: synced, force: force)
            synced_count  += 1 if result == :copied
            skipped_count += 1 if result == :skipped
          end

          puts "\u2705 Synced #{synced_count} template file(s)" if synced_count.positive?
          if skipped_count.positive?
            puts "\u2139\ufe0f  Skipped #{skipped_count} existing template(s) (use --force to overwrite)"
          end

          synced_count.positive? || skipped_count.positive?
        end

        def sync_config_files context, tool_filter: :all, offline: false
          # Validate tool filter parameter
          unless tool_filter == :all || tool_filter.is_a?(String) || tool_filter.is_a?(Symbol)
            puts "❌ Invalid tool filter: #{tool_filter}. Must be :all, tool name string, or tool symbol"
            return false
          end

          puts offline ? '🔄 Syncing configs (offline mode)...' : '🔄 Syncing configuration files...'

          # Check for docopslab-dev.yml manifest
          unless File.exist?(MANIFEST_PATH)
            puts "ℹ️  No #{MANIFEST_PATH} found"
            puts "❌ Legacy sync mode not implemented. Run 'rake labdev:init' to create manifest."
            return false
          end

          # Parse manifest
          begin
            manifest = YAML.load_file(MANIFEST_PATH)
          rescue StandardError => e
            puts "❌ Failed to parse #{MANIFEST_PATH}: #{e.message}"
            return false
          end

          config_packs_root = Library.resolve('config-packs')
          unless config_packs_root && Dir.exist?(config_packs_root)
            puts '❌ config-packs not found in library; run `labdev:sync:library` to fetch.'
            return false
          end

          # Get available tools from manifest for validation
          available_tools = manifest['tools']&.map { |t| t['tool'] } || []

          # Validate specific tool filter
          if tool_filter != :all
            tool_filter_str = tool_filter.to_s
            unless available_tools.include?(tool_filter_str)
              puts "❌ Tool '#{tool_filter_str}' not found in manifest. Available tools: #{available_tools.join(', ')}"
              return false
            end
            puts "📦 Filtering to tool: #{tool_filter_str}"
          end

          synced_count = 0
          expected_targets = Set.new

          # Process each tool from manifest
          manifest['tools']&.each do |tool_entry|
            tool_name = tool_entry['tool']
            enabled = tool_entry.fetch('enabled', true)

            # Skip if filtering to specific tool and this isn't it
            next if tool_filter != :all && tool_name != tool_filter.to_s

            unless enabled
              puts "⏭️  Skipping #{tool_name} (disabled in manifest)"
              next
            end

            puts "📦 Processing #{tool_name} config pack..."

            # Process each file mapping
            tool_entry['files']&.each do |file_config|
              source_rel = file_config['source']
              target_path = file_config['target']
              synced = file_config.fetch('synced', true)
              file_enabled = file_config.fetch('enabled', true)

              unless file_enabled
                puts "  ⏭️  Skipping #{source_rel} (disabled)"
                next
              end

              source_path = File.join(config_packs_root, source_rel)

              unless File.exist?(source_path)
                puts "  ❌ Source not found: #{source_rel}"
                next
              end

              # Add to expected targets for cleanup, regardless of synced status
              expected_targets.add(target_path)

              # Handle directory syncing (source ends with /)
              if source_rel.end_with?('/')
                sync_result = sync_directory(
                  source_path, target_path, synced: synced, expected_targets: expected_targets)
                synced_count += sync_result
              else
                # Create destination directory if needed
                FileUtils.mkdir_p(File.dirname(target_path))

                # Determine if we should copy the file
                file_existed_before_copy = File.exist?(target_path)

                should_copy = if synced # If synced: true, copy if missing or different
                                !file_existed_before_copy || File.read(source_path) != File.read(target_path)
                              else # If synced: false, copy only if missing
                                !file_existed_before_copy
                              end

                if should_copy
                  FileUtils.cp(source_path, target_path)
                  message = if synced
                              "📝 Synced: #{target_path} (auto-sync)"
                            elsif !file_existed_before_copy
                              "✅ Created: #{target_path}"
                            else
                              "📝 Synced: #{target_path}" # Fallback
                            end
                  puts "  #{message}"
                  synced_count += 1
                else
                  puts "  ✅ Up to date: #{target_path}"
                end
              end
            end
          end

          cleanup_count = cleanup_obsolete_files(context, expected_targets)

          # Generate runtime configs after syncing base configs
          puts '🔧 Generating runtime configs...'
          generated_count = 0
          generated_count += 1 if context.generate_vale_config
          generated_count += 1 if context.generate_htmlproofer_config

          puts '  ✅ All runtime configs up to date' if generated_count.zero?

          total_changes = synced_count + cleanup_count + generated_count
          if total_changes.positive?
            puts "✅ Config sync complete; #{synced_count} files updated, " \
                 "#{cleanup_count} files cleaned up, #{generated_count} configs generated"
          else
            puts '✅ All configs up to date'
          end

          true
        end

        def sync_directory source_dir, target_dir, synced: false, expected_targets: nil
          synced_count = 0

          FileUtils.mkdir_p(target_dir)

          # Sync all files in the source directory
          Dir.glob("#{source_dir}/**/*", File::FNM_DOTMATCH).each do |source_file|
            next if File.directory?(source_file)
            next if File.basename(source_file).start_with?('.') && ['.', '..'].include?(File.basename(source_file))

            # Calculate relative path within source directory
            rel_path = Pathname.new(source_file).relative_path_from(Pathname.new(source_dir))
            target_file = File.join(target_dir, rel_path)

            # Track expected files for cleanup detection
            expected_targets&.add(target_file) if synced

            # Create target subdirectory if needed
            FileUtils.mkdir_p(File.dirname(target_file))

            # Copy file if it doesn't exist or is different
            if !File.exist?(target_file) || File.read(source_file) != File.read(target_file)
              FileUtils.cp(source_file, target_file)
              puts "  📝 Synced: #{target_file}#{' (auto-sync)' if synced}"
              synced_count += 1
            else
              puts "  ✅ Up to date: #{target_file}"
            end
          end

          synced_count
        end

        def cleanup_obsolete_files _context, expected_targets
          cleanup_count = 0
          obsolete_files = []
          # Common vendor paths to check for obsolete files
          vendor_patterns = [
            File.join(Paths.config_vendor_dir, '**', '*')
          ]
          vendor_patterns.each do |pattern|
            Dir.glob(pattern).each do |file_path|
              next if File.directory?(file_path)
              next if file_path.include?('/.git/') # Skip git files

              # Check if this file is expected based on manifest
              obsolete_files << file_path unless expected_targets.include?(file_path)
            end
          end
          return 0 if obsolete_files.empty?

          puts "\n🧹 Found #{obsolete_files.length} potentially obsolete vendor files:"
          obsolete_files.sort.each do |file|
            puts "  📄 #{file}"
          end
          print "\nClean up these obsolete files? [y/N]: "
          response = $stdin.gets.chomp.downcase
          if %w[y yes].include?(response)
            obsolete_files.each do |file|
              File.delete(file)
              puts "  🗑️  Removed: #{file}"
              cleanup_count += 1
            rescue StandardError => e
              puts "  ❌ Failed to remove #{file}: #{e.message}"
            end
            # Clean up empty directories
            vendor_patterns.each do |pattern|
              base_dir = pattern.split('/**').first
              next unless Dir.exist?(base_dir)

              cleanup_empty_directories(base_dir)
            end
          else
            puts '⏭️  Skipping cleanup of obsolete files'
          end

          cleanup_count
        end

        private

        def cleanup_empty_directories dir_path
          return unless Dir.exist?(dir_path)

          # Get all subdirectories, sorted by depth (deepest first)
          subdirs = Dir.glob("#{dir_path}/**/*/").sort_by { |d| -d.count('/') }

          subdirs.each do |subdir|
            next unless Dir.exist?(subdir)
            next unless Dir.empty?(subdir)

            begin
              Dir.rmdir(subdir)
              puts "  📁 Removed empty directory: #{subdir}"
            rescue StandardError
              # Ignore errors; directory might not be empty due to hidden files
            end
          end
        end

        def copy_doc_file source_file, target_path, synced:, force:
          # Ensure target directory exists
          target_dir = File.dirname(target_path)
          FileUtils.mkdir_p(target_dir)

          # Check if target already exists
          if File.exist?(target_path)
            if synced || force
              # Overwrite if synced or force flag
              FileUtils.cp(source_file, target_path)
              puts "  🔄 Updated #{target_path}"
              :copied
            else
              # Skip if not synced and no force
              puts "  ⏭️  Skipped #{target_path} (already exists, synced=false)"
              :skipped
            end
          else
            # Create new file
            FileUtils.cp(source_file, target_path)
            puts "  ✓ Created #{target_path}"
            :copied
          end
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
    # rubocop:enable Metrics/ModuleLength
  end
end
