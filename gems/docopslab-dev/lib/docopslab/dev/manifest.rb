# frozen_string_literal: true

require 'yaml'

module DocOpsLab
  module Dev
    # Thin wrapper around the project manifest (.config/docopslab-dev.yml).
    # Shared by tools, sync, and library operations that need manifest data.
    module Manifest
      class << self
        # Load a project manifest YAML file.
        # Returns the parsed hash or nil if the file is absent or unreadable.
        def load path=Dev::MANIFEST_PATH
          return nil unless File.exist?(path)

          YAML.load_file(path)
        rescue StandardError
          nil
        end

        # True if data is a non-empty Hash.
        def valid? data
          data.is_a?(Hash) && !data.empty?
        end
      end
    end
  end
end
