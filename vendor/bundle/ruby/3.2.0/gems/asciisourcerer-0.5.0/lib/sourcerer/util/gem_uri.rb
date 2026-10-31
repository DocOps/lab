# frozen_string_literal: true

module Sourcerer
  module Util
    # Resolve <tt>gem://</tt> URIs to absolute filesystem paths.
    #
    # Not required internally; callers must require this file explicitly.
    module GemUri
      GEM_URI_PATTERN = %r{\Agem://([^/]+)/(.+)\z}

      # Resolve a +gem://+ URI to an absolute path within the named gem's directory.
      # Returns +path+ unchanged if it is not a +gem://+ URI.
      #
      # URI format: <tt>gem://<gem-name>/<path-within-gem></tt>
      # Example: <tt>gem://schemagraphy/lib/schemagraphy/cfgyml/templates/foo.liquid</tt>
      #
      # @param path [String] A gem:// URI or any other string.
      # @return [String] The resolved absolute path, or the original string if not a gem:// URI.
      # @raise [ArgumentError] If the gem:// URI is malformed.
      # @raise [LoadError] If the referenced gem is not loaded.
      def self.resolve path
        return path unless path.is_a?(String) && path.start_with?('gem://')

        match = GEM_URI_PATTERN.match(path)
        raise ArgumentError, "Invalid gem:// URI: #{path}" unless match

        spec = Gem.loaded_specs[match[1]]
        raise LoadError, "Gem '#{match[1]}' not loaded (referenced in gem:// URI: #{path})" unless spec

        File.join(spec.gem_dir, match[2])
      end
    end
  end
end
