# frozen_string_literal: true

require 'base64'
require 'bigdecimal'
require 'cgi'
require 'date'
require 'kramdown-asciidoc'

module Sourcerer
  module Jekyll
    module Liquid
      # Liquid-facing filters for Sourcerer's Jekyll-compatible runtime.
      #
      # Public methods in this module are the filter wrappers consumed by Liquid.
      # Core transformation logic lives in `Ops` so behavior is reusable and easier
      # to test/refactor without changing the Liquid surface.
      module Filters
        # Load canonical CLI args templates from YAML once at module load time
        def self.load_cli_args_parameters
          require 'yaml'
          # Path from filters.rb: lib/sourcerer/jekyll/liquid/filters.rb
          # To specs/data/liquid-filters.yml: go up 4 levels to gem root, then to specs/data
          yaml_path = File.join(__dir__, '../../../../specs/data/liquid-filters.yml')
          yaml_path = File.expand_path(yaml_path)
          data = YAML.load_file(yaml_path, permitted_classes: [Date, Time])
          filters = data.is_a?(Array) ? data : data['filters'] || []
          to_cli_args_filter = filters.find { |f| f['key'] == 'to_cli_args' }
          to_cli_args_filter&.dig('parameters') || {}
        end

        # Canonical template definitions loaded from specs/data/liquid-filters.yml
        CLI_ARGS_TEMPLATES = load_cli_args_parameters.freeze

        # Internal operations for filter behavior.
        module Ops
          module_function

          def render input, vars=nil
            scope = vars.is_a?(Hash) ? vars.transform_keys(&:to_s) : {}

            template =
              if input.respond_to?(:render) && input.respond_to?(:templated?) && input.templated?
                input
              else
                ::Liquid::Template.parse(input.to_s)
              end

            template.render(scope)
          end

          def sluggerize input, format='kebab'
            return input unless input.is_a?(String)

            case format
            when 'kebab' then input.downcase.gsub(/[\s\-_]/, '-')
            when 'snake' then input.downcase.gsub(/[\s\-_]/, '_')
            when 'camel' then input.downcase.gsub(/[\s\-_]/, '_').camelize(:lower)
            when 'pascal' then input.downcase.gsub(/[\s\-_]/, '_').camelize(:upper)
            else input
            end
          end

          # Convert a string into a lowercase URL slug, joining words with the
          # given separator (default `-`).
          def slugify input, *args
            separator = args[0] || '-'
            input.downcase
                 .gsub(/[^a-z0-9]+/, separator)
                 .gsub(/\A#{Regexp.escape(separator)}+|#{Regexp.escape(separator)}+\z/, '')
          end

          def plusify input
            input.gsub(/\n\n+/, "\n+\n")
          end

          def md_to_adoc input, wrap='ventilate'
            options = {}
            options[:wrap] = wrap.to_sym if wrap
            Kramdoc.convert(input, options)
          end

          def indent input, spaces=2, line1: false
            indent = ' ' * spaces
            lines = input.split("\n")
            indented = if line1
                         lines.map { |line| indent + line }
                       else
                         lines.map.with_index { |line, i| i.zero? ? line : indent + line }
                       end
            indented.join("\n")
          end

          def ruby_class input
            input.class.name
          end

          def title_caps input, hyphen=false
            return input unless input.is_a?(String)

            if hyphen
              input.gsub(/(^|[\s-])([[:alpha:]])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" }
            else
              input.gsub(/(^|\s)([[:alpha:]])/) { "#{::Regexp.last_match(1)}#{::Regexp.last_match(2).upcase}" }
            end
          end

          def demarkupify input
            return input unless input.is_a?(String)

            input = input.gsub(/`"|"`/, '"')
            input = input.gsub(/'`|`'/, "'")
            input = input.gsub(/[*_`]/, '')
            input = input.gsub(/[“”]/, '"')
            input.gsub(/[‘’]/, "'")
          end

          def inspect_yaml input
            require 'yaml'
            YAML.dump(input)
          end

          def base64 input
            return input unless input.is_a?(String)

            Base64.strict_encode64(input)
          end

          def base64_decode input
            return input unless input.is_a?(String)

            Base64.strict_decode64(input)
          rescue ArgumentError
            input
          end

          def html_escape input
            CGI.escapeHTML(input.to_s)
          end

          def html_unescape input
            CGI.unescapeHTML(input.to_s)
          end

          def wrap input, width=80
            return input unless input.is_a?(String)

            width = width.to_i
            return input if width <= 0

            input.split("\n").map do |line|
              line.gsub(/(.{1,#{width}})(\s+|$)/, "\\1\n").rstrip
            end.join("\n")
          end

          def commentwrap input, width=80, prefix=nil
            return input unless input.is_a?(String)

            wrapped = wrap(input, width)
            return wrapped unless prefix

            case prefix
            when 'xml'
              "<!-- #{wrapped} -->"
            when /\|/
              # Format like "/*|*/" becomes /* ... */
              parts = prefix.split('|')
              open_tag = parts[0]
              close_tag = parts[1] || ''
              "#{open_tag} #{wrapped}\n#{close_tag}"
            else
              # Regular comment prefix
              wrapped.split("\n").map { |line| "#{prefix}#{line}" }.join("\n")
            end
          end

          def to_yaml input, *args
            require 'yaml'

            # Parse args: can be "flow" and/or "quotes"
            flow = args.include?('flow')
            quotes = args.include?('quotes')

            if flow
              # Flow format (inline): {key: val}
              if input.is_a?(Array)
                if quotes
                  "[#{input.map { |item| "\"#{item}\"" }.join(', ')}]"
                else
                  "[#{input.map(&:inspect).join(', ')}]"
                end
              elsif input.is_a?(Hash)
                "{#{input.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')}}"
              else
                input.to_s
              end
            else
              # Block format (YAML): key: val
              output = YAML.dump(input)
              output.chomp
            end
          end

          def to_json input
            require 'json'
            input.to_json
          end

          def replace_regex input, pattern, replacement=''
            return input unless input.is_a?(String)

            input.gsub(/#{pattern}/, replacement)
          end

          def match input, pattern
            return false unless input.is_a?(String)

            !!(input =~ /#{pattern}/)
          end

          def holds_liquid input
            return false unless input.is_a?(String)

            # Check for Liquid tags: {{ }}, {% %}, {%- -%}, {{- -}}
            !!(input =~ /\{\{.*?\}\}|\{%-?.*?-?%\}/)
          end

          def to_cli_args input, template=nil, delimiter=' '
            return input unless input.is_a?(Hash)

            # Use templates loaded from canonical YAML source (Filters::CLI_ARGS_TEMPLATES)
            selected_template = Filters::CLI_ARGS_TEMPLATES[template] || template || '--<option> <argument>'

            input.map do |key, value|
              selected_template
                .gsub('<option>', key.to_s)
                .gsub('<o>', key.to_s[0])
                .gsub('<argument>', value.to_s)
                .gsub('<VARIABLE>', key.to_s.upcase)
                .gsub('<key>', key.to_s)
                .gsub('<value>', value.to_s)
            end.join(delimiter)
          end

          def store_list_concat input, key_name
            return input unless input.is_a?(Array)

            input.each_with_object([]) do |item, acc|
              values = item[key_name.to_s]
              acc.concat(values) if values.is_a?(Array)
            end.uniq
          end

          def store_list_dupes input, key_name
            return input unless input.is_a?(Array)

            # Collect all arrays from specified key
            arrays = input.map { |item| item[key_name.to_s] }.compact.grep(Array)

            # Find items that appear in multiple arrays
            all_items = arrays.flatten
            all_items.select { |item| all_items.count(item) > 1 }.uniq
          end

          # Overrides Jekyll's `inspect` filter, adding a `format` argument.
          # `html` (the default) reproduces Jekyll's own behavior exactly:
          # an HTML-escaped `Object#inspect` string.
          def inspect input, format='html'
            case format
            when 'yaml'
              require 'yaml'
              YAML.dump(input)
            when 'json'
              require 'json'
              input.to_json
            else
              html_escape(input.inspect)
            end
          end

          # -- Ports of Liquid 5 StandardFilters --
          #
          # Jekyll pins to Liquid 4, which lacks these four filters (added in
          # Liquid 5). Ported here so downstream templates can use them
          # regardless of the Liquid version Jekyll pulls in.
          # See BILL_OF_MATERIALS.adoc for provenance/license details.

          # Removes the last instance of a substring from a string.
          def remove_last input, string
            replace_last(input, string, '')
          end

          # Replaces the last instance of a substring in a string with a replacement.
          def replace_last input, string, replacement=''
            return input unless input.is_a?(String)

            target = string.to_s
            start_index = input.rindex(target)
            return input unless start_index

            output = input.dup
            output[start_index, target.length] = replacement.to_s
            output
          end

          # Strips leading/trailing whitespace and collapses interior runs of
          # whitespace to a single space.
          def squish input
            return input unless input.is_a?(String)

            input.strip.gsub(/\s+/, ' ')
          end

          # Sums a numeric array, or an array of Hashes at the given property.
          def sum input, property=nil
            return 0 unless input.is_a?(Array)

            values = input.map do |item|
              if property.nil?
                item
              elsif item.respond_to?(:[])
                item[property]
              else
                0
              end
            end

            result = values.sum { |value| to_number(value) }
            result.is_a?(BigDecimal) ? result.to_f : result
          end

          # @api private
          # Coerces a Liquid value to a number, matching Liquid 5's
          # `Utils.to_number` (Float -> BigDecimal for precision, numeric
          # strings parsed, everything else 0).
          def to_number obj
            case obj
            when Float
              BigDecimal(obj.to_s)
            when Numeric
              obj
            when String
              /\A-?\d+\.\d+\z/.match?(obj.strip) ? BigDecimal(obj) : obj.to_i
            else
              0
            end
          end
        end
        private_constant :Ops

        def render input, vars=nil
          Ops.render(input, vars)
        end

        def sluggerize input, format='kebab'
          Ops.sluggerize(input, format)
        end

        def slugify(input, *)
          Ops.slugify(input, *)
        end

        def plusify input
          Ops.plusify(input)
        end

        def md_to_adoc input, wrap='ventilate'
          Ops.md_to_adoc(input, wrap)
        end

        def indent input, spaces=2, line1: false
          Ops.indent(input, spaces, line1: line1)
        end

        def ruby_class input
          Ops.ruby_class(input)
        end

        def title_caps input, hyphen=false
          Ops.title_caps(input, hyphen)
        end

        def demarkupify input
          Ops.demarkupify(input)
        end

        def inspect_yaml input
          Ops.inspect_yaml(input)
        end

        def base64 input
          Ops.base64(input)
        end

        def base64_decode input
          Ops.base64_decode(input)
        end

        def html_escape input
          Ops.html_escape(input)
        end

        def html_unescape input
          Ops.html_unescape(input)
        end

        def wrap input, width=80
          Ops.wrap(input, width)
        end

        def commentwrap input, width=80, prefix=nil
          Ops.commentwrap(input, width, prefix)
        end

        def to_yaml(input, *)
          Ops.to_yaml(input, *)
        end

        def to_json input
          Ops.to_json(input)
        end

        def replace_regex input, pattern, replacement=''
          Ops.replace_regex(input, pattern, replacement)
        end

        def match input, pattern
          Ops.match(input, pattern)
        end

        def holds_liquid input
          Ops.holds_liquid(input)
        end

        def to_cli_args input, template=nil, delimiter=' '
          Ops.to_cli_args(input, template, delimiter)
        end

        def store_list_concat input, key_name
          Ops.store_list_concat(input, key_name)
        end

        def store_list_dupes input, key_name
          Ops.store_list_dupes(input, key_name)
        end

        def inspect input, format='html'
          Ops.inspect(input, format)
        end

        def remove_last input, string
          Ops.remove_last(input, string)
        end

        def replace_last input, string, replacement=''
          Ops.replace_last(input, string, replacement)
        end

        def squish input
          Ops.squish(input)
        end

        def sum input, property=nil
          Ops.sum(input, property)
        end
      end
    end
  end
end
