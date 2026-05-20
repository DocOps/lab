# frozen_string_literal: true

module DocOpsLab
  module Dev
    # Detects and provides utilities for Docker container environments.
    module DockerAware
      class << self
        # True if running inside a Docker container.
        # Checks:
        #   1. DOCOPSLAB_IN_DOCKER environment variable (set in Dockerfile)
        #   2. /.dockerenv marker file (standard Docker indicator)
        def running_in_docker?
          ENV['DOCOPSLAB_IN_DOCKER'] == 'true' || File.exist?('/.dockerenv')
        end

        # True if Docker but without access to host's cache directory.
        # This is the case when user runs: docker run -v "$(pwd):/workspace" ...
        # without explicitly mounting ~/.cache/docopslab
        def docker_without_cache?
          running_in_docker? && !cache_mount_accessible?
        end

        # True if the Docker container can access the host's cache mount.
        # Checks if /home/docops/.cache/docopslab exists and is readable.
        def cache_mount_accessible?
          cache_path = File.expand_path('~/.cache/docopslab')
          File.exist?(cache_path) && File.directory?(cache_path) && File.readable?(cache_path)
        rescue StandardError
          false
        end

        # Workspace-relative cache path for Docker-only users.
        # Returns path like /workspace/.docopslab-cache/
        def workspace_cache_path
          File.join('/workspace', '.docopslab-cache')
        end
      end
    end
  end
end
