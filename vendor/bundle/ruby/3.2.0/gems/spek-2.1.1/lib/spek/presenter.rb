# frozen_string_literal: true

require "forwardable"
require "refinements/arrays"
require "refinements/pathnames"
require "refinements/strings"
require "versionaire"

module Spek
  # Enhances the default Ruby Gems specification.
  class Presenter
    extend Forwardable

    using Refinements::Arrays
    using Refinements::Strings
    using Refinements::Pathnames
    using Versionaire::Cast

    delegate %i[
      bindir
      executables
      extra_rdoc_files
      files
      license
      metadata
      name
      platform
      require_paths
      required_ruby_version
      runtime_dependencies
      summary
    ] => :record

    def self.with_default record = nil, model: Gem::Specification
      record && record.is_a?(model) ? new(record) : new(model.new)
    end

    def initialize record
      @record = record
    end

    def allowed_push_host = metadata.fetch "allowed_push_host", ::Gem::DEFAULT_HOST

    def allowed_push_key = metadata.fetch "allowed_push_key", "rubygems_api_key"

    def authors = Array record.author

    def banner(delimiter: ": ") = [labeled_version, summary].tap(&:compress!).join delimiter

    def certificate_chain = Array(record.cert_chain).map { |path| Pathname path.to_s }

    def documentation_url = metadata.fetch "documentation_uri", ""

    def emails = Array record.email

    def funding_url = metadata.fetch "funding_uri", ""

    def homepage_url = String record.homepage

    def issues_url = metadata.fetch "bug_tracker_uri", ""

    def label = metadata.fetch "label", "Undefined"

    def labeled_summary(delimiter: ": ") = [label, summary].tap(&:compress!).join delimiter

    def labeled_version = [label, version].tap(&:compress!).join " "

    def named_version = [name, version].tap(&:compress!).join " "

    def package_name = %(#{[name, version].tap(&:compress!).join "-"}.gem)

    def package_path = Pathname("tmp").join package_name

    def rubygems_mfa? = metadata.fetch("rubygems_mfa_required", "false").to_bool

    def signing_key = Pathname record.signing_key.to_s

    def source_path = Pathname record.full_gem_path

    def source_url = metadata.fetch "source_code_uri", ""

    def version = Version record.version.to_s

    def versions_url = metadata.fetch "changelog_uri", ""

    private

    attr_reader :record
  end
end
