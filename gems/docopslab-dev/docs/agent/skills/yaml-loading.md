# Loading YAML/SGYML in DocOps Lab Projects

This document is intended for AI agents operating within a DocOps Lab environment.

As an AI agent, you can help DocOps Lab developers write code that properly loads YAML and SGYML data.

There are two types of basic YAML loaders in SchemaGraphy, differing around whether you need to resolve AsciiDoc attributes in the content.

**`SchemaGraphy::Loader.load_yaml_with_tags`:**
   This method loads a YAML file while preserving any custom tags (e.g., `!sometag`, `!somenamespace:anothertag`). Custom tags are attached to the data structure, allowing for later processing based on those tags.

   The resulting data structure will have the original string value along with a `tag` key that contains the normalized tag name (without `!` or namespace).

**`SchemaGraphy::Loader.load_yaml_with_attributes`:**
   This method loads a YAML file and resolves AsciiDoc attribute references like `{attribute_name}`. It first loads the YAML with tags and then resolves any attribute references using the provided attributes.

Detagging loaded data

```ruby
require 'schemagraphy'

yaml_data = SchemaGraphy::Loader.load_yaml_with_tags('path/to/file.yaml')
original_value = SchemaGraphy::TagUtils.detag(yaml_data['some_key'])
puts original_value
```

