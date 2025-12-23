# frozen_string_literal: true

# File to be called by DocOpsLab::Dev to auto-fix AsciiDoc files
module DocOpsLab
  module Dev
    module AutoFixAsciidoc
      class << self
        def fix_asciidoc_files _context, path: nil
          # use the find_asciidoc_files method if no path is passed
          adoc_files = if path
                         if File.directory?(path)
                           Dir.glob(File.join(path, '**', '*.adoc'))
                         elsif File.file?(path) && File.extname(path) == '.adoc'
                           [path]
                         else
                           puts "❌ Invalid path specified for AsciiDoc auto-fix: #{path}"
                           return false
                         end
                       else
                         Dev.find_asciidoc_files
                       end

          if adoc_files.empty?
            puts '✅ No AsciiDoc files found for auto-fix'
            return true
          end

          fixed_count = 0

          adoc_files.each do |file_path|
            File.read(file_path)
            Dev.run_script('adoc_section_ids.rb', [file_path])
          end

          if fixed_count.positive?
            puts "✅ AsciiDoc auto-fix complete; #{fixed_count} files modified"
          else
            puts '✅ All AsciiDoc files are already compliant'
          end

          true
        end
      end
    end
  end
end
