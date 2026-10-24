# Fix Jekyll AsciiDoc Build Errors

This document is intended for AI agents operating within a DocOps Lab environment.

As an AI agent, you can help fix Asciidoctor errors in Jekyll builds.

1. Perform a basic Jekyll build that writes verbose output to a local file.

Example with config option

```
bundle exec jekyll build --verbose --config configs/jekyll.yml > .agent/scratch/jekyll-build.log 2>&1
```

Note the `2>&1` at the end of the command, which ensures that both standard output and error messages are captured in the log file.
2. Run the analysis task on the exported file.

```
bundle exec rake 'labdev:lint:logs[jekyll-asciidoc,.agent/scratch/jekyll-build.log]'
```
3. Open the YAML file relayed in the response message (example: `Jekyll AsciiDoc issues report generated: .agent/reports/jekyll-asciidoc-issues-20251214_085323.yml`).
4. Follow the instructions in the report to address the issues found.

