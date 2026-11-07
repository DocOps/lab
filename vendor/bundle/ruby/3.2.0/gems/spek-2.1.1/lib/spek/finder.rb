# frozen_string_literal: true

module Spek
  # Finds multiple versions of an installed gem (if any) and answers found specifications.
  class Finder
    def self.call(path, ...) = new(...).call path

    def initialize client: ::Gem::Specification, presenter: Presenter
      @client = client
      @presenter = presenter
    end

    def call(name) = client.find_all_by_name(name).map { |record| presenter.with_default record }

    private

    attr_reader :client, :presenter
  end
end
