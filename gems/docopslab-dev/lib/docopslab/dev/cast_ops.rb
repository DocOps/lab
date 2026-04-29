# frozen_string_literal: true

require 'yaml'
require 'sourcerer/sync'

module DocOpsLab
  module Dev
    # Sync/Cast operations: synchronize canonical blocks from prime templates
    # into project-local target files using Sourcerer::Sync.
    #
    # Prime templates define canonical (universal-prefixed) blocks.
    # Target files receive those blocks on each sync, preserving all local content.
    # On first-time init the whole prime is rendered and written as the new target.
    #
    # Configuration is driven by <tt>templates:</tt> in the project manifest.
    # The list of template-to-target procedures lives under <tt>templates.manifest</tt>.
    module CastOps
      class << self
        # Sync canonical blocks from prime templates into all configured target files.
        #
        # @param context [DocOpsLab::Dev] caller context (for manifest access)
        # @param target_filter [String, nil] restrict to entries whose target matches
        # @param dry_run [Boolean] compute diff but do not write
        # @return [Hash{String => Sourcerer::Sync::Cast::CastResult}]
        def sync_cast_targets context, target_filter: nil, dry_run: false
          castings, global_data = load_castings(context, target_filter)
          return {} unless castings

          label = dry_run ? '🔍 Dry-run: diffing cast targets...' : '🔄 Syncing cast targets...'
          puts label

          results = {}
          castings.each do |entry|
            prime_path = resolve_prime(entry)
            next unless prime_path

            target_path = entry['target']

            unless File.exist?(target_path)
              puts "  ⚠️  Target not found: #{target_path} (run labdev:init:templates to bootstrap)"
              next
            end

            data             = build_data(global_data, entry)
            canonical_prefix = entry.fetch('canonical_prefix', 'universal-')

            result = Sourcerer::Sync.sync(
              prime_path,
              target_path,
              data: data,
              canonical_prefix: canonical_prefix,
              dry_run: dry_run)

            results[target_path] = result
            report_result(result, dry_run: dry_run)
          end

          puts "✅ Synced #{results.count { |_, r| r.applied_changes.any? }} cast target(s)" unless dry_run
          results
        end

        # Bootstrap new target files from prime templates.
        # Skips targets that already exist (use sync to update those).
        #
        # @param context [DocOpsLab::Dev] caller context
        # @param target_filter [String, nil] restrict to entries whose target matches
        # @return [Hash{String => Sourcerer::Sync::Cast::CastResult}]
        def init_cast_targets context, target_filter: nil
          castings, global_data = load_castings(context, target_filter)
          return {} unless castings

          puts '🆕 Initializing cast targets...'

          results = {}
          castings.each do |entry|
            prime_path = resolve_prime(entry)
            next unless prime_path

            target_path = entry['target']

            if File.exist?(target_path)
              puts "  ⏭️  Skipped #{target_path} (already exists; use labdev:sync:templates to update)"
              next
            end

            data   = build_data(global_data, entry)
            result = Sourcerer::Sync.init(prime_path, target_path, data: data)

            results[target_path] = result
            report_result(result, init: true)
          end

          puts "✅ Initialized #{results.size} cast target(s)"
          results
        end

        private

        # Returns [entries_array, global_data_hash] from the manifest.
        # When target_filter is given, entries is restricted to that single entry.
        def load_castings context, target_filter
          manifest = context.load_manifest
          unless manifest
            puts "❌ No manifest found at #{MANIFEST_PATH}"
            return nil
          end

          templates_cfg = manifest['templates']
          unless templates_cfg.is_a?(Hash)
            puts '⚠️  No templates section configured in manifest'
            return nil
          end

          castings = templates_cfg['manifest']
          unless castings.is_a?(Array) && castings.any?
            puts '⚠️  No entries configured under templates.manifest:'
            return nil
          end

          global_data = templates_cfg['data'] || {}

          if target_filter
            castings = castings.select { |e| e['target'] == target_filter }
            if castings.empty?
              puts "❌ No casting matched target: #{target_filter}"
              return nil
            end
          end

          [castings, global_data]
        end

        # Build the Liquid data hash for a casting.
        #
        # All template variables live under the top-level +data+ key:
        #   data.project.attributes  — document attributes from README.adoc
        #   data.variables.<key>     — merged manifest variables (global + per-entry)
        #
        # Precedence: data.project.attributes < global variables < per-entry variables
        def build_data global_data, entry
          inner = { 'project' => { 'attributes' => DataUtils.project_attributes } }

          vars = {}
          vars.merge!(global_data['variables'] || {})

          casting_data = entry['data'] || {}
          vars.merge!(casting_data['variables'] || {})

          inner['variables'] = vars
          { 'data' => inner }
        end

        # Resolve the prime template path from a casting entry.
        # Uses 'source' key for library-relative paths.
        def resolve_prime entry
          if entry['source']
            lib_root = Library.root
            unless lib_root
              puts '  ❌ Library not available; run labdev:sync:library to fetch.'
              return nil
            end
            path = File.join(lib_root, entry['source'])
            return path if File.exist?(path)

            puts "  ❌ Library source not found: #{entry['source']} (run labdev:sync:library)"
          else
            puts "  ❌ Entry for '#{entry['target']}' has no 'source' key"
          end
          nil
        end

        def report_result result, dry_run: false, init: false
          target = result.target_path

          result.errors.each   { |e| puts "  ❌ #{target}: #{e}" }
          result.warnings.each { |w| puts "  ⚠️  #{target}: #{w}" }

          return if result.errors.any?

          if init
            puts "  ✅ Initialized #{target}"
          elsif dry_run
            if result.diff && !result.diff.empty?
              puts "  📋 #{target}: differences found"
              result.diff.lines.first(10).each { |l| print "     #{l}" }
              puts ''
            else
              puts "  ✓  #{target}: up to date"
            end
          elsif result.applied_changes.any?
            puts "  ✅ #{target}: updated blocks: #{result.applied_changes.join(', ')}"
          else
            puts "  ✓  #{target}: up to date"
          end
        end
      end
    end
  end
end
