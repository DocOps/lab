# frozen_string_literal: true

require 'English'
module DocOpsLab
  module Dev
    # Git branch safety utilities for Rake tasks
    #
    # Provides methods to safely handle branch switching by checking for:
    # - Uncommitted changes (modified tracked files)
    # - Untracked files that would conflict with target branch
    #
    # @example Basic usage
    #   include DocOpsLab::Dev::GitBranch
    #
    #   current = git_current_branch
    #   if git_safe_to_switch?('gh-pages')
    #     system("git checkout gh-pages")
    #   else
    #     exit 1
    #   end
    #
    # @example With custom error handling
    #   git_ensure_clean_switch!('deploy-branch') do |conflicts|
    #     puts "Found conflicts: #{conflicts.join(', ')}"
    #   end
    module GitBranch
      # Get the current branch name
      #
      # @return [String] the current branch name
      # @raise [RuntimeError] if not in a git repository
      def git_current_branch
        branch = `git branch --show-current 2>&1`.strip
        raise 'Not in a git repository' if $CHILD_STATUS.exitstatus != 0

        branch
      end

      # Check if working directory has uncommitted changes
      #
      # Uses `git status --porcelain` to detect:
      # - Modified tracked files
      # - Staged changes
      # - Deleted files
      #
      # @return [Boolean] true if there are uncommitted changes
      def git_has_uncommitted_changes?
        !`git status --porcelain`.strip.empty?
      end

      # Get list of untracked files in working directory
      #
      # @return [Array<String>] list of untracked file paths
      def git_untracked_files
        `git ls-files --others --exclude-standard`.strip.split("\n")
      end

      # Get list of files in target branch
      #
      # @param branch [String] the target branch name
      # @return [Array<String>] list of file paths in the branch
      # @return [nil] if branch doesn't exist
      def git_files_in_branch branch
        # Check if branch exists
        result = `git rev-parse --verify #{branch} 2>/dev/null`.strip
        return nil if result.empty?

        # List all files in the branch
        `git ls-tree -r #{branch} --name-only`.strip.split("\n")
      end

      # Find untracked files that would conflict with target branch
      #
      # An untracked file conflicts if:
      # - It exists in the working directory (untracked)
      # - A file with the same path exists in the target branch
      # - Switching branches would require overwriting the untracked file
      #
      # @param branch [String] the target branch name
      # @return [Array<String>] list of conflicting file paths
      # @return [nil] if target branch doesn't exist
      def git_conflicting_files branch
        branch_files = git_files_in_branch(branch)
        return nil if branch_files.nil?

        untracked = git_untracked_files
        untracked & branch_files # Intersection
      end

      # Check if it's safe to switch to target branch
      #
      # Safe to switch if:
      # - No uncommitted changes in tracked files
      # - No untracked files that would conflict with target branch
      #
      # @param branch [String] the target branch name
      # @param verbose [Boolean] whether to print detailed messages
      # @return [Boolean] true if safe to switch
      def git_safe_to_switch? branch, verbose: true
        # Check for uncommitted changes
        if git_has_uncommitted_changes?
          puts '❌ You have uncommitted changes. Please commit or stash them first.' if verbose
          puts "💡 Run 'git status' to see changes." if verbose
          return false
        end

        # Check for conflicting untracked files
        conflicts = git_conflicting_files(branch)

        if conflicts.nil?
          puts "❌ Target branch '#{branch}' does not exist." if verbose
          return false
        end

        unless conflicts.empty?
          if verbose
            puts "❌ Untracked files would conflict with branch '#{branch}':"
            conflicts.each { |f| puts "   - #{f}" }
            puts '💡 Commit these files or remove them before switching branches.'
          end
          return false
        end

        true
      end

      # Ensure it's safe to switch branches, exit if not
      #
      # This is a convenience method that calls git_safe_to_switch?
      # and exits with status 1 if not safe.
      #
      # @param branch [String] the target branch name
      # @param verbose [Boolean] whether to print detailed messages
      # @yield [conflicts] optional block to run if conflicts found
      # @yieldparam conflicts [Array<String>] list of conflicting files
      # @return [void]
      def git_ensure_clean_switch! branch, verbose: true
        return if git_safe_to_switch?(branch, verbose: verbose)

        # If block given, call it with conflicts before exiting
        if block_given?
          conflicts = git_conflicting_files(branch) || []
          yield(conflicts)
        end

        exit 1
      end

      # Execute a block on a different branch, then return to original
      #
      # Safely switches to target branch, executes block, then returns
      # to original branch. Ensures clean state before switching.
      #
      # @param branch [String] the target branch to switch to
      # @param verbose [Boolean] whether to print detailed messages
      # @yield the block to execute on the target branch
      # @return [Object] the return value of the block
      # @raise [RuntimeError] if branch switch fails or block raises
      #
      # @example
      #   git_on_branch('gh-pages') do
      #     # Do work on gh-pages
      #     FileUtils.cp_r('_site/*', '.')
      #   end
      #   # Automatically returns to original branch
      def git_on_branch branch, verbose: true
        original_branch = git_current_branch

        # Safety check
        git_ensure_clean_switch!(branch, verbose: verbose)

        begin
          puts "📦 Switching to #{branch} branch..." if verbose
          system("git checkout #{branch}") or raise "Failed to checkout #{branch}"

          # Execute the block
          result = yield

          result
        ensure
          # Always return to original branch
          if git_current_branch != original_branch
            puts "🔄 Returning to #{original_branch} branch..." if verbose
            system("git checkout #{original_branch}")
          end
        end
      end

      # Get a summary of git working directory status
      #
      # @return [Hash] hash with :branch, :clean, :modified_count, :untracked_count
      def git_status_summary
        {
          branch: git_current_branch,
          clean: !git_has_uncommitted_changes?,
          modified_count: `git status --porcelain`.strip.lines.count,
          untracked_count: git_untracked_files.count
        }
      end
    end
  end
end
