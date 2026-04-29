# frozen_string_literal: true

require 'rspec'
require_relative 'spec_helper'

# Minimal stubs for gem-level dependencies cast_ops.rb needs at load time.
module Sourcerer
  module Sync
    CastResult = Struct.new(:target_path, :applied_changes, :errors, :warnings, :diff)
    def self.sync(_src, tgt, **) = CastResult.new(tgt, [], [], [], nil)
    def self.init(_src, tgt, **) = CastResult.new(tgt, ['initialized'], [], [], nil)
  end
end

module DocOpsLab
  module Dev
    def self.load_manifest(**) = nil
  end
end

require_relative '../../../lib/docopslab/dev/library/cache'
require_relative '../../../lib/docopslab/dev/library/fetch'
require_relative '../../../lib/docopslab/dev/library'
require_relative '../../../lib/docopslab/dev/data_utils'
require_relative '../../../lib/docopslab/dev/cast_ops'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Runs block inside a fresh project tmpdir backed by a temporary XDG cache.
# +seed: true+ writes the library fixture into the cache before yielding.
def in_tmp_project seed: false, &block
  Dir.mktmpdir('docopslab-cast-test-') do |tmpdir|
    original = ENV.fetch('XDG_CACHE_HOME', nil)
    ENV['XDG_CACHE_HOME'] = tmpdir
    DocOpsLab::Dev::Library::Cache.write!(LIBRARY_FIXTURE) if seed
    begin
      Dir.mktmpdir('docopslab-proj-') do |proj|
        Dir.chdir(proj, &block)
      end
    ensure
      ENV['XDG_CACHE_HOME'] = original.nil? ? ENV.delete('XDG_CACHE_HOME') : original
    end
  end
end

def templates_manifest *entries, global_vars: {}
  data_node = global_vars.any? ? { 'variables' => global_vars } : {}
  { 'templates' => { 'data' => data_node, 'manifest' => entries } }
end

def fake_context manifest_hash
  class_double(DocOpsLab::Dev, load_manifest: manifest_hash)
end

def cast_result tgt, changes = []
  Sourcerer::Sync::CastResult.new(tgt, changes, [], [], nil)
end

# ---------------------------------------------------------------------------
RSpec.describe DocOpsLab::Dev::CastOps do
  subject(:ops) { described_class }

  let(:agents_entry) { { 'source' => 'templates/AGENTS.markdown', 'target' => 'AGENTS.md' } }
  let(:readme_entry) { { 'source' => 'templates/README.asciidoc', 'target' => 'README.adoc' } }

  before { DocOpsLab::Dev::DataUtils.reset_project_attributes! }

  # -------------------------------------------------------------------------
  describe '.build_data (via public interface)' do
    # Exercised indirectly: init_cast_targets passes the result to Sourcerer::Sync.init.

    it 'always includes data.project.attributes key' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        expect(Sourcerer::Sync).to receive(:init) do |_src, _tgt, **opts|
          expect(opts[:data]['data']).to have_key('project')
          expect(opts[:data]['data']['project']).to have_key('attributes')
          cast_result('AGENTS.md', ['initialized'])
        end
        ops.init_cast_targets(ctx)
      end
    end

    it 'includes global variables in data.variables' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry, global_vars: { 'org' => 'DocOpsLab' }))
        expect(Sourcerer::Sync).to receive(:init) do |_src, _tgt, **opts|
          expect(opts[:data]['data']['variables']).to include('org' => 'DocOpsLab')
          cast_result('AGENTS.md', ['initialized'])
        end
        ops.init_cast_targets(ctx)
      end
    end

    it 'merges per-entry variables on top of global variables' do
      in_tmp_project(seed: true) do
        entry = agents_entry.merge('data' => { 'variables' => { 'org' => 'Override', 'extra' => 'yes' } })
        ctx   = fake_context(templates_manifest(entry, global_vars: { 'org' => 'DocOpsLab', 'shared' => 'x' }))
        expect(Sourcerer::Sync).to receive(:init) do |_src, _tgt, **opts|
          vars = opts[:data]['data']['variables']
          expect(vars).to include('org' => 'Override', 'shared' => 'x', 'extra' => 'yes')
          cast_result('AGENTS.md', ['initialized'])
        end
        ops.init_cast_targets(ctx)
      end
    end
  end

  # -------------------------------------------------------------------------
  describe '.load_castings (via public interface)' do
    it 'returns {} when manifest is nil' do
      ctx = fake_context(nil)
      expect(ops.sync_cast_targets(ctx)).to eq({})
      expect(ops.init_cast_targets(ctx)).to eq({})
    end

    it 'returns {} when templates key is missing' do
      expect(ops.sync_cast_targets(fake_context({ 'tools' => [] }))).to eq({})
    end

    it 'returns {} when templates.manifest is absent' do
      expect(ops.sync_cast_targets(fake_context({ 'templates' => { 'data' => {} } }))).to eq({})
    end

    it 'returns {} when templates.manifest is empty' do
      expect(ops.sync_cast_targets(fake_context({ 'templates' => { 'manifest' => [] } }))).to eq({})
    end

    it 'filters entries when target_filter is given' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry, readme_entry))
        expect(Sourcerer::Sync).to receive(:init).once do |_src, tgt, **|
          expect(tgt).to eq('README.adoc')
          cast_result(tgt, ['initialized'])
        end
        ops.init_cast_targets(ctx, target_filter: 'README.adoc')
      end
    end

    it 'returns {} when target_filter matches nothing' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        expect(ops.init_cast_targets(ctx, target_filter: 'nonexistent.txt')).to eq({})
      end
    end
  end

  # -------------------------------------------------------------------------
  describe '.resolve_prime (via public interface)' do
    it 'skips an entry with no source key' do
      in_tmp_project do
        ctx = fake_context(templates_manifest({ 'target' => 'AGENTS.md' }))
        expect(Sourcerer::Sync).not_to receive(:init)
        ops.init_cast_targets(ctx)
      end
    end

    it 'skips an entry when library is unavailable' do
      in_tmp_project(seed: false) do
        ctx = fake_context(templates_manifest(agents_entry))
        expect(Sourcerer::Sync).not_to receive(:init)
        ops.init_cast_targets(ctx)
      end
    end

    it 'skips an entry when source path does not exist in the library' do
      in_tmp_project(seed: true) do
        entry = { 'source' => 'templates/no-such-file.adoc', 'target' => 'target.adoc' }
        ctx   = fake_context(templates_manifest(entry))
        expect(Sourcerer::Sync).not_to receive(:init)
        ops.init_cast_targets(ctx)
      end
    end

    it 'resolves a source path that exists in the library' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        expect(Sourcerer::Sync).to receive(:init) do |src, _tgt, **|
          expect(File.exist?(src)).to be true
          cast_result('AGENTS.md', ['initialized'])
        end
        ops.init_cast_targets(ctx)
      end
    end
  end

  # -------------------------------------------------------------------------
  describe '.init_cast_targets' do
    it 'initializes a missing target' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        expect(ops.init_cast_targets(ctx)).to have_key('AGENTS.md')
      end
    end

    it 'skips a target that already exists' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        File.write('AGENTS.md', 'existing')
        expect(Sourcerer::Sync).not_to receive(:init)
        expect(ops.init_cast_targets(ctx)).to be_empty
      end
    end

    it 'initializes multiple entries' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry, readme_entry))
        expect(ops.init_cast_targets(ctx).keys).to contain_exactly('AGENTS.md', 'README.adoc')
      end
    end

    it 'passes canonical_prefix from the entry (whole-doc render; init still runs)' do
      in_tmp_project(seed: true) do
        entry = agents_entry.merge('canonical_prefix' => 'project-')
        ctx   = fake_context(templates_manifest(entry))
        expect(ops.init_cast_targets(ctx)).to have_key('AGENTS.md')
      end
    end
  end

  # -------------------------------------------------------------------------
  describe '.sync_cast_targets' do
    it 'skips an entry whose target does not exist' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        expect(Sourcerer::Sync).not_to receive(:sync)
        ops.sync_cast_targets(ctx)
      end
    end

    it 'calls Sourcerer::Sync.sync for an existing target' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        File.write('AGENTS.md', 'existing')
        expect(Sourcerer::Sync).to receive(:sync) do |src, tgt, **|
          expect(File.exist?(src)).to be true
          expect(tgt).to eq('AGENTS.md')
          cast_result(tgt)
        end
        ops.sync_cast_targets(ctx)
      end
    end

    it 'forwards dry_run: true to Sourcerer::Sync.sync' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        File.write('AGENTS.md', 'existing')
        expect(Sourcerer::Sync).to receive(:sync) do |_src, _tgt, **opts|
          expect(opts[:dry_run]).to be true
          cast_result('AGENTS.md')
        end
        ops.sync_cast_targets(ctx, dry_run: true)
      end
    end

    it 'forwards canonical_prefix from the entry to Sourcerer::Sync.sync' do
      in_tmp_project(seed: true) do
        entry = agents_entry.merge('canonical_prefix' => 'project-')
        ctx   = fake_context(templates_manifest(entry))
        File.write('AGENTS.md', 'existing')
        expect(Sourcerer::Sync).to receive(:sync) do |_src, _tgt, **opts|
          expect(opts[:canonical_prefix]).to eq('project-')
          cast_result('AGENTS.md')
        end
        ops.sync_cast_targets(ctx)
      end
    end

    it 'returns results keyed by target path' do
      in_tmp_project(seed: true) do
        ctx = fake_context(templates_manifest(agents_entry))
        File.write('AGENTS.md', 'existing')
        expect(ops.sync_cast_targets(ctx)).to have_key('AGENTS.md')
      end
    end
  end
end
