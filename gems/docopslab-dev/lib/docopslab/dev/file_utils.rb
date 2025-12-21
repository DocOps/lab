# frozen_string_literal: true

require 'pathname'

module DocOpsLab
  module Dev
    module FileUtilities
      class << self
        def find_shell_scripts context
          # First, try to find files using the new path configuration system
          files = find_files_to_lint('shellcheck', context)
          return files if files && !files.empty?

          # Fallback to old method if no paths are configured for shellcheck
          scripts = []
          patterns = [
            '**/*.sh',
            '**/*.bash',
            '**/.*rc',
            '**/.*profile',
            'scripts/*.sh'
          ]
          patterns.each do |pattern|
            Dir.glob(pattern).each do |file|
              next unless File.file?(file)
              next if file.include?('/.vendor/')
              next if file.include?('/node_modules/')
              next unless FileUtilities.git_tracked_or_staged?(file)

              scripts << file if File.executable?(file) || FileUtilities.shell_shebang?(file)
            end
          end
          scripts.uniq.sort
        end

        def shell_shebang? file
          return false unless File.readable?(file)

          first_line = File.open(file, 'r') do |f|
            f.readline
          rescue StandardError
            ''
          end
          first_line.start_with?('#!') &&
            (first_line.include?('sh') || first_line.include?('bash'))
        end

        def find_files_to_lint tool_slug, context
          path_config = context.get_path_config(tool_slug)
          lint_paths = path_config[:lint]
          skip_paths = path_config[:skip]
          exts = path_config[:exts]
          git_tracked_only = path_config[:git_tracked_only]

          return [] unless lint_paths

          files = []
          lint_paths.each do |path|
            # If path is a directory, search recursively. Otherwise, it's a glob.
            glob_pattern = File.directory?(path) ? File.join(path, '**', '*') : path
            Dir.glob(glob_pattern).each do |file|
              next unless File.file?(file)

              # Normalize path by removing ./ prefix for consistent pattern matching
              normalized = file.sub(%r{^\./}, '')
              files << normalized
            end
          end

          files.uniq!

          # Filter by extension if exts is provided
          if exts && !exts.empty?
            files.select! do |file|
              ext = File.extname(file).delete_prefix('.')
              exts.include?(ext)
            end
          end

          # Filter out ignored paths
          files.reject! do |file|
            should_skip = skip_paths.any? do |ignored|
              FileUtilities.file_matches_ignore_pattern?(file, ignored)
            end
            should_skip
          end

          # Filter by git tracking status
          if git_tracked_only
            files.select! do |file|
              is_tracked = FileUtilities.git_tracked_or_staged?(file)
              is_tracked
            end
          end

          files.sort
        end

        def find_asciidoc_files context
          FileUtilities.find_files_to_lint('vale', context)
        end

        def file_matches_ignore_pattern? file, pattern
          if pattern.include?('*') || pattern.include?('?')
            # Handle glob patterns
            # If pattern ends with /*, treat it as recursive (dir/**/*)
            recursive_pattern = if pattern.end_with?('/*')
                                  pattern.sub(%r{/\*$}, '/**/*')
                                else
                                  pattern
                                end

            File.fnmatch(recursive_pattern, file, File::FNM_PATHNAME | File::FNM_DOTMATCH) ||
              # Also try exact match without modification for explicit patterns
              File.fnmatch(pattern, file, File::FNM_PATHNAME | File::FNM_DOTMATCH)
          else
            # Non-glob patterns: match directory name anywhere in path
            File.fnmatch("**/#{pattern}/**", file, File::FNM_PATHNAME | File::FNM_DOTMATCH) ||
              File.fnmatch("**/#{pattern}", file, File::FNM_PATHNAME | File::FNM_DOTMATCH)
          end
        end

        def git_tracked_or_staged? file
          return true unless Dir.exist?('.git')

          repo_root = `git rev-parse --show-toplevel`.strip
          rel = Pathname.new(file).expand_path.relative_path_from(Pathname.new(repo_root)).to_s

          # Check if the file is tracked
          return true if system('git', 'ls-files', '--error-unmatch', rel, out: File::NULL, err: File::NULL)

          # Check if the file is staged (but not necessarily committed yet)
          return true if system('git', 'diff', '--name-only', '--cached', '--', rel, out: File::NULL, err: File::NULL)

          false
        end
      end
    end
  end
end
