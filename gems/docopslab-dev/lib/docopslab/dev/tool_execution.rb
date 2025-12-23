# frozen_string_literal: true

require 'shellwords'

module DocOpsLab
  module Dev
    module ToolExecution
      class << self
        def tool_available? tool_name
          system("which #{tool_name} > /dev/null 2>&1")
        end

        def docker_available?
          @docker_available ||= system('which docker > /dev/null 2>&1')
        end

        def image_available?
          unless docker_available?
            @image_available = false
            return @image_available
          end
          @image_available ||= system('docker image inspect docopslab/dev > /dev/null 2>&1')
        end

        def run_with_fallback tool_name, command, use_docker: false
          # Accept String or Array command; prefer Array for safer execution
          cmd_runner = lambda do |cmd|
            cmd.is_a?(Array) ? system(*cmd) : system(cmd)
          end

          # if env var LABDEV_DEBUG=true, print the full command
          if ENV['LABDEV_DEBUG'] == 'true'
            if command.is_a?(Array)
              puts "🐛 [DEBUG] Command to run: #{command.map do |c|
                Shellwords.escape(c)
              end.join(' ')}"
            else
              puts "🐛 [DEBUG] Command to run: #{command}"
            end
          end

          # Run command natively or fall back to Docker
          if use_docker || !tool_available?(tool_name)
            if image_available?
              run_in_docker(command)
            else
              puts "❌ #{tool_name} not available natively and Docker not found"
              puts "   Install #{tool_name} or pull Docker image to continue" if docker_available?
              puts "   Install #{tool_name} or Docker to continue"            unless docker_available?
              false
            end
          else
            cmd_runner.call(command)
          end
        end

        def run_in_docker command
          # Run command in docopslab/dev container
          # Handle both String and Array command formats
          cmd_str = command.is_a?(Array) ? command.shelljoin : command
          docker_cmd = "docker run -it --rm -v \"$(pwd):/workspace\" -w /workspace docopslab/dev #{cmd_str}"
          puts "🐳 Running in Docker: #{cmd_str}"
          system(docker_cmd)
        end
      end
    end
  end
end
