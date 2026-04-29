# frozen_string_literal: true

require 'rspec'
require_relative 'spec_helper'

# Load library module under test without loading the full gem stack
# (avoids Rake dependency and other gem-level setup).
module DocOpsLab
  module Dev
    def self.load_manifest(**) = nil
  end
end

require_relative '../../../lib/docopslab/dev/manifest'
require_relative '../../../lib/docopslab/dev/library/cache'
require_relative '../../../lib/docopslab/dev/library/fetch'
require_relative '../../../lib/docopslab/dev/library'

# Redirect the XDG cache to a tmp dir for the duration of a block.
# Restores the original value (or removes the key) afterwards.
def with_tmp_cache
  Dir.mktmpdir('docopslab-cache-test-') do |tmpdir|
    original = ENV.fetch('XDG_CACHE_HOME', nil)
    ENV['XDG_CACHE_HOME'] = tmpdir
    begin
      yield tmpdir
    ensure
      if original.nil?
        ENV.delete('XDG_CACHE_HOME')
      else
        ENV['XDG_CACHE_HOME'] = original
      end
    end
  end
end

RSpec.describe DocOpsLab::Dev::Library do
  # -------------------------------------------------------------------------
  describe DocOpsLab::Dev::Manifest do
    subject(:manifest) { described_class }

    describe '.load' do
      it 'returns a hash for a valid YAML file' do
        Dir.mktmpdir do |dir|
          path = File.join(dir, 'docopslab-dev.yml')
          File.write(path, "tools:\n  - tool: rubocop\n")
          expect(manifest.load(path)).to be_a(Hash)
        end
      end

      it 'returns nil for a missing file' do
        expect(manifest.load('/no/such/file.yml')).to be_nil
      end

      it 'returns nil for invalid YAML' do
        Dir.mktmpdir do |dir|
          bad = File.join(dir, 'bad.yml')
          File.write(bad, ":\n  invalid: [\n")
          expect(manifest.load(bad)).to be_nil
        end
      end
    end

    describe '.valid?' do
      it 'returns true for a non-empty hash' do
        expect(manifest.valid?({ 'tools' => [] })).to be true
      end

      it 'returns false for an empty hash' do
        expect(manifest.valid?({})).to be false
      end

      it 'returns false for nil' do
        expect(manifest.valid?(nil)).to be false
      end
    end
  end

  # -------------------------------------------------------------------------
  describe DocOpsLab::Dev::Library::Cache do
    subject(:cache) { described_class }

    describe '.root' do
      it 'uses XDG_CACHE_HOME when set' do
        with_tmp_cache do |tmpdir|
          expect(cache.root).to eq(File.join(tmpdir, 'docopslab/dev/library'))
        end
      end

      it 'defaults to ~/.cache when XDG_CACHE_HOME is unset' do
        original = ENV.delete('XDG_CACHE_HOME')
        begin
          expect(cache.root).to eq(File.join(Dir.home, '.cache/docopslab/dev/library'))
        ensure
          ENV['XDG_CACHE_HOME'] = original if original
        end
      end
    end

    describe '.available?' do
      it 'returns false when current/ has no manifest' do
        with_tmp_cache { expect(cache.available?).to be false }
      end

      it 'returns true when a valid manifest is present' do
        with_tmp_cache do
          cache.write!(LIBRARY_FIXTURE)
          expect(cache.available?).to be true
        end
      end
    end

    describe '.catalog' do
      it 'returns nil when unavailable' do
        with_tmp_cache { expect(cache.catalog).to be_nil }
      end

      it 'returns parsed catalog data when available' do
        with_tmp_cache do
          cache.write!(LIBRARY_FIXTURE)
          expect(cache.catalog).to include('library_version')
        end
      end
    end

    describe '.write!' do
      it 'copies source dir to current_path' do
        with_tmp_cache do
          cache.write!(LIBRARY_FIXTURE)
          expect(File.exist?(cache.catalog_path)).to be true
        end
      end

      it 'raises ArgumentError for a missing source' do
        with_tmp_cache do
          expect { cache.write!('/no/such/dir') }.to raise_error(ArgumentError, /not found/)
        end
      end
    end

    describe '.rotate!' do
      it 'returns false when current/ does not exist' do
        with_tmp_cache { expect(cache.rotate!).to be false }
      end

      it 'moves current/ to previous/' do
        with_tmp_cache do
          cache.write!(LIBRARY_FIXTURE)
          cache.rotate!
          expect(Dir.exist?(cache.previous_path)).to be true
          expect(Dir.exist?(cache.current_path)).to be false
        end
      end
    end

    describe '.rollback!' do
      it 'returns false when previous/ does not exist' do
        with_tmp_cache { expect(cache.rollback!).to be false }
      end

      it 'moves previous/ back to current/' do
        with_tmp_cache do
          cache.write!(LIBRARY_FIXTURE)  # create current/
          cache.rotate!                  # move current/ → previous/
          cache.rollback!                # move previous/ → current/
          expect(cache.available?).to be true
          expect(Dir.exist?(cache.previous_path)).to be false
        end
      end
    end

    describe '.status' do
      it 'returns available: false when no cache is present' do
        with_tmp_cache { expect(cache.status[:available]).to be false }
      end

      it 'returns status data when cache is present' do
        with_tmp_cache do
          cache.write!(LIBRARY_FIXTURE)
          s = cache.status
          expect(s[:available]).to be true
          expect(s[:version]).not_to be_nil
          expect(s[:cache_path]).to eq(cache.current_path)
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  describe DocOpsLab::Dev::Library do
    subject(:library) { described_class }

    describe '.available?' do
      it 'returns false when cache is empty' do
        with_tmp_cache { expect(library.available?).to be false }
      end

      it 'returns true after cache is populated' do
        with_tmp_cache do
          DocOpsLab::Dev::Library::Cache.write!(LIBRARY_FIXTURE)
          expect(library.available?).to be true
        end
      end

      it 'returns true when local_path points to a valid library directory' do
        with_tmp_cache do
          allow(DocOpsLab::Dev).to receive(:load_manifest)
            .and_return({ 'library' => { 'local_path' => LIBRARY_FIXTURE } })
          expect(library.available?).to be true
        end
      end
    end

    describe '.resolve' do
      it 'returns nil when cache is unavailable and no local_path' do
        with_tmp_cache { expect(library.resolve('templates/README.asciidoc')).to be_nil }
      end

      it 'returns an absolute path for an existing library file from cache' do
        with_tmp_cache do
          DocOpsLab::Dev::Library::Cache.write!(LIBRARY_FIXTURE)
          result = library.resolve('templates/README.asciidoc')
          expect(result).not_to be_nil
          expect(File.exist?(result)).to be true
        end
      end

      it 'falls back to local_path when cache is absent' do
        with_tmp_cache do
          allow(DocOpsLab::Dev).to receive(:load_manifest)
            .and_return({ 'library' => { 'local_path' => LIBRARY_FIXTURE } })
          result = library.resolve('templates/README.asciidoc')
          expect(result).not_to be_nil
          expect(result).to include(LIBRARY_FIXTURE)
        end
      end

      it 'returns nil for a path not present in the cache' do
        with_tmp_cache do
          DocOpsLab::Dev::Library::Cache.write!(LIBRARY_FIXTURE)
          expect(library.resolve('no/such/file.txt')).to be_nil
        end
      end
    end

    describe '.status' do
      it 'returns a hash with :available key' do
        with_tmp_cache { expect(library.status).to include(:available) }
      end
    end

    describe '.ensure_available!' do
      it 'returns true immediately when cache is already populated' do
        with_tmp_cache do
          DocOpsLab::Dev::Library::Cache.write!(LIBRARY_FIXTURE)
          expect(library.ensure_available!).to be true
        end
      end

      it 'returns true when local_path exists and fetch fails' do
        with_tmp_cache do
          allow(DocOpsLab::Dev).to receive(:load_manifest)
            .and_return({ 'library' => { 'local_path' => LIBRARY_FIXTURE } })
          # No cache present; local_path provides fallback
          expect(library.ensure_available!).to be true
        end
      end

      it 'raises when unavailable and fetch fails and no local_path' do
        with_tmp_cache do
          allow(DocOpsLab::Dev::Library::Fetch).to receive(:call).and_return(false)
          expect { library.ensure_available! }.to raise_error(RuntimeError, /labdev:sync:library/)
        end
      end
    end

    describe '.rollback!' do
      it 'returns false when no previous snapshot exists' do
        with_tmp_cache { expect(library.rollback!).to be false }
      end

      it 'restores the previous snapshot' do
        with_tmp_cache do
          DocOpsLab::Dev::Library::Cache.write!(LIBRARY_FIXTURE) # create current/
          DocOpsLab::Dev::Library::Cache.rotate!                 # move to previous/
          library.rollback!
          expect(library.available?).to be true
        end
      end
    end
  end

  # -------------------------------------------------------------------------
  describe DocOpsLab::Dev::Library::Fetch do
    let(:fetch) { described_class }

    describe '.gh_available?' do
      it 'returns a boolean' do
        expect(fetch.gh_available?).to be(true).or be(false)
      end
    end

    describe '.git_available?' do
      it 'returns a boolean' do
        expect(fetch.git_available?).to be(true).or be(false)
      end
    end

    describe '.call' do
      context 'when no CLI tool is available' do
        before do
          allow(fetch).to receive_messages(gh_available?: false, git_available?: false)
        end

        it 'returns false without touching the cache' do
          expect(fetch.call({})).to be false
        end
      end

      context 'when git is available but clone fails' do
        before do
          allow(fetch).to receive_messages(gh_available?: false, git_available?: true, system: false)
        end

        it 'returns false' do
          expect(fetch.call({})).to be false
        end
      end
    end
  end
end
