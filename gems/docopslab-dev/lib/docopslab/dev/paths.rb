# frozen_string_literal: true

module DocOpsLab
  module Dev
    # Centralized path constants for DocOps Lab Dev
    module Paths
      # Gem root directory (gems/docopslab-dev/)
      def self.gem_root
        File.expand_path('../../..', __dir__)
      end

      # Asset directories in gem
      def self.gem_assets
        File.join(gem_root, 'assets')
      end

      def self.gem_config_packs
        File.join(gem_assets, 'config-packs')
      end

      def self.gem_hooks
        File.join(gem_assets, 'hooks')
      end

      def self.gem_scripts
        File.join(gem_assets, 'scripts')
      end

      # Config vendor directory (where config packs are synced to)
      def self.config_vendor_dir
        '.config/.vendor/docopslab'
      end

      # Generated/managed config files
      CONFIG_FILES = {
        vale: '.config/vale.ini',
        htmlproofer: '.config/htmlproofer.yml',
        rubocop: '.config/rubocop.yml'
      }.freeze

      def self.config_file name
        CONFIG_FILES[name]
      end
    end
  end
end
