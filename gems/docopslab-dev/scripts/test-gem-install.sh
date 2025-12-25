#!/usr/bin/env bash
# Test gem installation in clean containerized environment
# This simulates what end users will experience when installing from RubyGems.org
# Intended to be run from the gem root directory

set -e

SCRIPT_DIR="."
PKG_DIR="${SCRIPT_DIR}/pkg"

# Detect latest gem version in pkg/
latest_gem=$(find "$PKG_DIR" -name "docopslab-dev-*.gem" -type f | sort -V | tail -n 1)

if [[ -z "$latest_gem" ]]; then
  echo "ERROR: No gem files found in $PKG_DIR"
  echo "Run 'bundle exec rake gemdo:build_gem' first"
  exit 1
fi

gem_filename=$(basename "$latest_gem")
gem_version=$(echo "$gem_filename" | sed -E 's/docopslab-dev-([0-9]+\.[0-9]+\.[0-9]+)\.gem/\1/')

echo "=================================================="
echo "Testing docopslab-dev gem v${gem_version}"
echo "Gem file: ${gem_filename}"
echo "=================================================="
echo

# Test 1: Basic installation in clean Ruby environment
echo "TEST 1: Installing gem in clean ruby:3.2 container..."
docker run --rm \
  -v "${latest_gem}:/tmp/${gem_filename}:ro" \
  ruby:3.2 \
  bash -c "
    set -e
    echo '→ Installing gem from file...'
    gem install /tmp/${gem_filename}
    
    echo
    echo '→ Verifying installation...'
    gem list | grep docopslab-dev
    
    echo
    echo '→ Checking gem contents...'
    gem contents docopslab-dev | head -n 20
    
    echo
    echo '→ Testing Ruby require...'
    ruby -e \"require 'docopslab/dev'; puts 'Successfully required docopslab/dev'\"
  "

echo
echo "=================================================="
echo "✅ Basic installation test PASSED"
echo "=================================================="
echo

# Test 2: Integration test with sample project
echo "TEST 2: Testing gem in sample project context..."

# Create minimal test project structure
test_project_dir=$(mktemp -d)
trap 'rm -rf "$test_project_dir"' EXIT

cat > "${test_project_dir}/Gemfile" <<EOF
source 'https://rubygems.org'

gem 'docopslab-dev', path: '/tmp/docopslab-dev'
gem 'rake'
EOF

cat > "${test_project_dir}/Rakefile" <<'EOF'
require 'docopslab/dev'

task :test_tasks do
  puts "Testing docopslab-dev Rake tasks..."
  Rake::Task.tasks.each do |task|
    puts "  - #{task.name}"
  end
end

task default: :test_tasks
EOF

echo "→ Running bundle install and testing Rake tasks..."
docker run --rm \
  -v "${latest_gem}:/tmp/docopslab-dev/${gem_filename}:ro" \
  -v "${test_project_dir}:/workspace:rw" \
  -w /workspace \
  ruby:3.2 \
  bash -c "
    set -e
    
    # Install the gem first so bundle can find it
    gem install /tmp/docopslab-dev/${gem_filename}
    
    # Update Gemfile to use installed gem instead of path
    cat > Gemfile <<'GEMFILE'
source 'https://rubygems.org'

gem 'docopslab-dev', '${gem_version}'
gem 'rake'
GEMFILE
    
    echo '→ Installing bundle dependencies...'
    bundle install
    
    echo
    echo '→ Listing available Rake tasks...'
    bundle exec rake -T
    
    echo
    echo '→ Running custom test task...'
    bundle exec rake test_tasks
  "

echo
echo "=================================================="
echo "✅ Integration test PASSED"
echo "=================================================="
echo

echo
echo "🎉 All tests completed successfully!"
echo "The gem is ready for publication to RubyGems.org"
echo
echo "To publish:"
echo "  cd ${SCRIPT_DIR}"
echo "  gem push ${gem_filename}"
