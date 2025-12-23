# frozen_string_literal: true

require 'pathspec'

module Jekyll
  module PathStringsCompare
    # Cache compiled PathSpecs per unique pattern list
    @_ps_cache = {}

    class << self
      attr_accessor :_ps_cache
    end

    # Returns true if +path+ matches any pattern (gitignore semantics).
    # patterns: String or Array<String>
    #
    # Examples:
    #   '/docs/**'         # whole subtree
    #   '/docs/*'          # direct children only
    #   '/docs/'           # that directory and everything in it
    #   '!/docs/keep.md'   # negate (last match wins)
    def path_matches? path, patterns
      return false if path.nil? || path.empty? || patterns.nil?

      list =
        case patterns
        when String then [patterns]
        when Array  then patterns.compact.map!(&:to_s)
        else []
        end
      return false if list.empty?

      key = list.join("\n")

      cache = PathStringsCompare._ps_cache
      spec = cache[key]
      unless spec
        # Prefer explicit 'gitignore' (supported across releases).
        # Fallback to default if this gem version ignores the second arg.
        begin
          spec = PathSpec.from_lines(list, 'gitignore')
        rescue ArgumentError, NoMethodError, RuntimeError
          spec = PathSpec.from_lines(list)
        end
        cache[key] = spec
      end

      # pathspec expects paths relative to root, without a leading slash.
      path_str = path.to_s.sub(%r{^/}, '')
      !!spec.match(path_str)
    end
  end

  module LiquidFilters
    include Jekyll::PathStringsCompare

    # Liquid: {{ doc.url | path_strings_compare: site.search.exclude }}
    def path_strings_compare input, patterns
      path_matches?(input, patterns)
    end
  end
end

Liquid::Template.register_filter(Jekyll::LiquidFilters)
