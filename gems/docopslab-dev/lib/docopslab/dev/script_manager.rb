# frozen_string_literal: true

require 'fileutils'

module DocOpsLab
  module Dev
    module ScriptManager
      class << self
        def sync_scripts
          puts '📜 Syncing common scripts from DocOps Lab...'

          unless Dir.exist?(SCRIPTS_SOURCE_DIR)
            puts '❌ No scripts directory found in gem'
            return false
          end

          # Ensure vendor scripts directory exists
          vendor_scripts_dir = File.join('scripts', '.vendor', 'docopslab')
          FileUtils.mkdir_p(vendor_scripts_dir)

          synced_count = 0

          Dir.glob("#{SCRIPTS_SOURCE_DIR}/*").each do |script_path|
            next unless File.file?(script_path)

            script_name = File.basename(script_path)
            dest_path = File.join(vendor_scripts_dir, script_name)

            # Check if file needs updating
            if !File.exist?(dest_path) || File.read(script_path) != File.read(dest_path)
              FileUtils.cp(script_path, dest_path)
              File.chmod(0o755, dest_path) # Make executable
              puts "  📜 Synced: #{dest_path} (executable)"
              synced_count += 1
            else
              puts "  ✅ Up to date: #{dest_path}"
            end
          end

          if synced_count.positive?
            puts "✅ Script sync complete; #{synced_count} files updated"
          else
            puts '✅ All scripts up to date'
          end

          true
        end

        def list_script_templates
          unless Dir.exist?(SCRIPTS_SOURCE_DIR)
            puts '❌ No scripts directory found in gem'
            return false
          end

          puts '📜 Available script templates:'

          Dir.glob("#{SCRIPTS_SOURCE_DIR}/*").each do |script_path|
            next unless File.file?(script_path)

            script_name = File.basename(script_path)

            # Try to extract description from script comments
            description = 'No description available'
            if File.readable?(script_path)
              File.open(script_path, 'r') do |f|
                f.each_line do |line|
                  if line.match(/^#\s*(.+)$/) && !line.include?('!/bin/')
                    description = line.match(/^#\s*(.+)$/)[1]
                    break
                  end
                end
              end
            end

            puts "  • #{script_name}: #{description}"
          end

          true
        end

        def run_script script_name, args=[]
          unless script_name
            puts '❌ Script name is required'
            puts 'Usage: bundle exec rake labdev:run[script_name] -- [args]'
            return false
          end

          # Add .sh extension if NO extension provided
          # (valid extensions are .sh, .rb, py, .js)
          script_name += '.sh' unless File.extname(script_name).length.positive?

          # Look for local script first
          project_script = File.join('scripts', script_name)
          vendor_script = File.join('scripts', '.vendor', 'docopslab', script_name)

          script_to_run = nil
          if File.exist?(project_script)
            puts "📜 Running local script: #{project_script}"
            script_to_run = project_script
          elsif File.exist?(vendor_script)
            puts "📜 Running vendor script: #{vendor_script}"
            script_to_run = vendor_script
          else
            puts "❌ Script not found: #{script_name}"
            puts 'Searched in:'
            puts "  - #{project_script}"
            puts "  - #{vendor_script}"
            return false
          end

          # Run the script using proper runtime and args
          case File.extname(script_to_run)
          when '.sh', ''
            cmd = ['bash']
          when '.rb'
            cmd = ['ruby']
          when '.py'
            cmd = ['python3']
          when '.js'
            cmd = ['node']
          else
            puts "❌ Unsupported script extension: #{File.extname(script_to_run)}"
            return false
          end
          cmd << script_to_run
          cmd.concat(args) if args.any?
          puts "🚀 Executing: #{cmd.join(' ')}"

          system(*cmd)

          $CHILD_STATUS.success?
        end
      end
    end
  end
end
