# frozen_string_literal: true

# Common helpers and setup for docopslab-dev specs.

FIXTURES_ROOT = File.expand_path('../fixtures', __dir__)
LIBRARY_FIXTURE = File.join(FIXTURES_ROOT, 'library', 'current')
GEM_ROOT_TEST = File.expand_path('../../..', __dir__)

require 'tmpdir'
require 'fileutils'
require 'json'
