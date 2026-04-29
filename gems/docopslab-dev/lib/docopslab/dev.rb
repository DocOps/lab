# frozen_string_literal: true

require 'English'
require 'rake/tasklib'
require 'yaml'
require 'fileutils'
require 'pathname'
require 'shellwords'
require_relative 'dev/version' # includes RUBY_TARGET
require_relative 'dev/paths'
require_relative 'dev/manifest'
require_relative 'dev/spell_check'
require_relative 'dev/log_parser'
require_relative 'dev/skim'
require_relative 'dev/tasks'
require_relative 'dev/git_hooks'
require_relative 'dev/tool_execution'
require_relative 'dev/git_branch'
require_relative 'dev/linters'
require_relative 'dev/config_manager'
require_relative 'dev/file_utils'
require_relative 'dev/script_manager'
require_relative 'dev/library'
require_relative 'dev/sync_ops'
require_relative 'dev/data_utils'
require_relative 'dev/cast_ops'
require_relative 'dev/checkers'
require_relative 'dev/initializer'
require_relative 'dev/auto_fix_asciidoc'
require_relative 'dev/help'

# Suppress experimental IO::Buffer warning from io-event gem (via html-proofer)
Warning[:experimental] = false if Warning.respond_to?(:[]=)

module DocOpsLab
  module Dev
    GEM_ROOT = begin
      spec = Gem::Specification.find_by_name('docopslab-dev')
      if spec
        spec.gem_dir
      else # Fallback for development
        File.expand_path('../../../', __dir__)
      end
    end

    # Path constants (Backwards compatibility)
    MANIFEST_PATH = '.config/docopslab-dev.yml'
    XDG_CACHE_SUBPATH = 'docopslab/dev/library'

    class << self
      attr_accessor :manifest, :tools_data
      attr_writer :manifest_path, :xdg_cache_subpath

      def manifest_path
        @manifest_path || MANIFEST_PATH
      end

      def xdg_cache_subpath
        @xdg_cache_subpath || XDG_CACHE_SUBPATH
      end

      # Upstream library defaults
      def default_library_repo
        'DocOps/lab'
      end

      def default_library_branch
        'labdev-library'
      end

      # Project paths (local/runtime)
      def config_vendor_dir
        Paths.config_vendor_dir
      end

      def hooks_dir
        '.git/hooks'
      end

      # Runtime/generated config files (merged from base + local)
      def config_paths
        Paths::CONFIG_FILES
      end

      # Shorthand for rubocop (most commonly referenced)
      def rubocop_config_path
        config_paths[:rubocop]
      end

      # Gem data paths (bundled with gem in specs/data/)
      def manifest_def_path
        File.join(GEM_ROOT, 'specs', 'data', 'default-manifest.yml')
      end

      def tools_def_path
        File.join(GEM_ROOT, 'specs', 'data', 'tools.yml')
      end

      # Asset paths are resolved at runtime from the remote library cache.
      # Use Library.resolve('config-packs/...'), Library.resolve('templates/...') etc.
      def library_path subpath=nil
        return Library::Cache.current_path unless subpath

        File.join(Library::Cache.current_path, subpath)
      end

      def load_manifest force_reload: false
        return @manifest if @manifest && !force_reload

        @manifest = YAML.load_file(manifest_path) if File.exist?(manifest_path)
        @manifest
      rescue StandardError => e
        warn "Failed to load manifest at #{manifest_path}: #{e.message}"
        nil
      end

      def load_tools_data
        return @tools_data if @tools_data

        @tools_data = begin
          if File.exist?(tools_def_path)
            YAML.load_file(tools_def_path)
          else
            []
          end
        rescue StandardError => e
          warn "Failed to load tools data: #{e.message}"
          []
        end
      end

      def get_tool_metadata tool_slug
        # Get a tool's info from tools definition
        tools_data = load_tools_data
        tools_data.find { |t| t['slug'] == tool_slug }
      end

      def get_tool_entry tool_slug
        # Get a tool's configuration from project manifest
        manifest = load_manifest
        return nil unless manifest

        manifest['tools']&.find { |t| t['tool'] == tool_slug }
      end

      def get_tool_files tool_slug
        # Get file mappings for a tool from manifest
        # Returns hash: { base: {upstream:, local:, synced:}, project: {upstream:, local:, synced:} }
        tool_entry = get_tool_entry(tool_slug)
        return {} unless tool_entry

        files = {}
        tool_entry['files']&.each do |file_config|
          target_path = file_config['target']
          source_path = file_config['source']

          next unless target_path # Skip if no target path defined

          if target_path.include?('.vendor/')
            files[:base] = {
              source: source_path,
              local: target_path,
              synced: file_config.fetch('synced', true)
            }
          else
            files[:project] = {
              source: source_path,
              local: target_path,
              synced: file_config.fetch('synced', false)
            }
          end
        end

        files
      end

      # Tool Execution

      def run_with_fallback tool_name, command, use_docker: false
        ToolExecution.run_with_fallback(tool_name, command, use_docker: use_docker)
      end

      def run_in_docker command
        ToolExecution.run_in_docker(command)
      end

      def run_script script_name, args=[]
        ScriptManager.run_script(script_name, args)
      end

      # Initialization

      def create_project_manifest
        Initializer.create_project_manifest
      end

      def bootstrap_project
        Initializer.bootstrap_project
      end

      def install_vale_styles
        SyncOps.install_vale_styles(self)
      end

      def install_missing_hooks
        GitHooks.install_missing_hooks
      end

      def check_hook_updates
        GitHooks.check_hook_updates
      end

      def update_hooks_interactive
        GitHooks.update_hooks_interactive
      end

      def create_gitignore_stub
        Initializer.create_gitignore_stub
      end

      # Sync Operations

      def sync_config_files tool_filter=:all, offline: false
        SyncOps.sync_config_files(self, tool_filter: tool_filter, offline: offline)
      end

      def sync_directory source_dir, target_dir, synced: false, expected_targets: nil
        SyncOps.sync_directory(source_dir, target_dir, synced: synced, expected_targets: expected_targets)
      end

      def sync_scripts
        SyncOps.sync_scripts(self)
      end

      def sync_vale_styles local: false
        SyncOps.sync_vale_styles(self, local: local)
      end

      def sync_docs force: false
        SyncOps.sync_docs(self, force: force)
      end

      def sync_templates force: false
        SyncOps.sync_templates(self, force: force)
      end

      # Checkers & Finders

      def tool_available? tool_name
        ToolExecution.tool_available?(tool_name)
      end

      def docker_available?
        ToolExecution.docker_available?
      end

      def image_available?
        ToolExecution.image_available?
      end

      def lab_dev_mode?
        Checkers.lab_dev_mode?
      end

      def gem_sourced_locally?
        Checkers.gem_sourced_locally?
      end

      def check_ruby_version
        Checkers.check_ruby_version
      end

      def check_config_structure
        Checkers.check_config_structure(self)
      end

      def check_standard_rake_tasks
        Checkers.check_standard_rake_tasks
      end

      def find_shell_scripts
        FileUtilities.find_shell_scripts(self)
      end

      def shell_shebang? file
        FileUtilities.shell_shebang?(file)
      end

      def find_asciidoc_files
        FileUtilities.find_asciidoc_files(self)
      end

      def get_path_config tool_slug
        ConfigManager.get_path_config(tool_slug, self)
      end

      def file_matches_ignore_pattern? file, pattern
        FileUtilities.file_matches_ignore_pattern?(file, pattern)
      end

      def git_tracked_or_staged? file
        FileUtilities.git_tracked_or_staged?(file)
      end

      # Special Runtime Config Handling

      def generate_vale_config style_override: nil
        ConfigManager.generate_vale_config(self, style_override: style_override)
      end

      def generate_htmlproofer_config
        ConfigManager.generate_htmlproofer_config(self)
      end

      def load_htmlproofer_config
        ConfigManager.load_htmlproofer_config
      end

      # Run Linters

      def run_rubocop file_path=nil, opts_string=''
        Linters.run_rubocop(self, file_path, opts_string)
      end

      def run_rubocop_with_filter filter_name
        Linters.run_rubocop_with_filter(self, filter_name)
      end

      def run_shellcheck file_path=nil, opts_string=''
        Linters.run_shellcheck(self, file_path, opts_string)
      end

      def run_actionlint opts_string=''
        Linters.run_actionlint(self, opts_string)
      end

      def run_all_linters
        Linters.run_all_linters(self)
      end

      def run_auto_fix
        Linters.run_auto_fix
        AsciiidocAutoFix.fix_asciidoc_files(self)
      end

      def run_rubocop_auto_fix path: nil
        Linters.run_rubocop_auto_fix(self, path: path)
      end

      def run_adoc_auto_fix path=nil
        AutoFixAsciidoc.fix_asciidoc_files(self, path: path)
      end

      def run_linter_group group_name, linters
        Linters.run_linter_group(self, group_name, linters)
      end

      def run_vale file_path=nil, opts_string='', output_format: :cli, filter: nil, style_override: nil
        Linters.run_vale(
          self, file_path, opts_string,
          output_format: output_format, filter: filter, style_override: style_override)
      end

      def lint_file file_path
        Linters.lint_file(self, file_path)
      end

      # Show Stuff

      def show_lint_rule tool, rule
        case tool
        when 'vale'
          print_vale_style(rule)
        when 'rubocop'
          print_cop(rule)
        else
          puts "❌ Unknown or unsupported tool: #{tool}. Supported tools: vale, rubocop"
        end
      end

      def list_hook_templates
        GitHooks.list_hook_templates
      end

      def list_script_templates
        ScriptManager.list_script_templates
      end

      private

      def print_vale_style rule
        puts "📄 Vale rule documentation for: #{rule}"
        package = rule.split('.').first
        rule_name = rule.split('.').last
        style_path = File.join('.config', '.vendor', 'vale', 'styles', package, "#{rule_name}.yml")
        unless File.exist?(style_path)
          puts "❌ Vale rule file not found: #{style_path}"
          return
        end
        config = File.read(Paths::CONFIG_FILES[:vale])
        config.lines.each do |line|
          next unless line.strip.start_with?("#{package}.#{rule_name} =")

          rule_setting = line.strip.split('=', 2).last.strip
          puts "⚙️  Rule setting from #{Paths::CONFIG_FILES[:vale]}: '#{rule_setting}'"
          break
        end
        unless File.exist?(style_path)
          puts "❌ Failed to retrieve style definition from #{style_path}"
          return
        end
        puts '---'
        puts File.read(style_path)
        puts ''
      end

      def print_cop rule
        puts "📄 RuboCop cop documentation for: #{rule}"
        cmd = "bundle exec rubocop --show-cops #{rule} --config #{File.join(Paths.config_vendor_dir, 'rubocop.yml')}"
        success = system(cmd)
        puts '❌ Failed to retrieve RuboCop cop documentation' unless success
      end

      def find_files_to_lint tool_slug
        FileUtilities.find_files_to_lint(tool_slug, self)
      end
    end
  end
end

# Auto-load tasks when required
DocOpsLab::Dev::Tasks.new if defined?(Rake)
