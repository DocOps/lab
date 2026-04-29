# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'digest'
require_relative '../../dev'

module DocOpsLab
  module Dev
    module Library
      # Manages the host-wide library cache at ~/.cache/docopslab/dev/library/.
      #
      # Cache layout:
      #   current/    Active library used for sync and resolve operations.
      #   previous/   Previous snapshot retained for fast rollback.
      #
      # The XDG_CACHE_HOME env variable is respected; defaults to ~/.cache.
      module Cache
        class << self
          # Optional path override; set by Library.sync!/fetch! when manifest
          # specifies `library.sync.cache_root`. Cleared after the operation.
          attr_writer :root_override

          # Absolute path to the cache root (~/.cache/docopslab/dev/library/).
          # Respects +root_override+ if set, then $XDG_CACHE_HOME, then ~/.cache.
          def root
            return File.expand_path(@root_override) if @root_override

            base = ENV.fetch('XDG_CACHE_HOME', File.join(Dir.home, '.cache'))
            File.join(base, Dev.xdg_cache_subpath)
          end

          # Temporarily override the cache root for the duration of a block.
          # Restores the previous value even if the block raises.
          def with_root_override path
            previous = @root_override
            @root_override = path
            yield
          ensure
            @root_override = previous
          end

          # Absolute path to the current library snapshot.
          def current_path
            File.join(root, 'current')
          end

          # Absolute path to the previous library snapshot (rollback target).
          def previous_path
            File.join(root, 'previous')
          end

          # Absolute path to the catalog inside the current snapshot.
          def catalog_path
            File.join(current_path, 'catalog.json')
          end

          # Load and return the parsed catalog from the current snapshot.
          # Returns nil if no cache is present or the catalog is unreadable.
          def catalog
            return nil unless File.exist?(catalog_path)

            load_catalog_json(catalog_path)
          end

          # True if a current snapshot with a readable catalog is present.
          def available?
            File.exist?(catalog_path)
          end

          # The remote HEAD SHA stored from the last successful fetch, or nil.
          def stored_head
            return nil unless File.exist?(head_path)

            s = File.read(head_path).strip
            s.empty? ? nil : s
          rescue StandardError
            nil
          end

          # Persist the remote HEAD SHA alongside the cache.
          def write_head! sha
            FileUtils.mkdir_p(root)
            File.write(head_path, sha.to_s.strip)
          end

          # True if the cache exists and was generated within +max_age_hours+.
          def fresh? max_age_hours=24
            return false unless available?

            ts = catalog&.dig('generated_at')
            return false unless ts

            (Time.now.utc - Time.parse(ts)) < max_age_hours * 3600
          rescue ArgumentError
            false
          end

          # Rotate current/ to previous/, removing any prior previous/ snapshot.
          # Returns true if a rotation was performed, false if current/ was absent.
          def rotate!
            return false unless Dir.exist?(current_path)

            FileUtils.rm_rf(previous_path)
            FileUtils.mv(current_path, previous_path)
            true
          end

          # Install a directory as the new current/ snapshot.
          # Rotates any existing current/ to previous/ first.
          # source_dir must be an existing directory.
          def write! source_dir
            raise ArgumentError, "Source directory not found: #{source_dir}" unless Dir.exist?(source_dir)

            rotate! if Dir.exist?(current_path)
            FileUtils.mkdir_p(File.dirname(current_path))
            FileUtils.cp_r(source_dir, current_path)
            true
          end

          # Swap previous/ back to current/.
          # Returns false if no previous/ snapshot exists.
          def rollback!
            return false unless Dir.exist?(previous_path)

            FileUtils.rm_rf(current_path)
            FileUtils.mv(previous_path, current_path)
            true
          end

          # Return a status hash describing the current snapshot.
          def status
            if available?
              meta = catalog
              {
                available: true,
                version: meta&.dig('library_version'),
                ref: meta&.dig('library_ref'),
                generated_at: meta&.dig('generated_at'),
                cache_path: current_path,
                has_previous: Dir.exist?(previous_path)
              }
            else
              { available: false, cache_path: current_path }
            end
          end

          CATALOG_JSON_KEYS = %w[library_version library_ref generated_at files].freeze

          private

          def head_path
            File.join(root, 'remote_head')
          end

          # Parse catalog.json, returning the hash or nil on any error.
          def load_catalog_json path
            data = JSON.parse(File.read(path))
            CATALOG_JSON_KEYS.all? { |k| data.key?(k) } ? data : nil
          rescue JSON::ParserError
            nil
          end
        end
      end
    end
  end
end
