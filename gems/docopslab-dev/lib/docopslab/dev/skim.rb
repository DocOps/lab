# frozen_string_literal: true

require 'json'
require 'asciisourcerer'
require 'sourcerer/util/pathifier'

module DocOpsLab
  module Dev
    # Source skimming via Sourcerer::SourceSkim
    module Skim
      ADOC_EXTS = %w[.adoc .asc .ad .asciidoc].freeze
      MD_EXTS   = %w[.md .markdown].freeze
      ALL_EXTS  = (ADOC_EXTS + MD_EXTS).freeze

      class << self
        # Skim all supported file types (AsciiDoc + Markdown), format auto-detected.
        def run path, form: nil, syntax: nil
          run_with_format(path, exts: ALL_EXTS, form: form, syntax: syntax)
        end

        # Skim AsciiDoc source files only.
        def run_adoc path, form: nil, syntax: nil
          run_with_format(path, exts: ADOC_EXTS, form: form, syntax: syntax, default_forms: [:tree])
        end

        # Skim Markdown source files only, with optional upstream:local overlay support.
        def run_md path, form: nil, syntax: nil
          run_with_format(path, exts: MD_EXTS, form: form, syntax: syntax, overlay: true)
        end

        private

        def run_with_format path, exts:, form: nil, syntax: nil, default_forms: nil, overlay: false
          unless path
            puts '❌ Path is required.'
            puts 'Usage: bundle exec rake labdev:skim[path,form,syntax]'
            return
          end

          forms      = form ? parse_forms(form) : default_forms
          file_paths = overlay ? resolve_overlay_paths(path, exts) : resolve_paths(path, exts)

          if file_paths.empty?
            ext_desc = exts.size == 1 ? exts.first : exts.join(', ')
            warn "No #{ext_desc} files found for: #{path}"
            return
          end

          results = {}
          cats = Sourcerer::SourceSkim::DEFAULT_CATEGORIES - [:attributes_custom]
          file_paths.each do |fp|
            skim_opts = { categories: cats }
            skim_opts[:forms] = forms if forms
            results[fp] = Sourcerer::SourceSkim.skim_file(fp, **skim_opts)
          end
          portable = JSON.parse(JSON.generate(results))

          output_syntax = resolve_syntax(syntax, form)
          puts output_syntax == :json ? JSON.pretty_generate(portable) : portable.to_yaml
        end

        # Resolve file paths with optional upstream:local overlay.
        #
        # When path_arg contains ':', split into upstream_dir:local_dir. Local files shadow
        # upstream files that share the same relative path; local-only files are appended.
        def resolve_overlay_paths path_arg, exts
          parts = path_arg.split(':', 2).map(&:strip)
          return resolve_paths(parts[0], exts) if parts.size == 1

          upstream_dir, local_dir = parts
          upstream_map = build_relative_map(upstream_dir, exts)
          local_map    = build_relative_map(local_dir, exts)
          upstream_map.merge(local_map).values
        end

        def build_relative_map dir_path, exts
          dir_path = dir_path.chomp('/')
          return {} unless File.directory?(dir_path)

          abs_base = File.expand_path(dir_path)
          Sourcerer::Util::Pathifier.match(dir_path).enum
                                    .select { |p| exts.any? { |e| p.end_with?(e) } }
                                    .each_with_object({}) do |abs_path, map|
            map[abs_path.sub("#{abs_base}/", '')] = abs_path
          end
        end

        def parse_forms form
          form.split(',').map { |f| f.strip.to_sym }
        end

        def resolve_paths path, exts
          result = Sourcerer::Util::Pathifier.match(path)
          result.type == :dir ? result.enum.select { |p| exts.any? { |e| p.end_with?(e) } } : result.enum.to_a
        end

        def resolve_syntax syntax, form
          return :yaml unless form

          syntax = 'yaml' if syntax == 'yml'
          puts
          return syntax.to_sym if syntax

          :json
        end
      end
    end
  end
end
