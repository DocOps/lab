# frozen_string_literal: true

require 'fileutils'

module DocOpsLab
  module Dev
    module Initializer
      class << self
        def create_project_manifest
          return if File.exist?(MANIFEST_PATH)

          puts '📋 Creating docopslab-dev.yml...'

          FileUtils.mkdir_p('.config')

          # Copy template from gem
          FileUtils.cp(Dev.manifest_def_path, MANIFEST_PATH)
          puts "✅ Created #{MANIFEST_PATH}"
        end

        def create_gitignore_stub
          if File.exist?('.gitignore')
            puts '⏭️  .gitignore already exists, skipping'
            return false
          end

          Library.ensure_available!
          stub = Library.resolve('templates/gitignore') ||
                 raise('Library templates/gitignore not found; run `labdev:sync:library`.')
          FileUtils.cp(stub, '.gitignore')
          puts '✅ Created .gitignore file'
          true
        end

        def create_gemfile_stub
          if File.exist?('Gemfile')
            puts '⏭️  Gemfile already exists, skipping'
            return false
          end

          Library.ensure_available!
          stub = Library.resolve('templates/Gemfile') ||
                 raise('Library templates/Gemfile not found; run `labdev:sync:library`.')
          FileUtils.cp(stub, 'Gemfile')
          puts '✅ Created Gemfile'
          true
        end

        def create_rakefile_stub
          if File.exist?('Rakefile')
            puts '⏭️  Rakefile already exists, skipping'
            return false
          end

          Library.ensure_available!
          stub = Library.resolve('templates/Rakefile') ||
                 raise('Library templates/Rakefile not found; run `labdev:sync:library`.')
          FileUtils.cp(stub, 'Rakefile')
          puts '✅ Created Rakefile'
          true
        end

        def init_git_repository
          if Dir.exist?('.git')
            puts '⏭️  Git repository already initialized, skipping'
            return false
          end

          system('git', 'init')
          puts '✅ Initialized Git repository'
          true
        end

        def bootstrap_project
          puts '� Bootstrapping DocOps Lab project...'
          puts ''

          created = []

          # Core project files
          created << 'Git repository' if init_git_repository
          created << '.gitignore' if create_gitignore_stub
          # Skip Gemfile; not needed for Docker workflow, template available if needed
          created << 'Rakefile' if create_rakefile_stub

          # DocOpsLab-specific
          create_project_manifest
          created << '.config/docopslab-dev.yml' unless File.exist?(MANIFEST_PATH)

          puts ''
          if created.any?
            puts "✅ Bootstrap complete! Created: #{created.join(', ')}"
            puts ''
            puts 'Next steps:'
            puts '  1. bundle exec rake labdev:sync:all  # or: docker run ... labdev:sync:all'
            puts '  2. Start using labdev tasks!'
          else
            puts '✅ Project already initialized, nothing to create'
          end
        end
      end
    end
  end
end
