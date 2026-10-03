# frozen_string_literal: true

require "refinements/pathnames"

module Spek
  # Updates a gem specification's version.
  class Versioner
    using Refinements::Pathnames

    def self.call(version, path, ...) = new(...).call version, path

    def initialize loader: Loader.new
      @loader = loader
    end

    def call version, path
      Pathname(path).rewrite { |content| content.sub(/version.+\n/, %(version = "#{version}"\n)) }
      loader.call path
    end

    private

    attr_reader :loader
  end
end
