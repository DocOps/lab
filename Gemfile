# frozen_string_literal: true

source 'https://rubygems.org'

gem 'colorize', '~> 1.1'
gem 'docopslab-dev', path: './gems/docopslab-dev'
gem 'jekyll', '~> 4.3.0'
gem 'pathspec', '~> 2.1'
gem 'reverse_markdown'
gem 'rubyzip', '~> 2.3' # For Vale package building
gem 'sass'

group :jekyll_plugins do
  gem 'jekyll-asciidoc',           '~> 3.0'
  gem 'jekyll-feed',               '~> 0.12'
  gem 'jekyll-redirect-from',      '~> 0.16'
  gem 'jekyll-seo-tag',            '~> 2.8'
  gem 'jekyll-sitemap',            '~> 1.4'
end

# Windows and JRuby does not include zoneinfo files, so bundle the tzinfo-data gem
# and associated library.
platforms :windows, :jruby do
  gem 'tzinfo', '>= 1', '< 3'
  gem 'tzinfo-data'
end

# Performance-booster for watching directories on Windows
gem 'wdm', '~> 0.1.1', platforms: %i[windows]

# Lock `http_parser.rb` gem to `v0.6.x` on JRuby builds since newer versions of the gem
# do not have a Java counterpart.
gem 'http_parser.rb', '~> 0.6.0', platforms: [:jruby]
