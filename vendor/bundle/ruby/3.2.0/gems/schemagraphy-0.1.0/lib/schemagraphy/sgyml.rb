# frozen_string_literal: true

module SchemaGraphy
  # Provides SGYML (SchemaGraphy YAML-based Modeling Language) type classification.
  # This is the canonical source for SGYML data types used across DocOps Lab tooling.
  #
  # Type strings are in "Kind:Class" form, e.g. "Scalar:String", "Compound:ArrayList",
  # "Null:nil". Downstream gems (AsciiSourcerer, ReleaseHx, etc.) that render SGYML
  # templates should obtain this classification via SchemaGraphy rather than
  # re-implementing it.
  module SGYML
    module_function

    # Classifies a Ruby value by its SGYML type.
    # @param input [Object] Any Ruby value.
    # @return [String] A "Kind:Class" type string.
    def classify input
      if input.nil?
        'Null:nil'
      elsif input.is_a?(Array)
        classify_array(input)
      elsif input.is_a?(Hash)
        classify_hash(input)
      elsif input.is_a?(String)
        'Scalar:String'
      elsif input.is_a?(Integer)
        'Scalar:Number'
      elsif input.is_a?(Float)
        'Scalar:Float'
      elsif input.is_a?(Time)
        'Scalar:DateTime'
      elsif input.is_a?(TrueClass) || input.is_a?(FalseClass)
        'Scalar:Boolean'
      else
        'unknown:unknown'
      end
    end

    def classify_array input
      if input.all? do |i|
        i.is_a?(Integer) || i.is_a?(Float) || i.is_a?(String) || i.is_a?(TrueClass) || i.is_a?(FalseClass)
      end
        'Compound:ArrayList'
      elsif input.all? { |i| i.is_a?(Hash) && i.keys.length >= 2 }
        'Compound:ArrayTable'
      else
        'Compound:Array'
      end
    end

    def classify_hash input
      if input.values.all? { |v| v.is_a?(Hash) && v.keys.length >= 2 }
        'Compound:MapTable'
      else
        'Compound:Map'
      end
    end
  end
end
