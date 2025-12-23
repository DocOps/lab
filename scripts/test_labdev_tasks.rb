#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for labdev rake tasks
# Reads tasks-def.yml and runs tests for each task

require 'yaml'
require 'open3'
require 'timeout'
require 'colorize'

class LabdevTaskTester
  attr_reader :tasks_def_path, :tasks_def, :results, :task_filters

  def initialize task_filters=[]
    @tasks_def_path = File.join(__dir__, '../gems/docopslab-dev/specs/data/tasks-def.yml')
    @tasks_def = load_tasks_definition
    @results = { passed: [], failed: [], skipped: [] }
    @task_filters = task_filters
  end

  def load_tasks_definition
    unless File.exist?(tasks_def_path)
      puts "❌ Tasks definition file not found: #{tasks_def_path}".red
      exit 1
    end

    YAML.load_file(tasks_def_path)
  end

  def run_all_tests
    if task_filters.any?
      puts "🧪 Testing labdev rake tasks (filtered: #{task_filters.join(', ')})...".cyan
    else
      puts '🧪 Testing labdev rake tasks...'.cyan
    end
    puts '=' * 80
    puts ''

    traverse_and_test(tasks_def['labdev'], 'labdev')

    print_summary
  end

  def should_test_task? task_path
    # If no filters, test everything
    return true if task_filters.empty?

    # Check if any filter matches this task path
    task_filters.any? do |filter|
      # Normalize filter (allow with or without labdev: prefix)
      normalized_filter = filter.start_with?('labdev:') ? filter : "labdev:#{filter}"

      # Match if the task path contains the filter
      task_path.include?(normalized_filter)
    end
  end

  def traverse_and_test node, path
    return unless node.is_a?(Hash)

    node.each do |key, value|
      next if key.start_with?('_') # Skip metadata keys

      task_path = "#{path}:#{key}"

      next unless value.is_a?(Hash)

      # Check if this task has tests
      if value['_test']
        # Only run if it matches filters (or no filters)
        run_task_tests(task_path, value['_test']) if should_test_task?(task_path)
      elsif value['_alias']
        # Skip aliases; they're tested via their canonical task
        if should_test_task?(task_path)
          @results[:skipped] << { task: task_path, reason: "alias for #{value['_alias']}" }
        end
      elsif !subtasks?(value)
        # Leaf task without explicit tests; generate simple test
        generate_simple_test(task_path, value) if should_test_task?(task_path)
      end

      # Recurse into subtasks
      traverse_and_test(value, task_path)
    end
  end

  def subtasks? node
    node.keys.any? { |k| !k.start_with?('_') }
  end

  def run_task_tests task_path, tests
    tests.each_with_index do |test_cmd, idx|
      # Remove any duplicate trailing quotes that might be typos (e.g., '' at end)
      # But keep single trailing quote as it's needed for proper shell quoting
      test_cmd = test_cmd.gsub(/''+$/, "'")

      puts "  Testing: #{task_path} [#{idx + 1}/#{tests.size}]".yellow
      puts "  Command: #{test_cmd}".light_black

      success = run_command(test_cmd)

      if success
        @results[:passed] << { task: task_path, command: test_cmd }
        puts '    ✅ PASS'.green
      else
        @results[:failed] << { task: task_path, command: test_cmd }
        puts '    ❌ FAIL'.red
      end

      puts ''
    end
  end

  def generate_simple_test task_path, task_info
    # For tasks without args, just try to invoke them with --help or dry-run if available
    # For tasks with args, skip (they should have _test defined)

    if task_info['_args']
      @results[:skipped] << { task: task_path, reason: 'requires arguments but no _test defined' }
      puts "  ⏭️  Skipping #{task_path} (requires args, no test)".light_black
      return
    end

    # Simple tasks without args; try invoking them
    test_cmd = "bundle exec rake #{task_path} --dry-run 2>/dev/null"

    puts "  Testing: #{task_path} (generated test)".yellow
    puts "  Command: #{test_cmd}".light_black

    success = run_command(test_cmd, dry_run: true)

    if success
      @results[:passed] << { task: task_path, command: test_cmd }
      puts '    ✅ PASS (task exists)'.green
    else
      @results[:failed] << { task: task_path, command: test_cmd }
      puts '    ❌ FAIL (task not found)'.red
    end

    puts ''
  end

  def run_command command, dry_run: false
    # Set a timeout for safety
    cmd_timeout = 30

    begin
      # Execute command through shell to handle quoting properly
      _, _, status = Timeout.timeout(cmd_timeout) do
        Open3.capture3('/bin/sh', '-c', command)
      end

      # Debug: uncomment to see command output
      # puts "    STDOUT: #{stdout[0..200]}..." unless stdout.empty?
      # puts "    STDERR: #{stderr[0..200]}..." unless stderr.empty?
      puts "    STATUS: #{status.exitstatus}" if status.exitstatus != 0

      # For dry-run tests, just check if the task exists
      return true if dry_run && status.success?

      # For actual tests, check exit status
      # Note: Some tasks may fail if dependencies aren't installed, which is okay for structure testing
      status.success?
    rescue Timeout::Error
      puts "    ⏱️  Command timed out after #{cmd_timeout}s".red
      false
    rescue StandardError => e
      puts "    ⚠️  Error running command: #{e.message}".red
      false
    end
  end

  def print_summary
    puts '=' * 80
    puts '📊 Test Summary'.cyan.bold
    puts '=' * 80
    puts ''

    puts "✅ Passed:  #{@results[:passed].size}".green
    puts "❌ Failed:  #{@results[:failed].size}".red
    puts "⏭️  Skipped: #{@results[:skipped].size}".yellow
    puts ''

    if @results[:failed].any?
      puts 'Failed Tests:'.red.bold
      @results[:failed].each do |result|
        puts "  • #{result[:task]}".red
        puts "    #{result[:command]}".light_black
      end
      puts ''
    end

    if @results[:skipped].any?
      puts 'Skipped Tests:'.yellow.bold
      @results[:skipped].each do |result|
        puts "  • #{result[:task]} - #{result[:reason]}".yellow
      end
      puts ''
    end

    # Exit with error code if any tests failed
    exit 1 if @results[:failed].any?
  end
end

# Run the tests if this script is executed directly
if __FILE__ == $PROGRAM_NAME
  # Accept task filters from command line arguments
  filters = ARGV
  tester = LabdevTaskTester.new(filters)
  tester.run_all_tests
end
