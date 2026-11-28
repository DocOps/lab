# YAML Coding Guide for DocOps Lab AI Agents

This document is intended for AI agents operating within a DocOps Lab environment.

Original sources for this document include:

<!-- detect the origin url based on the slug (origin) -->
- [YAML Styles and Conventions](/docs/yaml-styles/)
<!-- detect the origin url based on the slug (origin) -->
- [SchemaGraphy/SGYML 101](/docs/agent/schemagraphy-sgyml/)

Use these conventions when authoring, editing, or loading YAML and SGYML in DocOps Lab projects.

Table of Contents

- Indentation
- Block Strings
- Embedded Prose
- Scalars
- Data Boundary
- Agent Workflow
- Loading YAML and SGYML
- Removing Tags from Loaded Data

## Indentation

Use two spaces (never tabs) for each indentation level.

Align sibling mapping keys and sequence markers at the same level.

## Block Strings

Use the literal block indicator `|` for prose, examples, templates, and other strings that span multiple lines. Do not use folded block indicators such as `>` or `>-` as the routine house style.

Use an explicit chomping indicator only when the value’s trailing newline is part of a tested external contract.

Write one sentence per source line for prose inside a YAML block string. Do not insert arbitrary hard returns merely to constrain source width. Let sentence and structural boundaries (sometimes semicolons) determine line breaks.

Preferred

```yaml
summary: |
  The first sentence occupies one source line.
  The second sentence occupies the next source line, regardless of either sentence's length.
```

Avoid

```yaml
summary: >-
  The sentence is folded and wrapped at an
  arbitrary source-width boundary.
```

## Embedded Prose

Write user-facing prose inside YAML string nodes in AsciiDoc. Use backticks for inline literals and AsciiDoc lists, links, admonitions, and source blocks where structure requires them.

Do not introduce Markdown syntax into a YAML documentation node.

## Scalars

Use plain scalars when YAML parses the value unambiguously and the source remains readable.

Quote a scalar when it contains syntax that could change its type or structure.

Use single quotes for literal strings and double quotes only when YAML escape processing is intentional.

## Data Boundary

Store human-edited product definitions, schema-validated settings, and records with multiple generated consumers in YAML. Keep executable behavior, callbacks, classes, and callable strategies in the implementation language. Do not encode executable Ruby expressions as YAML strings except when the entirety of a block (such as a `code:` node) is intended to be treated as literal Ruby or other programming content.

## Agent Workflow

1. Preserve the distinction between source representation and parsed value when reviewing a YAML change.
2. Follow the house style for human-authored YAML even when multiple source representations would parse identically.
3. Treat prose inside YAML string nodes as AsciiDoc unless the containing format defines another markup language.
4. Use the loader provided by the target project rather than introducing a second YAML-loading path.
5. Validate both YAML parsing and the relevant schema or consumer behavior after changing structured data.

## Loading YAML and SGYML

There are two types of basic YAML loaders in SchemaGraphy, differing around whether you need to resolve AsciiDoc attributes in the content.

**`SchemaGraphy::Loader.load_yaml_with_tags`:**
   This method loads a YAML file while preserving any custom tags (e.g., `!sometag`, `!somenamespace:anothertag`). Custom tags are attached to the data structure, allowing for later processing based on those tags.

   The resulting data structure will have the original string value along with a `tag` key that contains the normalized tag name (without `!` or namespace).

**`SchemaGraphy::Loader.load_yaml_with_attributes`:**
   This method loads a YAML file and resolves AsciiDoc attribute references like `{attribute_name}`. It first loads the YAML with tags and then resolves any attribute references using the provided attributes.

## Removing Tags from Loaded Data

```ruby
require 'schemagraphy'

yaml_data = SchemaGraphy::Loader.load_yaml_with_tags('path/to/file.yaml')
original_value = SchemaGraphy::TagUtils.detag(yaml_data['some_key'])
puts original_value
```

