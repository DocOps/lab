# Liquid Templating in DocOps Lab Projects

This document is intended for AI agents operating within a DocOps Lab environment.

DocOps Lab’s Liquid 4 environment is invoked through a special bootstrapping procedure. It introduces numerous custom Liquid tags and filters.

Throughout DocOps Lab applications, Jekyll’s extended and modified version of Liquid 4 is standard.

This means all Jekyll’s filters and its special `include` tag are available within and outside Jekyll sites.

Table of Contents

- Custom Tags
- Liquid Filters
  - Custom Filters
- Liquid Syntax Styles
  - HTML Rendering Style
  - AsciiDoc Rendering Style
  - YAML Rendering Style
- Means of Invocation

## Custom Tags

Not all custom tags are always available, but the following are generally available in DocOps Lab projects:

<table class="tableblock frame-all grid-all stretch">
<caption class="title">Table 1. Table of custom tags, their source gems, and usage notes.</caption>

<thead>
<tr>
<th>Tag Name</th>
<th>Source Gem</th>
<th>Usage Notes</th>
</tr>
</thead>
<tbody>
<tr>
<td><p class="tableblock"><code>include</code></p></td>
<td><p class="tableblock">Jekyll</p></td>
<td><p class="tableblock">Transcludes the content of another file, with optional variable arguments going in but no transcendent affect on the context.</p></td>
</tr>
<tr>
<td><p class="tableblock"><code>embed</code></p></td>
<td><p class="tableblock">AsciiSourcerer</p></td>
<td><p class="tableblock">Transcludes another file, with full pass-through of variables (no arguments needed) with full write access to the context (can add/change variables permanently).</p></td>
</tr>
</tbody>
</table>

## Liquid Filters

A canonical listing of custom filters is available in the AsciiSourcerer gem at [`lib/specs/data/liquid-filters.yml`](https://github.com/DocOps/asciisourcerer/blob/main/lib/specs/data/liquid-filters.yml).

The full compendium includes _all_ filters available in Liquid 5 and Jekyll 4, even though officially Jekyll and AsciiSourcerer standardize on Liquid 4. Shopify’s novel Liquid 5 filters are hard-coded in AsciiSourcerer.

> **IMPORTANT:** <table>
> <tr>
> <td>
> <i class="fa icon-important" title="Important"></i>
> </td>
> <td>
> All other Shopify-sourced filters are conveyed directly from their Liquid 4.0.4 versions.
> </td>
> </tr>
> </table>

Where official Jekyll filters override their Liquid 4 counterparts, the Jekyll versions are used. Where an AsciiSourcerer filter overrides either upstream counterpart, the AsciiSourcerer version is used.

### Custom Filters

See `.agent/docs/topics/liquid-filters-reference.md` for a listing of filters available to projects with AsciiSourcerer available. See the section starting at `// tag::asciisourcerer[]` for custom filters available downstream of AsciiSourcerer.

## Liquid Syntax Styles

DocOps Lab contributions should standardize around certain Liquid syntax conventions, namely around indentation and integration with various markup languages we generate from templates.

### HTML Rendering Style

HTML is by far the most common output target for Liquid templates, but DocOps Lab house style prefers a certain form of indentation.

Our preference is to indent the Liquid tags in cadence with the surrounding HTML tags, so that the Liquid tags are visually aligned with the HTML they are generating.

```html
{% for item in items %}
  <div class="item">
    <h2>{{ item.title }}</h2>
    <p>
      {{ item.description }}
      {% if item.link %}
      <hr>
      <a href="{{ item.link }}">Read more</a>
      {% endif %}
    </p>
  </div>
{% endfor %}
```

### AsciiDoc Rendering Style

Because AsciiDoc does not involve much indentation, Liquid syntax meant to render AsciiDoc output is a little awkward.

Maintain left-flush, un-indented Liquid tags, but indent the tag internals to match the intended AsciiDoc output.

```asciidoc
{%- for item in items %}
{{ item.title }};;
{{ item.description }}
{%- if item.link %}
Link:;;; {{ item.link }}
{%- endif %}
{% endfor %}
```

Use left-side whitespace control (`{%-`) to avoid extra blank lines in the output, but skip it on typical `{% endfor %}` tags to ensure a blank line between iterations where it matters.

### YAML Rendering Style

YAML pre-processing with Liquid can be fairly straightforward. YAML is a great target for Liquid, even though indentation and whitespace control matter more than for HTML or AsciiDoc.

Intertwine Liquid on its own indentation scale and it should map to the YAML fairly well.

```yaml
{%- for item in items %}
- title: {{ item.title }}
  description: {{ item.description }}
  {%- if item.link %}
  link: {{ item.link }}
  {%- endif %}
{% endfor %}
```

## Means of Invocation

If you are developing a Ruby gem or app in the DocOps Lab ecosystem, the basic Jekyll/Liquid engine is invoked via the `asciisourcerer` gem.

```ruby
require 'asciisourcerer'

Sourcerer::Rendering.render_outputs([
  {
    template: 'templates/release-notes.liquid',
    data: 'data/release.yml',
    out: 'build/docs/release-notes.md',
    key: 'release',
    attrs: 'README.adoc',
    engine: 'liquid'
  },
  {
    converter: 'MyProject::JsonRenderer',
    data: 'data/release.yml',
    out: 'build/api/release.json'
  }
])
```

Direct invocation of Liquid rendering is also possible, but the above method is recommended for most use cases in DocOps Lab projects, as it provides a consistent user experience in terms of availability and behavior of tags and filters.

