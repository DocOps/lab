# frozen_string_literal: true

require 'digest'
require 'json'
require 'shellwords'
require 'tmpdir'
require_relative 'manifest'
require_relative 'library/cache'
require_relative 'library/fetch'

module DocOpsLab
  module Dev
    # Remote library fetch, cache, and resolution.
    # Manages a host-wide asset cache at ~/.cache/docopslab/dev/library/.
    # Callers should use this module directly: Library.fetch!, Library.resolve(path), etc.
    module Library
      class << self
        def fetch! config=nil
          config ||= library_config_from_manifest
          with_cache_root(config) { Fetch.call(config) }
        end

        # Fetch the library if the cache is absent or stale, then sync all
        # manifest-driven content (docs, config files, templates, scripts) to
        # local paths. This is the main entry point for `labdev:sync:library`.
        def sync! force: false
          config = library_config_from_manifest
          with_cache_root(config) do
            if local_path_active?(config)
              puts "📚 Using local library at #{File.expand_path(config['local_path'])}"
            elsif !force && Cache.available? && sha_current?(config)
              puts "\u2705 Library cache is up to date (#{Cache.stored_head&.slice(0, 8)})"
            else
              puts Cache.available? ? '🔄 Library has updates; refreshing...' : '📥 Library cache not found; fetching...'
              ok = Fetch.call(config)
              unless ok
                warn '⚠️  Library fetch failed. Using existing cache if available.'
                raise 'Library unavailable.' unless available?
              end
            end

            context = Dev
            SyncOps.sync_config_files(context)
            SyncOps.sync_docs(context, force: force)
            SyncOps.sync_templates(context, force: force)
            SyncOps.sync_scripts(context)
          end
        end

        # Copy a local library directory into the host cache and sync content to
        # manifest-configured paths. Intended for development workflows where
        # assets live in the +lab+ monorepo (.library/ or library/current/) and
        # have not yet been published to the remote branch.
        #
        # Resolution order for +source_path+:
        #   1. Explicit argument (task arg or direct call)
        #   2. manifest +library.local_path+ (resolved relative to cwd)
        #   3. .library/ in the current working directory
        #   4. ../lab/.library/ relative to cwd (downstream-project fallback)
        #
        # A minimal catalog.json is generated into a staging copy if the source
        # directory does not already contain one.
        def stage! source_path: nil
          resolved = resolve_stage_source(source_path)
          unless resolved
            warn '⚠️  No local library path found. ' \
                 "Pass a path, or set library.local_path in #{Dev::MANIFEST_PATH}."
            return false
          end

          puts "📦 Staging local library from #{resolved}..."

          Dir.mktmpdir('docopslab-stage-') do |tmpdir|
            dest = File.join(tmpdir, 'stage')
            FileUtils.cp_r(resolved, dest)
            ensure_catalog!(dest)
            Cache.write!(dest)
          end

          puts "✅ Local library staged to #{Cache.current_path}"

          context = Dev
          SyncOps.sync_config_files(context)
          SyncOps.sync_docs(context, force: true)
          SyncOps.sync_templates(context, force: true)
          SyncOps.sync_scripts(context)
          true
        rescue StandardError => e
          warn "⚠️  Stage failed: #{e.message}"
          false
        end

        def cached_path
          Cache.current_path
        end

        # Returns the effective library root directory (nil if unavailable).
        # Does not auto-fetch; call ensure_available! first if needed.
        # Resolution order mirrors resolve():
        #   1. XDG host cache  2. local_path from manifest
        def root
          return Cache.current_path if Cache.available?

          lp = Dev.load_manifest&.dig('library', 'local_path')
          return File.expand_path(lp) if lp && File.exist?(File.join(lp, 'catalog.json'))

          nil
        end

        # Returns the absolute path to a cached file, or nil if absent.
        # Resolution order:
        #   1. XDG host cache (~/.cache/docopslab/dev/library/current/)
        #   2. local_path from manifest (dev/monorepo fallback, e.g. .library/)
        def resolve relative_path
          if Cache.available?
            full_path = File.join(Cache.current_path, relative_path)
            return full_path if File.exist?(full_path)
          end

          # local_path fallback for monorepo dev and offline use
          lp = Dev.load_manifest&.dig('library', 'local_path')
          if lp
            local_full = File.expand_path(File.join(lp, relative_path))
            return local_full if File.exist?(local_full)
          end

          nil
        end

        # True if a library is available via cache or local_path fallback.
        def available?
          return true if Cache.available?

          lp = Dev.load_manifest&.dig('library', 'local_path')
          !!(lp && File.exist?(File.join(lp, 'catalog.json')))
        end

        # Ensure the library is available, auto-fetching if necessary.
        # Returns true if available after the call; raises on failure.
        def ensure_available!
          return true if available?

          puts '📥 Library cache not found; fetching now...'
          ok = fetch!
          return true if ok && available?

          lp = Dev.load_manifest&.dig('library', 'local_path')
          if lp && Dir.exist?(lp)
            warn "⚠️  Remote fetch failed; using local_path fallback: #{lp}"
            return true
          end

          raise 'Library unavailable. Run `bundle exec rake labdev:sync:library` to fetch it.'
        end

        def status
          Cache.status
        end

        def rollback!
          if Cache.rollback!
            puts "✅ Library rolled back to previous snapshot at #{Cache.current_path}"
            true
          else
            warn '⚠️  No previous library snapshot available for rollback.'
            false
          end
        end

        def print_status
          s = status
          if s[:available]
            puts "📚 Library cache: #{s[:cache_path]}"
            puts "   Version    : #{s[:version] || '(unknown)'}"
            puts "   Ref        : #{s[:ref] || '(unknown)'}"
            puts "   Generated  : #{s[:generated_at] || '(unknown)'}"
            puts "   Previous   : #{s[:has_previous] ? 'yes' : 'none'}"
          else
            puts "⚠️  No library cache found at #{s[:cache_path]}"
            lp = Dev.load_manifest&.dig('library', 'local_path')
            if lp && File.exist?(File.join(lp, 'catalog.json'))
              puts "   Local path : #{File.expand_path(lp)} (active fallback)"
            else
              puts '   Run `bundle exec rake labdev:sync:library` to fetch.'
            end
          end
        end

        # Compare manifest catalog entries against the cached library files
        # Falls back to an on-repo local path if provided in the manifest
        def print_catalog_comparison manifest = nil
          manifest ||= Dev.load_manifest
          lib_cfg = manifest && manifest['library']

          if lib_cfg.nil? || lib_cfg.empty?
            puts "ℹ️  No `library` block found in #{Dev.manifest_path} (or it's empty)."
            return
          end

          catalog = lib_cfg.dig('catalog', 'overrides') || lib_cfg['catalog'] || lib_cfg['catalog_overrides']

          unless catalog && !catalog.empty?
            puts 'ℹ️  No catalog overrides found in manifest.library.catalog; nothing to compare.'
            return
          end

          puts '🔎 Comparing manifest catalog entries to cached library files...'

          entries = []
          case catalog
          when Array
            entries = catalog
          when Hash
            catalog.each do |k, v|
              entries << if v.is_a?(String)
                           v
                         elsif v.is_a?(Hash) && v['path']
                           v['path']
                         else
                           k
                         end
            end
          else
            puts "⚠️  Unrecognized catalog format: #{catalog.class}. Skipping detailed compare."
            return
          end

          missing = []
          present = []

          entries.each do |rel_path|
            rel = rel_path.to_s.sub(%r{^/}, '')
            resolved = resolve(rel)

            # Fallback to on-repo local path if provided
            if resolved.nil? && lib_cfg['local_path']
              repo_local = File.join(Dir.pwd, lib_cfg['local_path'].to_s, rel)
              resolved = File.exist?(repo_local) ? repo_local : nil
            end

            if resolved
              present << { path: rel, full: resolved }
            else
              missing << rel
            end
          end

          if present.any?
            puts "✅ Found #{present.size} catalog entries in the cache or local path:"
            present.each do |p|
              puts "  - #{p[:path]} -> #{p[:full]}"
            end
          end

          if missing.any?
            puts "❌ Missing #{missing.size} catalog entries in the cache/local path:"
            missing.each do |m|
              puts "  - #{m}"
            end
          else
            puts '✅ All catalog entries present in cache/local path.'
          end
        end

        private

        def sha_current? config
          remote = Fetch.remote_head(config)
          return Cache.fresh? unless remote # network unavailable; fall back to TTL

          Cache.stored_head == remote
        end

        # True when local_path is configured and its catalog is present on disk.
        # When active, sync! uses the local directory directly and skips the
        # remote SHA check; the caller (library maintainer) manages it locally.
        def local_path_active? config
          lp = config['local_path']
          lp && File.exist?(File.join(File.expand_path(lp), 'catalog.json'))
        end

        def with_cache_root(config, &)
          cr = config.dig('sync', 'cache_root')
          # Auto-derive from local_path when no explicit cache_root is set.
          # local_path points to the 'current' snapshot dir, so its parent is
          # the cache root (mirrors Cache::XDG_CACHE_SUBPATH layout).
          cr = File.join(File.expand_path(config['local_path']), '..') if cr.nil? && local_path_active?(config)
          Cache.with_root_override(cr ? File.expand_path(cr) : nil, &)
        end

        def library_config_from_manifest
          Dev.load_manifest&.dig('library') || {}
        end

        # Resolve the source directory for stage! using the priority chain:
        #   explicit arg → manifest local_path → .library/ in cwd → ../lab/.library/
        def resolve_stage_source explicit_path
          candidates = []
          candidates << File.expand_path(explicit_path) if explicit_path

          lp = library_config_from_manifest['local_path']
          candidates << File.expand_path(lp) if lp

          candidates << File.join(Dir.pwd, '.library')
          candidates << File.expand_path(File.join(Dir.pwd, '..', 'lab', '.library'))

          candidates.find { |p| Dir.exist?(p) }
        end

        # Write a minimal catalog.json into +dir+ if one is not already present.
        def ensure_catalog! dir
          catalog_file = File.join(dir, 'catalog.json')
          return if File.exist?(catalog_file)

          files = Dir.glob("#{dir}/**/*").reject { |f| File.directory?(f) }
                     .map { |f| f.delete_prefix("#{dir}/") }
          catalog = {
            'library_version' => 'local',
            'library_ref'     => 'local-stage',
            'generated_at'    => Time.now.utc.iso8601,
            'files'           => files
          }
          File.write(catalog_file, JSON.generate(catalog))
        end
      end
    end
  end
end
