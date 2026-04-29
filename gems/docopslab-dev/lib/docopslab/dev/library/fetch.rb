# frozen_string_literal: true

require 'fileutils'
require 'shellwords'
require 'tmpdir'
require 'zlib'

module DocOpsLab
  module Dev
    module Library
      # Fetches the remote asset library and installs it to the host cache.
      #
      # Fetch strategy (in order of preference):
      #   1. `gh` CLI downloads the branch via the GitHub API tarball endpoint.
      #   2. `git clone --depth=1` with sparse checkout; pulls only the library
      #      sub-tree from the remote branch.
      #
      # Auth notes:
      #   DocOps/lab is a public repository; no credentials are required.
      #   A GITHUB_TOKEN env variable can be added in a future iteration if
      #   private repo support is needed.
      module Fetch
        class << self
          # Fetch the remote library and install it to the host cache.
          #
          # config is a hash (or nil) mirroring the `library.source` manifest
          # block:
          #   { 'repo' => '...', 'branch' => '...', 'path' => '...' }
          #
          # Returns true on success, false on failure (logs a warning).
          def call config={}
            source = resolve_source(config)

            Dir.mktmpdir('docopslab-library-') do |tmpdir|
              dest = File.join(tmpdir, 'library')
              FileUtils.mkdir_p(dest)

              ok = fetch_git_content(source[:repo], source[:branch], source[:path], dest)
              unless ok
                warn '⚠️  Library fetch failed; cache not updated.'
                return false
              end

              sha = remote_head_for_source(source)
              Cache.write!(dest)
              Cache.write_head!(sha) if sha
              puts "✅ Library fetched and cached at #{Cache.current_path}"
              true
            end
          rescue StandardError => e
            warn "⚠️  Library fetch error: #{e.message}"
            false
          end

          # True if the `gh` CLI is present and executable.
          def gh_available?
            system('gh --version > /dev/null 2>&1')
          end

          # True if the `git` CLI is present and executable.
          def git_available?
            system('git --version > /dev/null 2>&1')
          end

          # Look up the current HEAD SHA for the configured remote branch.
          # Runs `git ls-remote` (requires git and network access.)
          # Returns the SHA string, or nil on failure.
          def remote_head config={}
            remote_head_for_source(resolve_source(config))
          end

          private

          def remote_head_for_source source
            url = "https://github.com/#{source[:repo]}.git"
            ref = "refs/heads/#{source[:branch]}"
            out = `git ls-remote #{Shellwords.escape(url)} #{Shellwords.escape(ref)} 2>/dev/null`
            sha = out.split("\t").first&.strip
            sha&.empty? ? nil : sha
          rescue StandardError
            nil
          end

          def resolve_source config
            src = config.is_a?(Hash) ? (config['source'] || config[:source] || {}) : {}
            raw = src['path'] || src[:path]
            {
              repo:   src['repo']   || src[:repo]   || Dev.default_library_repo,
              branch: src['branch'] || src[:branch] || Dev.default_library_branch,
              path:   raw&.to_s&.delete_suffix('/')
            }
          end

          # Route to the best available CLI tool.
          # Prefer git clone (simpler, transparent, no extraction layer).
          # Fall back to gh tarball download if git is unavailable.
          def fetch_git_content repo, branch, path, dest
            if git_available?
              fetch_via_git_clone(repo, branch, path, dest)
            elsif gh_available?
              fetch_via_gh(repo, branch, path, dest)
            else
              warn '⚠️  Neither `git` nor `gh` CLI is available. Cannot fetch library.'
              false
            end
          end

          # Use `gh api` to download the branch tarball, then extract the
          # library sub-path.
          def fetch_via_gh repo, branch, path, dest
            owner, repo_name = repo.split('/', 2)
            Dir.mktmpdir('docopslab-gh-') do |tmpdir|
              archive = File.join(tmpdir, 'library.tar.gz')
              cmd = "gh api repos/#{Shellwords.escape(owner)}/#{Shellwords.escape(repo_name)}" \
                    "/tarball/#{Shellwords.escape(branch)} " \
                    "> #{Shellwords.escape(archive)}"
              unless system(cmd)
                warn '⚠️  `gh api` call failed.'
                return false
              end
              extract_subpath_from_tarball(archive, path, dest)
            end
          end

          # Use `git clone --depth=1` to pull the library branch.
          # If +path+ is given, only that subdirectory is checked out (sparse);
          # otherwise the entire branch root is copied.
          def fetch_via_git_clone repo, branch, path, dest
            Dir.mktmpdir('docopslab-git-') do |tmpdir|
              clone_dir = File.join(tmpdir, 'clone')
              url = "https://github.com/#{repo}.git"
              clone_flags = path ? '--filter=blob:none --sparse' : ''
              clone_cmd = [
                'git clone',
                '--depth=1',
                "--branch #{Shellwords.escape(branch)}",
                clone_flags,
                Shellwords.escape(url),
                Shellwords.escape(clone_dir)
              ].reject(&:empty?).join(' ')

              unless system(clone_cmd)
                warn '⚠️  `git clone` failed.'
                return false
              end

              if path
                sparse_cmd = "git -C #{Shellwords.escape(clone_dir)} sparse-checkout set #{Shellwords.escape(path)}"
                system(sparse_cmd)
              end

              source_path = path ? File.join(clone_dir, path) : clone_dir
              unless Dir.exist?(source_path)
                warn "⚠️  Library path '#{path}' not found in remote branch."
                return false
              end

              FileUtils.cp_r("#{source_path}/.", dest)
              true
            end
          end

          # Extract all entries under `path/` from a GitHub-format tarball.
          # GitHub tarballs wrap everything in a top-level `owner-repo-SHA/`
          # prefix directory; this method strips that prefix automatically.
          def extract_subpath_from_tarball archive, path, dest
            require 'rubygems/package'

            Dir.mktmpdir('docopslab-tar-') do |extract_dir|
              Zlib::GzipReader.open(archive) do |gz|
                Gem::Package::TarReader.new(gz) do |tar|
                  tar.each do |entry|
                    parts = entry.full_name.split('/', 2)
                    next if parts.length < 2

                    relative = parts[1]
                    next if relative.empty?

                    if path
                      next unless relative.start_with?("#{path}/") || relative == path

                      local_relative = relative.delete_prefix("#{path}/")
                    else
                      local_relative = relative
                    end
                    target = File.join(extract_dir, local_relative)

                    if entry.directory?
                      FileUtils.mkdir_p(target)
                    elsif entry.file?
                      FileUtils.mkdir_p(File.dirname(target))
                      File.binwrite(target, entry.read)
                    end
                  end
                end
              end

              FileUtils.cp_r("#{extract_dir}/.", dest)
            end
            true
          rescue StandardError => e
            warn "⚠️  Tarball extraction failed: #{e.message}"
            false
          end
        end
      end
    end
  end
end
