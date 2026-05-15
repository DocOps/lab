# frozen_string_literal: true

def generate_id_from_heading heading
  heading.gsub(/\b(a|an|the|and|or|but|for|nor|on|at|to|from|by|in|of|is|are|was|were|be|being|been)\b/i, '')
         .gsub(/[^\w\s-]/, '').strip
         .squeeze(' ')
         .gsub(' ', '-').downcase
  heading.strip.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
end

def process_adoc_file file_path
  lines = File.readlines(file_path)
  updated_lines = []
  i = 0

  while i < lines.size
    line = lines[i]
    if line =~ /^(={2,})\s([A-Z].*)$/ # Match AsciiDoc headings (2+ = chars)
      Regexp.last_match(1)
      heading_text = Regexp.last_match(2)

      # Check if previous line is an explicit ID
      if i.zero? || lines[i - 1] !~ /^\[\[.*\]\]$/
        generated_id = generate_id_from_heading(heading_text)
        updated_lines << "[[#{generated_id}]]\n"
      end
    end
    updated_lines << line
    i += 1
  end

  File.write(file_path, updated_lines.join)
  puts "Processed file: #{file_path}"
end

# We need an alternative to optparse, hopefully using no dependencies

if ARGV.empty?
  puts 'Usage: ruby adoc_section_ids.rb <asciidoc_file1> [<asciidoc_file2> ...]'
  exit 1
end

ARGV.each do |file_path|
  unless File.exist?(file_path)
    puts "File not found: #{file_path}"
    next
  end

  process_adoc_file(file_path)
end
