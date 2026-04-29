# frozen_string_literal: true

# Handles staging, catalog generation, and local cache loading for the
#  docopslab-dev library.
# Reads the declarative source map from +INDEX_PATH+
#  (gems/docopslab-dev/specs/data/library-index.yml).
#
# Consumed by the `gemdo:push:library:*`` Rake tasks in Rakefile.
# Source entries may be a directory (copied with cp_r) or a single file
#  (copied to the exact +dest+ path).
# Set `enabled: false` on an entry to skip it without removing it from the index.

require 'digest'
require 'fileutils'
require 'json'
require 'pathname'
require 'time'
require 'yaml'

module LibraryManager
  INDEX_PATH   = 'gems/docopslab-dev/specs/data/library-index.yml'
  STAGE_DIR    = '.library'
  CATALOG_FILE = 'catalog.json'

  class << self
    # Remove and recreate +STAGE_DIR+, then copy every enabled index entry into it.
    # Handles both directory sources (cp_r) and single-file sources (cp).
    # Assumes all prebuild tasks have already been run.
    def stage!
      index = load_index
      puts "📦 Staging library assets into #{STAGE_DIR}/..."
      FileUtils.rm_rf(STAGE_DIR)
      FileUtils.mkdir_p(STAGE_DIR)

      index['categories'].each do |entry|
        next if entry['enabled'] == false

        src  = entry['source']
        dest = File.join(STAGE_DIR, entry['dest'])

        if File.file?(src)
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(src, dest)
          puts "  ✓ #{entry['dest']}"
        elsif Dir.exist?(src)
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp_r(src, dest)
          puts "  ✓ #{entry['dest']}/"
        else
          puts "  ⚠️  Source not found: #{src} (skipping #{entry['dest']})"
        end
      end

      puts "✅ Library staged at #{STAGE_DIR}/"
    end

    # Write +CATALOG_FILE+ inside +STAGE_DIR+ with SHA256 checksums for every
    #  staged file.
    # Raises if +STAGE_DIR+ does not yet exist.
    def generate_catalog! version
      raise "#{STAGE_DIR}/ not found; run stage! first" unless Dir.exist?(STAGE_DIR)

      puts "📝 Generating #{CATALOG_FILE}..."

      git_ref = `git rev-parse --short HEAD 2>/dev/null`.strip
      git_ref = 'unknown' if git_ref.empty?

      files = Dir.glob("#{STAGE_DIR}/**/*", File::FNM_DOTMATCH)
                 .reject { |f| File.directory?(f) || File.basename(f).start_with?('.') }
                 .sort
                 .map do |f|
                   rel = Pathname.new(f).relative_path_from(Pathname.new(STAGE_DIR)).to_s
                   sha = Digest::SHA256.hexdigest(File.binread(f))
                   { 'path' => rel, 'sha256' => "sha256:#{sha}" }
                 end

      catalog = {
        'library_version' => version,
        'library_ref'     => "labdev-library@#{git_ref}",
        'generated_at'    => Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'files'           => files
      }

      File.write(catalog_path, "#{JSON.pretty_generate(catalog)}\n")
      puts "✅ #{CATALOG_FILE} written with #{files.size} entries"
      catalog_path
    end

    # Return unique prebuild Rake task names from the index (enabled entries only,
    #  in declaration order, deduplicated).
    def prebuild_tasks
      load_index['categories']
        .reject { |e| e['enabled'] == false }
        .map    { |e| e['prebuild'] }
        .compact
        .uniq
    end

    # Absolute path to the catalog file inside STAGE_DIR.
    def catalog_path
      File.join(STAGE_DIR, CATALOG_FILE)
    end

    # True when STAGE_DIR and its catalog file both exist.
    def staged?
      Dir.exist?(STAGE_DIR) && File.exist?(catalog_path)
    end

    private

    def load_index
      YAML.load_file(INDEX_PATH)
    end
  end
end
