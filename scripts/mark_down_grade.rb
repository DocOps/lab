# frozen_string_literal: true

# ReverseMarkdown Extensions
#
# Extends ReverseMarkdown with custom converters for better HTML-to-Markdown conversion
# Specifically designed for converting AsciiDoc-generated HTML to cleaner Markdown
#
# Usage:
#   require_relative 'scripts/mark_down_grade'
#   MarkDownGrade.bootstrap!
#   markdown = ReverseMarkdown.convert(html, github_flavored: true)
#
# See README-mark_down_grade.adoc for more.

require 'reverse_markdown'

module MarkDownGrade
  VERSION = '0.1.0'

  @config = {
    preserve_heading_ids: true,
    strip_internal_links: false
  }

  class << self
    attr_reader :config
  end

  # Setup all custom converters
  # Options:
  #   preserve_heading_ids: (default: true) Include <a id="..."> anchors before headings
  #   strip_internal_links: (default: false) Remove href from internal anchor links, keeping only text
  def self.bootstrap! options={}
    @config.merge!(options)

    register_pre_converter
    register_heading_converters
    register_dl_converters
    register_block_converters
    register_table_converter
    register_comment_converter
    register_list_converters
    register_link_converter if @config[:strip_internal_links]
  end

  # Enhanced Pre converter to handle additional code block language patterns
  class CustomPre < ReverseMarkdown::Converters::Pre
    MAP = {
      'rb' => 'ruby',
      'yml' => 'yaml',
      'js' => 'javascript',
      'ts' => 'typescript',
      'sh' => 'bash',
      'zsh' => 'bash',
      'bash' => 'bash',
      'json' => 'json',
      'yaml' => 'yaml',
      'md' => 'markdown'
    }.freeze

    def language node
      # Parent handles highlight-*, brush:, etc.
      lang = super
      return normalize(lang) if lang

      candidates = []

      # 1) Inspect this <pre> and its <code> child
      code_child = node.at_css('code')
      [node, code_child].compact.each do |ele|
        collect_lang_hints(ele, candidates)
      end

      # 2) Inspect ancestors up to two levels (e.g., listingblock containers)
      node.ancestors.take(3).each do |anc|
        collect_lang_hints(anc, candidates)
      end

      candidates.compact!
      candidates.map! { |c| normalize(c) }
      candidates.find { |c| c } # first normalized non-nil
    end

    private

    def collect_lang_hints ele, acc
      return unless ele.respond_to?(:[])

      classes = ele['class'].to_s.split
      classes.each do |cls|
        if (m = cls.match(/\A(language|lang|highlight|source)-([A-Za-z0-9_+#-]+)\z/))
          acc << m[2]
        end
      end
      %w[data-lang data-language lang language].each do |attr|
        v = ele[attr]
        acc << v if v && !v.empty?
      end
    end

    def normalize value
      return nil if value.to_s.strip.empty?

      v = value.to_s.downcase
      v = MAP[v] || v
      # common aliases
      v = 'javascript' if %w[js nodejs node ecmascript].include?(v)
      v = 'yaml' if v == 'yml'
      v = 'bash' if %w[shell sh zsh].include?(v)
      v
    end
  end

  # Heading converter: optionally preserve id attribute by emitting an anchor before the heading
  class HeadingWithId < ReverseMarkdown::Converters::Base
    def convert node, state={}
      level = node.name[/\d/].to_i
      prefix = '#' * level
      heading = "#{prefix} #{treat_children(node, state)}\n"

      if MarkDownGrade.config[:preserve_heading_ids]
        anchor = node['id'].to_s.strip
        anchor.empty? ? "\n#{heading}" : "\n<a id=\"#{anchor}\"></a>\n#{heading}"
      else
        "\n#{heading}"
      end
    end
  end

  # Definition list converter: render AsciiDoc HD lists as Markdown term blocks
  # Example:
  # <dt>Term</dt><dd>Text</dd>
  # →
  # *Term*:
  #    Text...
  class DlConverter < ReverseMarkdown::Converters::Base
    def convert node, state={}
      children = node.element_children
      i = 0
      out = []
      while i < children.length
        if children[i].name == 'dt'
          # collect one or more consecutive dt terms
          terms = []
          while i < children.length && children[i].name == 'dt'
            terms << treat_children(children[i], state).strip
            i += 1
          end
          # expect a dd next (optional)
          dd = i < children.length && children[i].name == 'dd' ? children[i] : nil
          body_md = ''
          if dd
            # Convert dd by converting each child and joining, then indent each non-empty line by 3 spaces
            body_content = dd.children.map { |c| treat(c, state) }.join.strip
            body_md = indent_block(body_content)
          end
          terms.each do |term|
            out << "**#{term}**:\n#{body_md}".rstrip
          end
        end
        i += 1
      end
      "#{out.join("\n\n")}\n"
    end

    private

    def indent_block text
      return '' if text.to_s.empty?

      text.split("\n").map { |line| line.empty? ? '' : "   #{line}" }.join("\n")
    end
  end

  # Definition term converter: preserves <dt> with classes, converts content
  class DtConverter < ReverseMarkdown::Converters::Base
    def convert node, state={}
      class_attr = node['class'] ? %( class="#{node['class']}") : ''
      "<dt#{class_attr}>#{treat_children(node, state)}</dt>\n"
    end
  end

  # Definition description converter: preserves <dd>, converts nested content
  # Nested <ul><li> elements are automatically converted to Markdown lists
  class DdConverter < ReverseMarkdown::Converters::Base
    def convert node, state={}
      # treat_children converts nested HTML (like <ul><li>) to Markdown automatically
      content = treat_children(node, state)
      "<dd>\n#{content.strip}\n</dd>\n"
    end
  end

  # Special Div converter: handles sidebarblock and admonitionblock specifically; delegates others to default Div
  class SpecialDivConverter < ReverseMarkdown::Converters::Base
    def initialize
      super
      @default_div = ReverseMarkdown::Converters::Div.new
    end

    def convert node, state={}
      classes = node['class'].to_s.split
      if classes.include?('sidebarblock')
        convert_sidebarblock(node, state)
      elsif classes.include?('admonitionblock')
        convert_admonitionblock(node, state)
      else
        @default_div.convert(node, state)
      end
    end

    private

    def convert_sidebarblock node, state={}
      # Keep outer <div class="sidebarblock"> and an optional <div class="title">, convert the rest to Markdown
      container = node.at_css('div.content') || node
      title_node = container.at_css('> .title') || node.at_css('> .title')
      # Convert title to an h4 Markdown heading for better structure in MD
      title_md = ''
      if title_node
        title_text = treat_children(title_node, state).strip
        title_text = title_text.gsub(/\s+/, ' ')
        title_md = "#### #{title_text}\n\n"
      end
      # Body is all children of container except the title node
      body_nodes = container.children.reject { |c| c.element? && c['class'].to_s.split.include?('title') }
      body_md = body_nodes.map { |c| treat(c, state) }.join.strip
      %(<div class="sidebarblock">\n#{title_md}#{body_md}\n</div>\n)
    end

    def convert_admonitionblock node, state={}
      # Render Asciidoctor admonition as a Markdown blockquote with bold label
      classes = node['class'].to_s.split
      type = (classes & %w[note tip warning caution important]).first ||
             node.at_css('td.icon > .title')&.text&.downcase || 'note'
      type_up = type.to_s.strip.upcase

      container = node.at_css('td.content') || node.at_css('div.content') || node

      # Optional content title inside the content cell
      content_title_node = container.at_css('> .title')
      inline_title = content_title_node ? treat_children(content_title_node, state).strip.gsub(/\s+/, ' ') : nil

      # Body is all children except the content title
      body_nodes = container.children.reject { |c| c.element? && c['class'].to_s.split.include?('title') }
      body_md = body_nodes.map { |c| treat(c, state) }.join.strip

      label = "**#{type_up}:**"
      label += " #{inline_title}" if inline_title && !inline_title.empty?

      # Insert label at first non-empty line, then prefix every line as a blockquote
      lines = body_md.split("\n")
      if lines.empty?
        lines = [label]
      else
        idx = lines.index { |l| !l.strip.empty? } || 0
        lines[idx] = "#{label} #{lines[idx].lstrip}".rstrip
      end

      quoted = lines.map { |l| l.strip.empty? ? '>' : "> #{l}" }.join("\n")
      "#{quoted}\n"
    end
  end

  # Passthrough Tables: preserve HTML tables as-is (except admonition internals handled elsewhere)
  class TablePassthrough < ReverseMarkdown::Converters::Base
    def convert node, _state={}
      "#{node.to_html}\n"
    end
  end

  # HTML Comment converter: preserve comments and ensure a trailing newline
  class HtmlComment < ReverseMarkdown::Converters::Base
    def convert node, _state={}
      out = node.to_html
      out.end_with?("\n") ? out : "#{out}\n"
    end
  end

  # Link converter that strips internal anchor links
  # Internal links (href="#...") are converted to plain text
  # External links are preserved as Markdown links
  class LinkConverter < ReverseMarkdown::Converters::Base
    def convert node, state={}
      href = node['href'].to_s

      if href.start_with?('#')
        treat_children(node, state)
      else
        ReverseMarkdown::Converters::A.new.convert(node, state)
      end
    end
  end

  # List item converter that handles nested lists and checklists
  # Extends ReverseMarkdown's default Li to properly convert nested ol/ul elements
  class LiWithNestedLists < ReverseMarkdown::Converters::Base
    def convert node, state={}
      indentation = indentation_from(state)

      content_parts = []
      nested_lists = []

      # Check for checkbox in this LI or its first paragraph
      # Asciidoctor often puts the checkbox inside a <p> tag
      checkbox = node.at_xpath('./input[@type="checkbox"] | ./p/input[@type="checkbox"][1]')

      prefix = if checkbox
                 is_checked = checkbox['checked'] || checkbox['data-item-complete'] == '1'
                 # Remove the checkbox from the DOM so it doesn't get rendered again
                 checkbox.remove
                 is_checked ? '<!--CHECKBOX_CHECKED--> ' : '<!--CHECKBOX_UNCHECKED--> '
               else
                 prefix_for(node)
               end

      node.children.each do |child|
        if child.element? && %w[ol ul].include?(child.name)
          nested_lists << child
        else
          content_parts << treat(child, state)
        end
      end

      content = content_parts.join.strip
      result = "#{indentation}#{prefix}#{content}\n"

      nested_lists.each do |nested_list|
        nested_state = state.merge(ol_count: state.fetch(:ol_count, 0) + 1)
        nested_md = treat(nested_list, nested_state).strip
        result << "#{nested_md}\n" unless nested_md.empty?
      end

      result
    end

    private

    def prefix_for node
      if node.parent.name == 'ol'
        index = node.parent.xpath('li').index(node)
        "#{index.to_i + 1}. "
      else
        '- '
      end
    end

    def indentation_from state
      length = state.fetch(:ol_count, 0)
      '   ' * [length - 1, 0].max
    end
  end

  # Register the enhanced Pre converter
  def self.register_pre_converter
    ReverseMarkdown::Converters.register :pre, CustomPre.new
  end

  # Register heading converter that preserves ids
  def self.register_heading_converters
    converter = HeadingWithId.new
    ReverseMarkdown::Converters.register :h1, converter
    ReverseMarkdown::Converters.register :h2, converter
    ReverseMarkdown::Converters.register :h3, converter
    ReverseMarkdown::Converters.register :h4, converter
    ReverseMarkdown::Converters.register :h5, converter
    ReverseMarkdown::Converters.register :h6, converter
  end

  # Register all definition list converters
  def self.register_dl_converters
    ReverseMarkdown::Converters.register :dl, DlConverter.new
    ReverseMarkdown::Converters.register :dt, DtConverter.new
    ReverseMarkdown::Converters.register :dd, DdConverter.new
  end

  # Register block converter for special div classes
  def self.register_block_converters
    ReverseMarkdown::Converters.register :div, SpecialDivConverter.new
  end

  # Register table passthrough converter
  def self.register_table_converter
    ReverseMarkdown::Converters.register :table, TablePassthrough.new
  end

  # Register HTML comment converter
  def self.register_comment_converter
    ReverseMarkdown::Converters.register :comment, HtmlComment.new
  end

  # Register custom list converters for nested list support
  def self.register_list_converters
    ReverseMarkdown::Converters.register :li, LiWithNestedLists.new
  end

  # Register custom link converter to strip internal anchor links
  def self.register_link_converter
    ReverseMarkdown::Converters.register :a, LinkConverter.new
  end

  # Convenience method to convert HTML with extensions already applied
  def self.convert html, options={}
    bootstrap! unless @setup_complete
    @setup_complete = true

    markdown = ReverseMarkdown.convert(html, options)

    # Post-process checklists to ensure correct format
    markdown.gsub('<!--CHECKBOX_CHECKED-->', '- [x]')
            .gsub('<!--CHECKBOX_UNCHECKED-->', '- [ ]')
  end
end
