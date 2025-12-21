# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module DocOpsLab
  module Dev
    module Help
      class << self
        def show_task_help task_string=nil
          tasks_def_path = File.join(GEM_ROOT, 'specs/data/tasks-def.yml')

          unless File.exist?(tasks_def_path)
            puts '❌ Tasks definition file not found'
            return
          end

          tasks_def = YAML.load_file(tasks_def_path)

          if task_string.nil?
            show_general_help
            return
          end

          # Normalize task string (allow with or without labdev: prefix)
          task_string = "labdev:#{task_string}" unless task_string.start_with?('labdev:')

          # Parse task path
          task_parts = task_string.sub('labdev:', '').split(':')

          # Navigate to task in YAML structure
          current = tasks_def['labdev']
          found = true
          task_parts.each do |part|
            if current.is_a?(Hash) && current[part]
              current = current[part]
            else
              puts "❌ Task not found: #{task_string}"
              found = false
              break
            end
          end

          return unless found

          show_task_details(task_string, current)
        end

        private

        def show_general_help
          puts '📚 DocOps Lab Development Tools - Available Tasks'
          puts '=' * 60
          puts ''
          puts 'Use `bundle exec rake -T | grep labdev:` to see all tasks.'
          puts 'Use `bundle exec rake labdev:help[verb:subtask]` for detailed help.'
          puts ''
          puts "Example: bundle exec rake 'labdev:help[run:script]'"
          puts ''
        end

        def show_task_details task_string, task_info
          puts "📚 Help for: #{task_string}"
          puts '=' * 60
          puts ''

          if task_info['_desc']
            puts "Description: #{task_info['_desc']}"
            puts ''
          end

          if task_info['_docs']
            puts 'Documentation:'
            puts task_info['_docs']
            puts ''
          end

          if task_info['_alias']
            puts "⚠️  This is an alias for: #{task_info['_alias']}"
            # Display help for the aliased task
            show_task_help(task_info['_alias'])
            return
          end

          # Show subtasks if this is a namespace
          subtasks = task_info.select { |k, v| !k.start_with?('_') && v.is_a?(Hash) }
          if subtasks.any?
            puts 'Available subtasks:'
            puts ''
            subtasks.each do |subtask_name, subtask_info|
              desc = subtask_info['_desc'] || '(no description)'
              alias_note = subtask_info['_alias'] ? " → #{subtask_info['_alias']}" : ''
              puts "  #{task_string}:#{subtask_name}#{alias_note}"
              puts "    #{desc}"
              puts ''
            end
          end

          if task_info['_args']
            puts 'Arguments:'
            task_info['_args'].each do |arg_name, arg_info|
              required = arg_info['required'] ? '(required)' : '(optional)'
              puts "  #{arg_name} #{required}"
              puts "    #{arg_info['summ']}" if arg_info['summ']
              puts "    #{arg_info['docs'].strip.split("\n").join("\n    ")}" if arg_info['docs']
              puts ''
            end
          end

          return unless task_info['_test']

          puts 'Example usage:'
          task_info['_test'].each do |test_cmd|
            puts "  #{test_cmd}"
          end
          puts ''
        end
      end
    end
  end
end
