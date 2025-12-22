# frozen_string_literal: true

require 'nokogiri'
require 'fileutils'
require_relative 'mark_down_grade'

module GenAgentDocs
  def self.run build_dir
    puts '📄 Generating agent documentation for docopslab-dev gem...'

    # Setup ReverseMarkdown extensions for better conversion
    # Strip internal anchor links and disable anchor IDs for LLM consumption
    MarkDownGrade.bootstrap!(strip_internal_links: true, preserve_heading_ids: false)

    # Manage paths
    source_dir = File.expand_path(File.join(build_dir, 'docs', 'agent'))
    gem_docs_dir = 'gems/docopslab-dev/docs/agent'
    FileUtils.rm_rf(gem_docs_dir)
    FileUtils.mkdir_p(gem_docs_dir)

    if Dir.exist?(source_dir)
      puts "  📂 Processing agent docs from #{source_dir}..."

      # Process agent docs directories created by Jekyll
      # Jekyll creates flat directories like /agent/git/ rather than /agent/skills/git/
      # We need to organize them back into the proper subdirectory structure

      # First handle the root index.html if it exists
      root_html = File.join(source_dir, 'index.html')
      if File.exist?(root_html)
        dest_file = File.join(gem_docs_dir, 'index.md')
        convert_and_write(root_html, dest_file)
      end

      # Create a mapping of file names to their intended categories
      # TODO: Tech Debt; Refactor this to avoid hardcoded directory mapping. Consider preserving directory structure during Jekyll build.
      # This is based on our file organization from the source
      # Each of these 3 vars should be Arrays made up of all *.adoc files in the given directory (_docs/agent/{skills,topics,roles,missions}) that are NOT preceeded by an underscore in the filename.
      skill_files = Dir.glob('_docs/agent/skills/*.adoc')
                       .map { |path| File.basename(path, '.adoc') }
                       .reject { |name| name.start_with?('_') }
      topic_files = Dir.glob('_docs/agent/topics/*.adoc')
                       .map { |path| File.basename(path, '.adoc') }
                       .reject { |name| name.start_with?('_') }
      role_files = Dir.glob('_docs/agent/roles/*.adoc')
                      .map { |path| File.basename(path, '.adoc') }
                      .reject { |name| name.start_with?('_') }
      mission_files = Dir.glob('_docs/agent/missions/*.adoc')
                         .map { |path| File.basename(path, '.adoc') }
                         .reject { |name| name.start_with?('_') }

      # Process all agent doc subdirectories
      Dir.glob(File.join(source_dir, '*')).select { |path| File.directory?(path) }.each do |doc_dir|
        doc_name = File.basename(doc_dir)
        html_file = File.join(doc_dir, 'index.html')
        next unless File.exist?(html_file)

        # Determine which category this file belongs to
        category = if skill_files.include?(doc_name)
                     'skills'
                   elsif topic_files.include?(doc_name)
                     'topics'
                   elsif role_files.include?(doc_name)
                     'roles'
                   elsif mission_files.include?(doc_name)
                     'missions'
                   else
                     # Default to 'misc' for uncategorized files
                     'misc'
                   end

        # Create category subdirectory in gem docs
        gem_category_dir = File.join(gem_docs_dir, category)
        FileUtils.mkdir_p(gem_category_dir)

        # Generate the markdown file
        dest_file = File.join(gem_category_dir, "#{doc_name}.md")
        convert_and_write(html_file, dest_file)
      end
    else
      puts "  ⚠️  Agent docs source directory not found: #{source_dir}"
    end

    # Process AGENTS.markdown template (strip Jekyll frontmatter, keep Liquid syntax)
    agents_template_source = '_docs/templates/AGENTS.markdown'
    agents_template_dest = File.join('gems/docopslab-dev/docs/agent', 'AGENTS.md')

    if File.exist?(agents_template_source)
      content = File.read(agents_template_source)

      # Strip Jekyll frontmatter (between --- markers)
      content = content.sub(/\A---.*?---\n/m, '')

      # Write to gem lib path (Liquid syntax preserved - no interpolation)
      File.write(agents_template_dest, content)
      puts "  ✓ Generated #{agents_template_dest}"
    else
      puts "  ⚠️  AGENTS.markdown template not found: #{agents_template_source}"
    end

    puts "✅ Agent documentation generated in #{gem_docs_dir}"
  end

  def self.convert_and_write html_file, dest_file
    doc = Nokogiri::HTML(File.read(html_file))
    h1 = doc.at_css('h1')
    body_div = doc.at_css('div.document-body')

    if body_div
      markdown_content = MarkDownGrade.convert(body_div.inner_html, github_flavored: true)

      title = h1 ? "# #{h1.text.strip}\n\n" : ''
      File.write(dest_file, title + markdown_content)
      puts "  ✓ Generated #{dest_file}"
    else
      puts "  ⚠️  No document body found in #{html_file}, skipping."
    end
  end
end
