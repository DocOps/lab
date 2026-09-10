# frozen_string_literal: true

require 'fileutils'

#
# Build site-wide xref_* attributes from collections and inject them
# into every AsciiDoc page right before Asciidoctor runs.
# Page front matter set as AsciiDoc `page-` attributes are not available
#  at the point this hook runs, so conventional frontmatter (--- fenced)
#  is recommended for overriding relevant values such as:
#  `xref_id`, `title`, `slug`, `xref_exclude`
#
# Usage:
# 1) Add this file to your _plugins/ directory
# 2) Ensure your collections have 'output: true' in _config.yml
# 3) Optionally set 'xref_exclude: true' in a page's front matter
#    to skip adding it to the attribute map.
# 4) Optionally set 'xref_id: custom-id' in a page's front matter
#    to use a custom ID instead of the slugified filename.
# 5) Use the generated attributes in your AsciiDoc content, e.g.:
#
#    {xref_guide_getting_started_title}
#    {xref_guide_getting_started_url}
#    {xref_guide_getting_started_link}
# 6) Alternately, write an includable file by setting
#    xref_attrs:
#      outfile: path/to/_includes/xref_attrs.adoc

module Jekyll
  module AsciiDoc
    # Patch Jekyll::AsciiDoc with constants it should provide but doesn't
    DEFAULT_FILE_EXTS = %w[asciidoc adoc ad].freeze unless defined?(DEFAULT_FILE_EXTS)

    module Ext
      # Shared utility methods for all AsciiDoc extensions

      module_function

      def asciidoc_ext_regex site
        # Match upstream Jekyll AsciiDoc logic exactly
        ext_config = if site&.config&.dig('asciidoc', 'ext')
                       site.config['asciidoc']['ext']
                     else
                       Jekyll::AsciiDoc::DEFAULT_FILE_EXTS * ','
                     end

        # Build regex the same way as upstream: /^\.(?:#{ext.tr ',', '|'})$/ix
        /^\.(?:#{ext_config.tr ',', '|'})$/ix
      end

      def asciidoc? doc, site = nil
        ext = doc.respond_to?(:extname) ? doc.extname : File.extname(doc.path.to_s)
        asciidoc_ext_regex(site).match? ext.to_s
      end

      module XrefAttrs
        SENTINEL = '// XREF-ATTRS-INJECTED'

        def self.extract_page_slug doc
          slug = doc.data['slug'] if doc.data.key?('slug') && !doc.data['slug'].to_s.strip.empty?
          slug ||= doc.data['page_slug'] if doc.data.key?('page_slug') && !doc.data['page_slug'].to_s.strip.empty?
          slug
        end

        def self.slugify value
          Jekyll::Utils.slugify value.to_s, mode: 'pretty', cased: false
        end

        def self.title_for doc
          doc.data['title'] || doc.data['doctitle'] || doc.data['page-title'] ||
            slugify(doc.basename_without_ext).tr('-', ' ').split.map(&:capitalize).join(' ')
        end

        def self.agent_group_for doc
          # Agent docs are grouped by their source directory, not their (flat)
          # published URL, e.g. _docs/agent/skills/foo.adoc -> "skills"
          return unless doc.relative_path.to_s =~ %r{_docs/agent/([^/]+)/}

          Regexp.last_match(1)
        end

        def self.build_attr_map site
          attrs = {}

          site.collections.each do |label, coll|
            coll.docs.each do |d|
              next if d.data['draft']
              next if d.data['published'] == false
              next if d.data['xref_exclude']

              slug  = d.data['xref_id'] || d.data['slug'] || extract_page_slug(d) || d.basename_without_ext

              slug  = slugify(slug)
              title = title_for(d)
              url   = d.url.to_s
              next if url.empty?

              base = "xref_#{label}_#{slug}"
              attrs["#{base}_title"] = title
              attrs["#{base}_url"]   = url
              # Use link: for absolute site URLs; xref: is for doc/ID targets
              attrs["#{base}_link"]  = "link:#{url}[#{title}]"

              # Agent docs also get a group-qualified key (e.g.
              # xref_docs_agent_skills_foo) so that same-slugged agent and
              # non-agent docs don't collide.
              group = agent_group_for(d)
              next unless group

              agent_base = "xref_docs_agent_#{group}_#{slug}"
              attrs["#{agent_base}_title"] = title
              attrs["#{agent_base}_url"]   = url
              attrs["#{agent_base}_link"]  = "link:#{url}[#{title}]"
            end
          end

          attrs
        end

        def self.build_agent_attr_map site
          # Agent-markdown counterpart of build_attr_map: for each agent doc,
          # emit the same group-qualified keys but pointing at the relative
          # path used in the generated .agent/docs/ markdown library instead
          # of the published HTML URL.
          agent_attrs = {}

          site.collections.each_value do |coll|
            coll.docs.each do |d|
              next if d.data['draft']
              next if d.data['published'] == false
              next if d.data['xref_exclude']

              group = agent_group_for(d)
              next unless group

              slug  = d.data['xref_id'] || d.data['slug'] || extract_page_slug(d) || d.basename_without_ext
              slug  = slugify(slug)
              title = title_for(d)
              path  = "./#{group}/#{slug}.md"

              base = "xref_docs_agent_#{group}_#{slug}"
              agent_attrs["#{base}_title"] = title
              agent_attrs["#{base}_url"]   = path
              agent_attrs["#{base}_link"]  = path
            end
          end

          agent_attrs
        end

        def self.attrs_block attrs
          lines = [SENTINEL]
          attrs.each do |k, v|
            lines << ":#{k}: #{v}"
          end
          lines << ''
          lines.join "\n"
        end

        def self.write_attrs_file site, attrs, agent_attrs = nil
          outfile_config = site.config.dig('xref_attrs', 'outfile')
          return unless outfile_config

          outfile_path = File.join(site.source, outfile_config)
          outfile_dir = File.dirname(outfile_path)

          # Ensure directory exists
          FileUtils.mkdir_p(outfile_dir)

          # Write HTML attributes
          lines = attrs.map do |k, v|
            ":#{k}: #{v}"
          end
          new_content = "#{lines.join("\n")}\n"

          existing = (File.read(outfile_path) if File.exist?(outfile_path))

          unless existing == new_content
            File.write(outfile_path, new_content)
            Jekyll.logger.info 'xref', "wrote #{attrs.size} attributes to #{outfile_config}"
          end

          # Write agent-specific attributes if provided
          return unless agent_attrs

          agent_outfile = outfile_config.sub(/\.adoc$/, '_agent.adoc')
          agent_outfile_path = File.join(site.source, agent_outfile)
          agent_outfile_dir = File.dirname(agent_outfile_path)
          FileUtils.mkdir_p(agent_outfile_dir)

          agent_lines = agent_attrs.map do |k, v|
            ":#{k}: #{v}"
          end
          agent_content = "#{agent_lines.join("\n")}\n"

          agent_existing = (File.read(agent_outfile_path) if File.exist?(agent_outfile_path))

          return if agent_existing == agent_content

          File.write(agent_outfile_path, agent_content)
          Jekyll.logger.info 'xref', "wrote #{agent_attrs.size} agent attributes to #{agent_outfile}"
        end
      end
    end
  end
end

# 1) Build the attribute maps once after content is read
Jekyll::Hooks.register :site, :post_read do |site|
  map = Jekyll::AsciiDoc::Ext::XrefAttrs.build_attr_map site
  agent_map = Jekyll::AsciiDoc::Ext::XrefAttrs.build_agent_attr_map site
  site.config['xref_attr_map']   = map
  site.config['xref_attr_block'] = Jekyll::AsciiDoc::Ext::XrefAttrs.attrs_block map
  site.config['xref_attr_map_agent'] = agent_map
  Jekyll.logger.info 'xref', "built #{map.size} attributes (#{agent_map.size} agent)"

  # Write attributes to file if configured
  Jekyll::AsciiDoc::Ext::XrefAttrs.write_attrs_file site, map, agent_map
end

# 2) Prepend the attribute entries to each AsciiDoc source before render
Jekyll::Hooks.register :documents, :pre_render do |doc, _payload|
  next unless Jekyll::AsciiDoc::Ext.asciidoc? doc, doc.site

  # Make the raw map visible to Liquid on this page for debugging
  doc.data['xref_attr_map'] = doc.site.config['xref_attr_map']

  block = doc.site.config['xref_attr_block'].to_s
  next if block.empty?

  content = doc.content.to_s
  head    = content.lstrip
  next if head.start_with? Jekyll::AsciiDoc::Ext::XrefAttrs::SENTINEL

  doc.content = "#{block}\n#{content}"
end

Jekyll::Hooks.register :pages, :pre_render do |page, _payload|
  next unless Jekyll::AsciiDoc::Ext.asciidoc? page, page.site

  # Make the raw map visible to Liquid on this page for debugging
  page.data['xref_attr_map'] = page.site.config['xref_attr_map']

  block = page.site.config['xref_attr_block'].to_s
  next if block.empty?

  content = page.content.to_s
  head    = content.lstrip
  next if head.start_with? Jekyll::AsciiDoc::Ext::XrefAttrs::SENTINEL

  page.content = "#{block}\n#{content}"
end
