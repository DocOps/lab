# frozen_string_literal: true

require 'liquid'

module SchemaGraphy
  # Liquid filter wrappers for SchemaGraphy domain operations.
  #
  # These filters are registered globally when SchemaGraphy is loaded and are
  # available in any Liquid rendering environment that has required this gem.
  # Following the DocOps Lab convention, each gem in the ecosystem registers
  # its own domain-specific filters here rather than delegating to AsciiSourcerer.
  module Filters
    # Classifies a value by its SGYML type.
    # @return [String] A "Kind:Class" type string (e.g. "Scalar:String", "Compound:ArrayList").
    # @see SchemaGraphy::SGYML.classify
    def sgyml_type input
      SchemaGraphy::SGYML.classify(input)
    end
  end
end

Liquid::Template.register_filter(SchemaGraphy::Filters)
