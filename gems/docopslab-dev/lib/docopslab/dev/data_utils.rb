# frozen_string_literal: true

module DocOpsLab
  module Dev
    # Utilities for loading and caching project-level data for use in
    # Liquid template rendering (Sync/Cast) and other data-driven operations.
    module DataUtils
      class << self
        # Lazily load and cache the README.adoc document attributes.
        #
        # Available in Liquid templates as +data.project.attributes.<key>+.
        # Asciidoctor built-in attributes are filtered out; only user-defined
        #  string attributes are returned.
        #
        # @return [Hash{String => String}]
        def project_attributes
          return @project_attributes if defined?(@project_attributes)

          readme = 'README.adoc'
          unless File.exist?(readme)
            @project_attributes = {}
            return @project_attributes
          end

          require 'sourcerer/asciidoc'
          raw = Sourcerer::AsciiDoc.load_attributes(readme)
          @project_attributes = raw.select do |k, v|
            v.is_a?(String) && !v.empty? && !k.start_with?('asciidoctor')
          end
        rescue StandardError => e
          warn "⚠️  Could not load README.adoc attributes: #{e.message}"
          @project_attributes = {}
        end

        # Reset the cached project attributes (useful in tests or after file changes).
        def reset_project_attributes!
          remove_instance_variable(:@project_attributes) if defined?(@project_attributes)
        end
      end
    end
  end
end
