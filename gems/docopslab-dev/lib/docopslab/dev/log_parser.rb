# frozen_string_literal: true

require 'fileutils'
require 'shellwords'

module DocOpsLab
  module Dev
    # Log parsing functionality for Jekyll AsciiDoctor build logs
    module LogParser
      class << self
        def parse_jekyll_asciidoc_log log_file, output_dir=nil
          output_dir ||= default_output_dir

          script_name = 'parse_jekyll_asciidoc_logs.rb'

          # Execute the parsing script using ScriptManager.run_script
          Dev.run_script(script_name, [log_file, output_dir])
        end

        private

        def default_output_dir
          manifest = DocOpsLab::Dev.load_manifest
          log_config = manifest.dig('logs', 'output_dir') || '.agent/reports'
          FileUtils.mkdir_p(log_config)
          log_config
        end
      end
    end
  end
end
