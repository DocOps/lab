#!/usr/bin/env ruby
# frozen_string_literal: true

# Build DocOpsLab Vale package for distribution
# This script creates a Vale package from the docopslab-dev gem's config-packs

require 'fileutils'
require 'zip'
require 'yaml'

def build_vale_package
  puts '📦 Building DocOpsLab Vale package...'

  # Create artifacts directory
  artifacts_dir = 'artifacts/vale-packages'
  FileUtils.mkdir_p(artifacts_dir)

  # Create temporary package directory
  temp_dir = 'tmp/vale-package-build'
  package_dir = temp_dir
  FileUtils.rm_rf(temp_dir)
  FileUtils.mkdir_p(package_dir)

  vale_source = 'gems/docopslab-dev/assets/config-packs/vale'

  begin
    # Copy .vale.ini from base.ini
    vale_config_source = File.join(vale_source, 'base.ini')
    vale_config_dest = File.join(package_dir, '.vale.ini')

    raise "Source config not found: #{vale_config_source}" unless File.exist?(vale_config_source)

    FileUtils.cp(vale_config_source, vale_config_dest)
    puts "  ✓ Copied base config to #{vale_config_dest}"

    # Copy styles directory
    styles_source = 'gems/docopslab-dev/assets/config-packs/vale'
    styles_dest = File.join(package_dir, 'styles')
    FileUtils.mkdir_p(styles_dest)

    style_paths_array = YAML.load_file('gems/docopslab-dev/specs/data/tools.yml')
                            .find { |t| t['slug'] == 'vale' }['packaging']['packages']
    style_paths_array.each do |package|
      vale_name = package['target']
      src_name = package['source']
      source_style_dir = File.join(styles_source, src_name)
      dest_style_dir = File.join(styles_dest, vale_name)
      next unless File.directory?(source_style_dir)

      FileUtils.cp_r(source_style_dir, dest_style_dir)
      puts "  ✓ Copied style folder: #{src_name} → #{vale_name}/"
    end

    # Copy style scripts directory
    File.join(package_dir, 'config', 'scripts')

    # Create the zip package
    package_file = File.join(artifacts_dir, 'DocOpsLabStyles.zip')
    FileUtils.rm_f(package_file)

    puts '  📦 Creating package archive...'
    Zip::File.open(package_file, Zip::File::CREATE) do |zipfile|
      # Include all files and directories recursively
      Dir.glob(File.join(package_dir, '**', '{*,.*}'), File::FNM_DOTMATCH).each do |file|
        next if File.directory?(file)
        next if ['.', '..'].include?(File.basename(file))

        # Calculate relative path within the package
        relative_path = file.sub("#{temp_dir}/", '')
        zipfile.add(relative_path, file)
        puts "    + #{relative_path}"
      end
    end

    puts "✅ DocOpsLab Vale package built: #{package_file}"

    # Show package info
    file_size = File.size(package_file)
    puts "📊 Package size: #{(file_size / 1024.0).round(2)} KB"

    # Show contents summary
    puts "\n📋 Package contents:"
    Zip::File.open(package_file) do |zipfile|
      zipfile.each do |entry|
        puts "  #{entry.name} (#{(entry.size / 1024.0).round(2)} KB)"
      end
    end
  rescue StandardError => e
    puts "❌ Failed to build Vale package: #{e.message}"
    exit 1
  ensure
    # Clean up temporary directory
    FileUtils.rm_rf(temp_dir)
  end
end

# Run if called directly
if __FILE__ == $PROGRAM_NAME
  # Change to project root if we're in scripts/
  Dir.chdir('..') if File.basename(Dir.pwd) == 'scripts'

  build_vale_package
end
