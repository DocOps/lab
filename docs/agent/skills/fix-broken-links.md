# Fix Broken Links

This document is intended for AI agents operating within a DocOps Lab environment.

Original sources for this document include:

<!-- detect the origin url based on the slug (origin) -->
- [Fix Broken Links](/docs/agent/fix-broken-links/)

A systematic approach to debugging and fixing broken links in DocOps Lab websites or sites generated with DocOps Lab tooling.

Due to complex sourcing procedures at work in DocOps Lab projects, where a particular link comes from is not always obvious.

This guide focuses on the methodologies for tracing link sources rather than specific solutions, making it applicable across different Jekyll/AsciiDoc sites.

Table of Contents

- Common Link Failure Patterns
  - External Link Failures
  - Internal Link Failures
- Debugging Methodology
  - Step 1: Run HTMLProofer and Categorize Failures
  - Step 2: Identify High-Impact Patterns
  - Step 3: Trace Link Sources
  - Step 4: Apply Appropriate Fix Strategy
- Data-Driven Link Debugging
  - YAML Data Sources
  - Dependency Tracing Process
  - Example Trace: AsciiDocsy Links
- Pre-Publication Link Strategy
- Validation and Testing
  - Rebuild and Verify
  - Test Cycle
- Prevention Strategies
  - Development Practices
  - Configuration Management

## Common Link Failure Patterns

### External Link Failures

<dl>
<dt class="hdlist1">Network timeouts</dt>
<dd>
Temporary connectivity issues that resolve after rebuild
</dd>
<dt class="hdlist1">404 errors</dt>
<dd>
Missing pages or incorrect URLs
</dd>
<dt class="hdlist1">Pre-publication links</dt>
<dd>
Links to repositories or resources not yet available
</dd>
<dt class="hdlist1">Malformed URLs</dt>
<dd>
Missing repository names or incorrect paths
</dd>
</dl>

### Internal Link Failures

<dl>
<dt class="hdlist1">Missing project anchors</dt>
<dd>
Data/template mismatches in generated content
</dd>
<dt class="hdlist1">Section anchor mismatches</dt>
<dd>
ID generation vs link target differences
</dd>
<dt class="hdlist1">Template variable errors</dt>
<dd>
Unprocessed variables in URLs
</dd>
<dt class="hdlist1">Missing pages</dt>
<dd>
Links to pages that don’t exist
</dd>
</dl>

## Debugging Methodology

### Step 1: Run HTMLProofer and Categorize Failures

Run link validation

```
bundle exec rake labdev:lint:html 2>&1 | tee .agent/scratch/link-failures.txt
```

Extract external failure patterns

```
grep "External link.*failed" .agent/scratch/link-failures.txt | wc -l
```

Extract internal failure patterns

```
grep "internally linking" .agent/scratch/link-failures.txt | wc -l
```

### Step 2: Identify High-Impact Patterns

Look for repeated failures across multiple pages:

- Same broken link appearing on 3+ pages = template/data issue

- Similar link patterns = systematic problem

- Timeout clusters = network/rebuild issue

### Step 3: Trace Link Sources

#### For Missing Anchors (Internal Links and X-refs)

If the problem is an anchor that does not exist, either the pointer or the anchor must be wrong.

<dl>
<dt class="hdlist1"> **Consider how the page was generated:** </dt>
<dd>
- Is it a standard `.adoc` file?

- Is it a Liquid-rendered HTML page?

- Is it a Liquid-rendered AsciiDoc file (usually `*.adoc.liquid` or `*.asciidoc`)
</dd>
<dt class="hdlist1"> **For standard AsciiDoc files…​** </dt>
<dd>
The offending link source will likely be:

1. an AsciiDoc xref (`<<anchor-slug>>` or `xref:anchor-slug[]`)

2. a pre-generated xref in the form of an attribute placeholder (`{xref_scope_anchor-slug_link}`) that has resolved to a proper AsciiDoc xref

3. a hybrid reference (`link:{xref_scope_anchor-slug_url}[some text]`)

In any case, the `anchor-slug` portion should correspond literally to the reported missing anchor. If these are rendering properly and do not contain obvious misspellings, consider how the intended target might be misspelled or missing and address the source of the anchor itself.
</dd>
<dt class="hdlist1"> **For Liquid-rendered pages…​** </dt>
<dd>
The offending link source will likely be a misspelled or poorly constructed link.

1. a hard-coded link in Liquid/HTML (`"a href="#anchor-slug">`)

2. a data-driven link in Liquid/HTML (`"a href="#{{ variable | slugify }}">`)

3. a data-driven link in Liquid/AsciiDoc (`link:#{{ variable | slugify }}`)

4. a pre-generated xref in the form of an attribute placeholder (`{xref_some-scope_some-slug-string_link}`; generated from Liquid such as: `{xref_{{ scope }}_{{ variable }}_link}`)

Other than for hard-coded links, you will need to trace the source to one of the following:

- A YAML file, typically in a `_data/` or `data/` directory.

- Attributes derived from a file like `README.adoc`.
</dd>
<dt class="hdlist1"> **Other tips for investigating broken anchors:** </dt>
<dd>
Check what anchors actually exist

```
grep -on 'id="[^"]*"' _site/page-slug/index.html
```

Find template generating the links

```
grep -rn "distinct identifier string" _includes _pages _templates
```
</dd>
</dl>

### Step 4: Apply Appropriate Fix Strategy

#### Option A: Fix the Data (Recommended for Project Links)

Update dependency names to match actual project slugs:

```yaml
# Before
deps: [jekyll-asciidoc-ui, AsciiDocsy]

# After
deps: [jekyll-asciidoc-ui, asciidocsy-jekyll-theme]
```

#### Option B: Fix the Template

Update link generation to use project lookup:

```liquid
{% assign dep_project = projects | where: 'slug', dep | first %}
{% unless dep_project %}{% assign dep_project = projects | where: 'name', dep | first %}{% endunless %}
<a href="/projects/#{{ dep_project.slug | default: dep | slugify }}">
```

#### Option C: Fix the Anchors/IDs

Update actual IDs to match expected links. Use this solution only when the link source is wrong or the target anchor ID is wrong where it is designated or missing.

Misspelled link source

```asciidoc
See xref:sectione-one[Section One] for details.
```

Misspelled anchor ID

```asciidoc
[[secton-one]]
=== Section One
```

## Data-Driven Link Debugging

### YAML Data Sources

Key files that commonly generate broken links:

<dl>
<dt class="hdlist1">`_data/docops-lab-projects.yml`</dt>
<dd>
Project dependencies and metadata
</dd>
<dt class="hdlist1">`_data/pages/*.yml`</dt>
<dd>
Navigation and cross-references
</dd>
<dt class="hdlist1">Individual frontmatter</dt>
<dd>
Local link definitions
</dd>
</dl>

### Dependency Tracing Process

1. **Identify the broken link pattern** : `#missing-anchor`

2. **Find the data source** : Search YAML files for dependency names

3. **Trace template processing** : Follow Liquid template logic

4. **Compare with reality** : Check actual generated IDs

5. **Apply data fix** : Update dependency to match actual slug

### Example Trace: AsciiDocsy Links

```bash
# 1. Broken link found
# internally linking to /projects/#asciidocsy

# 2. Find template source
grep -r "#asciidocsy" _includes/
# Found in: _includes/project-profile.html line 76

# 3. Check template logic
# href="/projects/#{{ dep | slugify }}"

# 4. Find data source
grep -n "AsciiDocsy" _data/docops-lab-projects.yml
# Found: deps: [..., AsciiDocsy]

# 5. Check actual anchor
grep 'id=".*asciidoc.*"' _site/projects/index.html
# Found: id="asciidocsy-jekyll-theme"

# 6. Fix: Change AsciiDocsy → asciidocsy-jekyll-theme
```

## Pre-Publication Link Strategy

For links to resources not yet available:

1. **Tag with FIXME-PREPUB** : Add comments for easy identification

2. **Document in notes** : Track what needs to be updated at publication

3. **Use conditional logic** : Hide pre-pub links in production builds

```asciidoc
// FIXME-PREPUB: Update when DocOps/box repository is published
See the link:https://github.com/DocOps/docops-box[DocOps Box repository] for details.
```

## Validation and Testing

### Rebuild and Verify

```bash
# Rebuild site with fixes
bundle exec rake build

# Re-run validation
bundle exec rake labdev:lint:html

# Check specific fix
grep "#fixed-anchor" _site/target-page.html
```

### Test Cycle

1. Fix high-impact patterns first (3+ occurrences)

2. Rebuild and validate after each batch of fixes

3. Document fixes for future reference

4. Test both internal and external link resolution

## Prevention Strategies

### Development Practices

<dl>
<dt class="hdlist1">Consistent naming</dt>
<dd>
Align dependency names with actual project slugs
</dd>
<dt class="hdlist1">Template validation</dt>
<dd>
Test link generation logic with sample data
</dd>
<dt class="hdlist1">Documentation standards</dt>
<dd>
Document expected anchor patterns
</dd>
<dt class="hdlist1">Regular validation</dt>
<dd>
Include link checking in CI/CD pipelines
</dd>
</dl>

### Configuration Management

<dl>
<dt class="hdlist1">Default values</dt>
<dd>
Define link patterns in configuration rather than hardcoding
</dd>
<dt class="hdlist1">Validation rules</dt>
<dd>
Create checks for common link anti-patterns
</dd>
<dt class="hdlist1">Documentation</dt>
<dd>
Maintain mapping between logical names and actual slugs
</dd>
</dl>

This systematic approach transforms broken link debugging from a frustrating manual process into a predictable, methodical workflow that scales across projects and team members.

