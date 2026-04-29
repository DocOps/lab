# frozen_string_literal: true

require 'rspec'
require_relative 'spec_helper'
require 'rake'
require 'rake/tasklib'
require 'yaml'

TASKS_RB_PATH       = File.join(GEM_ROOT_TEST, 'lib/docopslab/dev/tasks.rb').freeze
TASKS_DEF_YAML_PATH = File.join(GEM_ROOT_TEST, 'specs/data/tasks-def.yml').freeze

# ---- Helpers ----------------------------------------------------------------

# Recursively collect ALL non-_* key paths from a nested hash.
# Includes namespace nodes and leaf task nodes alike.
# Example: { 'sync' => { 'library' => { '_desc' => '...' } } } →
#          ['labdev:sync', 'labdev:sync:library']
def collect_all_task_paths hash, prefix = []
  [].tap do |paths|
    hash.each do |key, value|
      next if key.to_s.start_with?('_')

      current = prefix + [key]
      paths << current.join(':')
      paths.concat(collect_all_task_paths(value, current)) if value.is_a?(Hash)
    end
  end
end

# Collect only paths whose node carries a non-blank _desc value.
def collect_described_task_paths hash, prefix = []
  [].tap do |paths|
    hash.each do |key, value|
      next if key.to_s.start_with?('_')

      current = prefix + [key]
      paths << current.join(':') if value.is_a?(Hash) && !value['_desc'].to_s.strip.empty?
      paths.concat(collect_described_task_paths(value, current)) if value.is_a?(Hash)
    end
  end
end

# Load tasks.rb into a temporarily isolated Rake application and return
#   { all: [names], described: [names_with_comment] }
# Restores the previous Rake.application even if an error occurs.
def load_labdev_rake_tasks
  # Ensure the DocOpsLab::Dev namespace exists so tasks.rb can open it.
  Object.const_set(:DocOpsLab, Module.new) unless defined?(DocOpsLab)
  DocOpsLab.const_set(:Dev, Module.new) unless DocOpsLab.const_defined?(:Dev, false)

  previous_app = Rake.application
  fresh_app    = Rake::Application.new
  Rake.application = fresh_app

  # Remove Tasks if already loaded so `load` can re-define it cleanly.
  DocOpsLab::Dev.send(:remove_const, :Tasks) if DocOpsLab::Dev.const_defined?(:Tasks, false) # rubocop:disable RSpec/RemoveConst
  load TASKS_RB_PATH
  DocOpsLab::Dev::Tasks.new

  labdev_tasks = fresh_app.tasks.select { |t| t.name.start_with?('labdev') }
  {
    all:       labdev_tasks.map(&:name),
    described: labdev_tasks.reject { |t| t.comment.to_s.strip.empty? }.map(&:name)
  }
ensure
  Rake.application = previous_app
end

# ---- Spec -------------------------------------------------------------------

RSpec.describe 'labdev task registry (tasks.rb ↔ tasks-def.yml)' do
  let(:labdev_def) { YAML.load_file(TASKS_DEF_YAML_PATH).fetch('labdev') }

  # Computed once per example via let memoisation.
  let(:rake_info)                 { load_labdev_rake_tasks }
  let(:all_rake_task_names)       { rake_info[:all] }
  let(:described_rake_task_names) { rake_info[:described] }
  let(:all_yaml_paths)            { collect_all_task_paths(labdev_def, ['labdev']) }
  let(:described_yaml_paths)      { collect_described_task_paths(labdev_def, ['labdev']) }

  # ---- tasks-def.yml → tasks.rb -------------------------------------------

  describe 'tasks-def.yml → tasks.rb' do
    it 'every _desc path in tasks-def.yml has a matching registered Rake task' do
      missing = described_yaml_paths - all_rake_task_names
      expect(missing).to be_empty,
                         "YAML _desc entries with no matching Rake task:\n#{missing.map { |p| "  - #{p}" }.join("\n")}"
    end
  end

  # ---- tasks.rb → tasks-def.yml -------------------------------------------

  describe 'tasks.rb → tasks-def.yml' do
    it 'every registered Rake task has a corresponding tasks-def.yml entry' do
      undocumented = all_rake_task_names - all_yaml_paths
      expect(undocumented).to be_empty,
                              "Rake tasks with no tasks-def.yml entry:\n#{undocumented.map do |t|
                                "  - #{t}"
                              end.join("\n")}"
    end

    it 'every Rake task carrying a description has a _desc in tasks-def.yml' do
      missing_desc = described_rake_task_names - described_yaml_paths
      expect(missing_desc).to be_empty,
                              "Rake tasks with a description but no _desc in tasks-def.yml:\n#{missing_desc.map do |t|
                                "  - #{t}"
                              end.join("\n")}"
    end
  end

  # ---- tasks-def.yml internal consistency ---------------------------------

  describe 'tasks-def.yml internal consistency' do
    it 'has no blank _desc values' do
      blanks = all_yaml_paths.select do |path|
        parts = path.split(':')[1..]
        node  = labdev_def.dig(*parts)
        node.is_a?(Hash) && node.key?('_desc') && node['_desc'].to_s.strip.empty?
      end
      expect(blanks).to be_empty,
                        "tasks-def.yml entries with blank _desc:\n#{blanks.map { |p| "  - #{p}" }.join("\n")}"
    end

    it 'has no _alias pointing to a path absent from tasks-def.yml' do
      bad_aliases = []
      all_yaml_paths.each do |path|
        parts = path.split(':')[1..]
        node  = labdev_def.dig(*parts)
        next unless node.is_a?(Hash) && node.key?('_alias')

        target       = node['_alias'].to_s
        target_parts = target.split(':')[1..]
        bad_aliases << "#{path} → #{target}" unless labdev_def.dig(*target_parts).is_a?(Hash)
      end
      expect(bad_aliases).to be_empty,
                             "tasks-def.yml _alias entries pointing to missing paths:\n#{bad_aliases.map do |a|
                               "  - #{a}"
                             end.join("\n")}"
    end
  end
end
