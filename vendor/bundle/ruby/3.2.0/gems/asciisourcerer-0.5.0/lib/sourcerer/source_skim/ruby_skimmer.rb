# frozen_string_literal: true

require 'yard'

module Sourcerer
  module SourceSkim
    # Parses Ruby source code and produces a JSON-ready skim hash.
    #
    # A new instance should be created per-document call. External callers should
    # use {Sourcerer::SourceSkim.skim_file} or {Sourcerer::SourceSkim.skim_string}
    # with a Ruby file or +format: :ruby+ rather than instantiating this class
    # directly.
    # @api private
    class RubySkimmer
      # @param content [String] raw Ruby source code
      # @param config [Config]
      # @return [Hash] JSON-ready skim
      def process content, config: Config.new(forms: [:flat], descriptions: true)
        require 'tempfile'

        @config = config

        # Set logging level to ERROR to suppress YARD warnings about missing files or other issues. This ensures that the skimming process is not interrupted by non-critical warnings.
        YARD::Logger.instance.level = 3

        # YARD's registry is a process-wide global. Without clearing it first,
        # a class/module/method path already registered from a previous
        # #process call keeps pointing at that call's (now-deleted) tempfile,
        # so it would be silently excluded from every subsequent skim.
        YARD::Registry.clear

        # YARD's parser is designed for documentation generation, so it expects
        # a file path to determine the source type.
        Tempfile.create(['sourcerer', '.rb']) do |tempfile|
          tempfile.write(content)
          tempfile.flush

          # Parse ONLY the modules, methods, and classes defined in the current file.
          YARD::Parser::SourceParser.parse(tempfile.path)
          objects = YARD::Registry.all(:class, :module, :method).select { |obj| obj.file == tempfile.path }

          result = {}
          result[:classes] = build_classes(objects.select { |obj| obj.type == :class })
          result[:modules] = build_modules(objects.select { |obj| obj.type == :module })
          result[:methods] = build_methods(objects.select { |obj| obj.type == :method })
          result
        end
      end

      private

      def build_classes classes
        classes.map do |cls|
          {
            name: cls.path,
            line: cls.line
          }.merge(
            @config.descriptions? ? { desc: cls.docstring.to_s } : {})
        end
      end

      def build_modules modules
        modules.map do |mod|
          {
            name: mod.path,
            line: mod.line
          }.merge(
            @config.descriptions? ? { desc: mod.docstring.to_s } : {})
        end
      end

      def build_methods methods
        methods.map do |meth|
          {
            name: meth.path,
            line: meth.line
          }.merge(
            @config.descriptions? ? { desc: meth.docstring.to_s } : {})
        end
      end
    end
  end
end
