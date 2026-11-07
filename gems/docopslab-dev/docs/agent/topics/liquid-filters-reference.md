# Liquid Filters Reference for DocOps Lab Projects

This document is intended for AI agents operating within a DocOps Lab environment.

Custom AsciiSourcerer/DocOps Lab filters are located under `## Filters from AsciiSourcerer` below.

Table of Contents

- Filters from Jekyll
- Filters from AsciiSourcerer
- Filters from Shopify
- Filters from schemagraphy
- Filters from jekyll-asciidoc

## Filters from Jekyll

**Date to XML Schema (`date_to_xml_schema`):**
   Convert a Date into XML Schema (ISO 8601) format.

   **Category:** Date Formatting

   **Examples:**
      Input

      ```twig
      {{ "2008-11-07 1:07:54pm" | date_to_xmlschema }}
      ```

      Output

      ```yaml
      2008-11-07T13:07:54-08:00
      ```

**Date to RFC-822 Format (`date_to_rfc822`):**
   Convert a Date into the RFC-822 format used for RSS feeds.

   **Category:** Date Formatting

   **Examples:**
      Input

      ```twig
      {{ data.time | date_to_rfc822 }}
      ```

      Output

      ```yaml
      Fri, 07 Nov 2008 13:07:54 -0800
      ```

**Date to String (`date_to_string`):**
   Convert a date to short format.

   **Category:** Date Formatting

   **Examples:**
      Input

      ```twig
      {{ data.time | date_to_string }}
      ```

      Output

      ```yaml
      07 Nov 2008
      ```

      Input

      ```twig
      {{ data.time | date_to_string: "ordinal", "US" }}
      ```

      Output

      ```yaml
      Nov 7th, 2008
      ```

**Date to Long String (`date_to_long_string`):**
   Format a date to long format.

   **Category:** Date Formatting

   **Examples:**
      Input

      ```twig
      {{ data.time | date_to_long_string }}
      ```

      Output

      ```yaml
      07 November 2008
      ```

      Input

      ```twig
      {{ data.time | date_to_long_string: "ordinal" }}
      ```

      Output

      ```yaml
      7th November 2008
      ```

**Where (`where`):**
   Select all the objects in an array where the key has the given value.

   **Category:** Array Selection

   **Examples:**
      Input

      ```twig
      {% assign filtered = data.users | where:"level", 2 %}
      {{ filtered | size }}
      ```

      Output

      ```yaml
      1
      ```

      Input

      ```twig
      {% assign member = data.users | where:"user","alice" %}
      {{ member[0] | jsonify }}
      ```

      Output

      ```yaml
      {"user":"alice","level":1}
      ```

**Where Expression (`where_exp`):**
   Select all the objects in an array where the expression is true.

   **Category:** Array Selection

   **Examples:**
      Input

      ```twig
      {{ data.members | where_exp:"item",
      "item.grad_year == 2014" | jsonify }}
      ```

      Output

      ```yaml
      [{"user":"andie","grad_year":2014,"projects":["fooman","barbaz"]},{"user":"lonnie","grad_year":2014,"projects":["fooman"]}]
      ```

      Input

      ```twig
      {{ data.members | where_exp:"item",
      "item.grad_year < 2014" | jsonify }}
      ```

      Output

      ```yaml
      [{"user":"cindy","grad_year":2012,"projects":["fooman","foobar"]}]
      ```

      Input

      ```twig
      {{ data.members | where_exp:"item",
      "item.projects contains 'barbaz'" | jsonify }}
      ```

      Output

      ```yaml
      [{"user":"andie","grad_year":2014,"projects":["fooman","barbaz"]}]
      ```

**Group By (`group_by`):**
   Group an array’s items by a given property.

   **Category:** Array Organizing

   **Examples:**
      Input

      ```twig
      {% assign grouped = data.members | group_by:"grad_year" | first %}
      {{ grouped.name }}
      ```

      Output

      ```yaml
      2014
      ```

**Group By Expression (`group_by_exp`):**
   Group an array’s items using a Liquid expression.

   **Category:** Array Organizing

   **Examples:**
      Input

      ```twig
      {{ data.members | group_by_exp: "item", "item.grad_year" | map: "name" | join: "," }}
      ```

      Output

      ```yaml
      2014,2012
      ```

**XML Escape (`xml_escape`):**
   Escape some text for use in XML.

   **Category:** String Escaping

   **Examples:**
      Input

      ```twig
      {{ "<strong>some text</strong>" | xml_escape }}
      ```

      Output

      ```yaml
      &lt;strong&gt;some text&lt;/strong&gt;
      ```

**CGI Escape (`cgi_escape`):**
   CGI escape a string for use in a URL. Replaces any special characters with appropriate `%XX` replacements. CGI escape normally replaces a space with a plus `+` sign.

   **Category:** String Escaping

   **Examples:**
      Input

      ```twig
      {{ "foo, bar; baz?" | cgi_escape }}
      ```

      Output

      ```yaml
      foo%2C+bar%3B+baz%3F
      ```

**URI Escape (`uri_escape`):**
   Percent encodes any special characters in a URI. URI escape normally replaces a space with `%20`.[Reserved characters](https://en.wikipedia.org/wiki/Percent-encoding#Types_of_URI_characters)will not be escaped.

   **Category:** String Escaping

   **Examples:**
      Input

      ```twig
      {{ "http://foo.com/?q=foo, \bar?" | uri_escape }}
      ```

      Output

      ```yaml
      http://foo.com/?q=foo,%20%5Cbar?
      ```

**Number of Words (`number_of_words`):**
   Count the number of words in a text.

   **Category:** String Analysis

   **Examples:**
      Input

      ```twig
      {{ page.content | number_of_words }}
      ```

      Output

      ```yaml
      3
      ```

**Array to Sentence (`array_to_sentence_string`):**
   Convert an array into a sentence. Useful for listing tags. Optional argument for connector.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {{ tags_array | array_to_sentence_string }}
      ```

      Output

      ```yaml
      foo, bar, and baz
      ```

      Input

      ```twig
      {{ tags_array | array_to_sentence_string: "or" }}
      ```

      Output

      ```yaml
      foo, bar, or baz
      ```

**Data To JSON (`jsonify`):**
   Convert Hash or Array to JSON.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {{ tags_array | jsonify }}
      ```

      Output

      ```yaml
      ["foo","bar","baz"]
      ```

**Normalize Whitespace (`normalize_whitespace`):**
   Replace any occurrence of whitespace with a single space.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "a b" | normalize_whitespace }}
      ```

      Output

      ```yaml
      a b
      ```

**Sort (`sort`):**
   Sort an array. Optional arguments for hashes 1. property name 2. nils order (_first_ or _last_).

   **Category:** Array Organizing

   **Examples:**
      Input

      ```twig
      {{ page.tags | sort | inspect }}
      ```

      Output

      ```yaml
      [&quot;Seattle&quot;, &quot;Spokane&quot;, &quot;Tacoma&quot;]
      ```

      Input

      ```twig
      {{ site.posts | sort: "author" }}
      ```

      Input

      ```twig
      {{ site.pages | sort: "title", "last" }}
      ```

**Sample (`sample`):**
   Pick a random value from an array. Optionally, pick multiple values.

   **Category:** Array Selection

   **Examples:**
      Input

      ```twig
      {{ site.pages | sample }}
      ```

      Input

      ```twig
      {{ site.pages | sample: 2 }}
      ```

**To Integer (`to_integer`):**
   Convert a string or boolean to integer.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {{ true | to_integer }}
      ```

      Output

      ```yaml
      1
      ```

      Input

      ```twig
      {% assign five = "5" | to_integer %}
      {% if five == 5 %}Samesies!{% endif %}
      ```

      Output

      ```yaml
      Samesies!
      ```

      Input

      ```twig
      {{ "five" | to_integer }}
      ```

      Output

      ```yaml
      0
      ```

**Push (`push`):**
   Insert an item at the end of an array

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {{ page.tags | push: "Spokane" | inspect }}
      ```

      Output

      ```yaml
      [&quot;Seattle&quot;, &quot;Tacoma&quot;, &quot;Spokane&quot;, &quot;Spokane&quot;]
      ```

**Pop (`pop`):**
   Remove an item from the end of an array

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {{ page.tags | pop | inspect }}
      ```

      Output

      ```yaml
      [&quot;Seattle&quot;, &quot;Tacoma&quot;]
      ```

**Shift (`shift`):**
   Remove an item from the beginning of an array

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {{ page.tags | shift | inspect }}
      ```

      Output

      ```yaml
      [&quot;Tacoma&quot;, &quot;Spokane&quot;]
      ```

**Unshift (`unshift`):**
   Insert an item at the beginning of an array

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {{ page.tags | unshift: "Olympia" | inspect }}
      ```

      Output

      ```yaml
      [&quot;Olympia&quot;, &quot;Seattle&quot;, &quot;Tacoma&quot;, &quot;Spokane&quot;]
      ```

**Relative URL (`relative_url`):**
   Prepend `baseurl` config value to the input to convert a URL path into a relative URL. This is recommended for a site that is hosted on a subpath of a domain.

   > **NOTE:** <table>
   > <tr>
   > <td>
   > <i class="fa icon-note" title="Note"></i>
   > </td>
   > <td>
   > Requires registration of a <code>site.baseurl</code> object outside <code>jekyll build</code> contexts.
   > </td>
   > </tr>
   > </table>

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "test-path" | relative_url }}
      ```

      Output

      ```yaml
      /docs/test-path
      ```

**Absolute URL (`absolute_url`):**
   Prepend `url` and `baseurl` values to the input to convert a URL path to an absolute URL.

   > **NOTE:** <table>
   > <tr>
   > <td>
   > <i class="fa icon-note" title="Note"></i>
   > </td>
   > <td>
   > Requires registration of <code>site.baseurl</code> and <code>site.url</code> objects outside <code>jekyll build</code> contexts.
   > </td>
   > </tr>
   > </table>

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "test-path" | absolute_url }}
      ```

      Output

      ```yaml
      https://example.com/docs/test-path
      ```

**Markdownify (`markdownify`):**
   Converts a Markdown string to HTML.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Test with **bold** and a [link](https://example.com)." | markdownify }}
      ```

      Output

      ```yaml
      <p>Test with <strong>bold</strong> and a <a href="https://example.com">link</a>.</p>
      ```

**Smartify (`smartify`):**
   Convert "quotes" into “smart quotes.”

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ 'He said, "Hello!"' | smartify }}
      ```

      Output

      ```yaml
      He said, “Hello!”
      ```

**Sassify (`sassify`):**
   Convert an indented-syntax Sass string into CSS.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ sass_text | sassify }}
      ```

      Output

      ```yaml
      body {
        color: red;
      }
      ```

**Scssify (`scssify`):**
   Convert a SCSS-formatted (brace/semicolon syntax) string into CSS.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ scss_text | scssify }}
      ```

      Output

      ```yaml
      body {
        color: red;
      }
      ```

## Filters from AsciiSourcerer

**Slugify (`slugify`):**
   Convert a string into a lowercase URL "slug".

   > **NOTE:** <table>
   > <tr>
   > <td>
   > <i class="fa icon-note" title="Note"></i>
   > </td>
   > <td>
   > This is not the Jekyll version.
   > </td>
   > </tr>
   > </table>

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "The _config.yml file" | slugify }}
      ```

      Output

      ```yaml
      the-config-yml-file
      ```

      Input

      ```twig
      {{ "The _config.yml file" | slugify: "_" }}
      ```

      Output

      ```yaml
      the_config_yml_file
      ```

**Inspect (`inspect`):**
   Convert an object into its String representation for debugging. Overrides Jekyll’s `inspect` filter, adding an optional `format` argument:`html` (default) reproduces Jekyll’s own behavior exactly (an HTML-escaped`Object#inspect` string, quotes become `"`); `yaml` and `json` render the object in those formats instead.

   **Category:** Object Analysis

   **Examples:**
      Example 1. Default (html) format, matches Jekyll’s inspect

      Input

      ```twig
      {{ tags_array | inspect }}
      ```

      Output

      ```yaml
      [&quot;foo&quot;, &quot;bar&quot;, &quot;baz&quot;]
      ```

      Example 2. YAML format

      Input

      ```twig
      {{ tags_array | inspect: "yaml" }}
      ```

      Output

      ```yaml
      ---
      - foo
      - bar
      - baz
      ```

      Example 3. JSON format

      Input

      ```twig
      {{ tags_array | inspect: "json" }}
      ```

      Output

      ```yaml
      ["foo","bar","baz"]
      ```

**Sum (`sum`):**
   Sums a numeric array, or an array of Hashes at the given property.

   (This filter duplicates Shopify’s `sum` filter.)

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ data.members | sum: "grad_year" }}
      ```

      Output

      ```yaml
      6040
      ```

**Remove Last (`remove_last`):**
   Removes the last instance of a substring from a string.

   (This filter duplicates Shopify’s `remove_last` filter.)

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Ground control to Major Tom." | remove_last: "o" }}
      ```

      Output

      ```yaml
      Ground control to Major Tm.
      ```

**Replace Last (`replace_last`):**
   Replaces the last instance of a substring in a string with a replacement.

   (This filter duplicates Shopify’s `replace_last` filter.)

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Ground control to Major Tom." | replace_last: "o", "0" }}
      ```

      Output

      ```yaml
      Ground control to Major T0m.
      ```

**Squish (`squish`):**
   Strips leading and trailing whitespace and collapses interior runs of whitespace to a single space.

   (This filter duplicates Liquid 5’s `squish` filter.)

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ " A string that is obviously longer than 25 characters " | squish }}
      ```

      Output

      ```yaml
      A string that is obviously longer than 25 characters
      ```

**Wrap (`wrap`):**
   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "A string that is obviously longer than 25 characters" | wrap: 25 }}
      ```

      Output

      ```yaml
      A string that is
      obviously longer than 25
      characters
      ```

**Comment Wrap (`commentwrap`):**
   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ comment_text | commentwrap: 25, "// " }}
      ```

      Output

      ```yaml
      // A string that is
      // obviously longer than 25
      // characters
      ```

      Input

      ```twig
      {{ comment_text | commentwrap: 25, "xml" }}
      ```

      Output

      ```yaml
      <!-- A string that is
      obviously longer than 25
      characters -->
      ```

      Input

      ```twig
      {{ comment_text | commentwrap: 25, "/*|*/" }}
      ```

      Output

      ```yaml
      /* A string that is
      obviously longer than 25
      characters
      */
      ```

**Convert to CLI Arguments (`to_cli_args`):**
   Transform a Hash into a string of CLI-formatted arguments. Accepts an optional template name to format the output. See `parameters` section for all available templates and their output formats. When no template is specified, defaults to `long_space` format. Arguments are joined with a space by default; can be customized via delimiter parameter.

   **Category:** Object Conversion

   **Examples:**
      Example 4. Default (long\_space) format

      Input

      ```twig
      {{ my_flat_hash | to_cli_args }}
      ```

      Output

      ```yaml
      --key1 valuu_one --key2 val_two --key3 third value
      ```

      Example 5. Long equals format

      Input

      ```twig
      {{ my_flat_hash | to_cli_args: "long_equals" }}
      ```

      Output

      ```yaml
      --key1=valuu_one --key2=val_two --key3=third value
      ```

      Example 6. Single-letter flags with values

      Input

      ```twig
      {{ cli_flags_hash | to_cli_args: "short_space" }}
      ```

      Output

      ```yaml
      -k valuu_one -v val_two -o third value
      ```

      Example 7. Positional arguments only

      Input

      ```twig
      {{ my_flat_hash | to_cli_args: "positional" }}
      ```

      Output

      ```yaml
      valuu_one val_two third value
      ```

      Example 8. Environment variable format (uppercase keys)

      Input

      ```twig
      {{ my_flat_hash | to_cli_args: "env_arg" }}
      ```

      Output

      ```yaml
      KEY1=valuu_one KEY2=val_two KEY3=third value
      ```

      Example 9. Key=value format

      Input

      ```twig
      {{ my_flat_hash | to_cli_args: "keyval" }}
      ```

      Output

      ```yaml
      key1=valuu_one key2=val_two key3=third value
      ```

**Data objects to YAML (`to_yaml`):**
   Turn any parameter or data object into YAML format.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {{ my_flat_hash | to_yaml }}
      ```

      Output

      ```yaml
      ---
      key1: valuu_one
      key2: val_two
      key3: third value
      ```

      Input

      ```twig
      {{ my_flat_hash | to_yaml: "flow" }}
      ```

      Output

      ```yaml
      {key1: "valuu_one", key2: "val_two", key3: "third value"}
      ```

      Input

      ```twig
      {{ page.tags | to_yaml }}
      ```

      Output

      ```yaml
      ---
      - Seattle
      - Tacoma
      - Spokane
      ```

      Input

      ```twig
      {{ page.tags | to_yaml: "flow" }}
      ```

      Output

      ```yaml
      ["Seattle", "Tacoma", "Spokane"]
      ```

      Input

      ```twig
      {{ page.tags | to_yaml: "flow", "quotes" }}
      ```

      Output

      ```yaml
      ["Seattle", "Tacoma", "Spokane"]
      ```

**Data objects to JSON (`to_json`):**
   Turn any parameter or data object into JSON format.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {{ my_flat_hash | to_json }}
      ```

      Output

      ```yaml
      {"key1":"valuu_one","key2":"val_two","key3":"third value"}
      ```

      Input

      ```twig
      {{ page.tags | to_json }}
      ```

      Output

      ```yaml
      ["Seattle","Tacoma","Spokane"]
      ```

      Input

      ```twig
      {{ odd_keys_hash | to_json }}
      ```

      Output

      ```yaml
      {"key 1":"valuu_one","$key2":"val_two","key:3":"third value"}
      ```

**Regular Expression Replace (`replace_regex`):**
   Use regular expressions to match and replace text patterns.

   **Category:** String Management

   **Examples:**
      Input

      ```twig
      {{ "hello world" | replace_regex: "world", "there" }}
      ```

      Output

      ```yaml
      hello there
      ```

      Input

      ```twig
      {{ "one,two,three" | replace_regex: ",", "-" }}
      ```

      Output

      ```yaml
      one-two-three
      ```

**Pattern Match (`match`):**
   Returns of string or number matches pattern.

   **Category:** String Analysis

   **Examples:**
      Input

      ```twig
      {% assign matched = "testword" | match: "^.*word$" %}
      {% if matched %}It matched!{% endif %}
      ```

      Output

      ```yaml
      It matched!
      ```

**Holds Liquid (`holds_liquid`):**
   Returns true if a snippet of text contains Liquid markup tags.

   **Category:** Object Analysis

   **Examples:**
      Input

      ```twig
      {{ liquidy_text | holds_liquid }}
      ```

      Output

      ```yaml
      true
      ```

      Input

      ```twig
      {{ "This is just text." | holds_liquid }}
      ```

      Output

      ```yaml
      false
      ```

**Metastore list concat (`store_list_concat`):**
   Concatenates each Array-formatted value of the same-named property across all nodes in an Array of Hashes (Metastore). Accepts an Array of Hashes and the keyname of a property to collect from.

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {{ data.metastore | store_list_concat: "children" | jsonify }}
      ```

      Output

      ```yaml
      ["child1","child2","child3","child4","child5","child6"]
      ```

**Metastore list duplicates (`store_list_dupes`):**
   Returns a list of duplicate items among multiple Arrays across multiple same-named properties in an Array of Hashes (Metastore). Accepts an Array of Hashes and the keyname of a Scalar property to check; returns the names of duplicate properties.

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {{ data.metastore | store_list_dupes: "children" | jsonify }}
      ```

      Output

      ```yaml
      ["child1"]
      ```

## Filters from Shopify

**Absolute Value (`abs`):**
   Returns the absolute value of a number.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ -17 | abs }}
      ```

      Output

      ```yaml
      17
      ```

      Input

      ```twig
      {{ "-19.86" | abs }}
      ```

      Output

      ```yaml
      19.86
      ```

**Append (`append`):**
   Adds the specified string to the end of another string.

   **Category:** String Management

   **Examples:**
      Input

      ```twig
      {{ "/my/fancy/url" | append: ".html" }}
      ```

      Output

      ```yaml
      /my/fancy/url.html
      ```

**At Least (`at_least`):**
   Limits a number to a minimum value; returns the input unchanged if it’s already at or above the minimum.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 4 | at_least: 5 }}
      ```

      Output

      ```yaml
      5
      ```

      Input

      ```twig
      {{ 4 | at_least: 3 }}
      ```

      Output

      ```yaml
      4
      ```

**At Most (`at_most`):**
   Limits a number to a maximum value; returns the input unchanged if it’s already at or below the maximum.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 4 | at_most: 5 }}
      ```

      Output

      ```yaml
      4
      ```

      Input

      ```twig
      {{ 4 | at_most: 3 }}
      ```

      Output

      ```yaml
      3
      ```

**Capitalize (`capitalize`):**
   Capitalizes the first character of a string and downcases the rest. Only the first character is affected, so later words are not capitalized.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "my GREAT title" | capitalize }}
      ```

      Output

      ```yaml
      My great title
      ```

**Ceiling (`ceil`):**
   Rounds a number up to the nearest whole number. Liquid tries to convert the input to a number before applying the filter.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 1.2 | ceil }}
      ```

      Output

      ```yaml
      2
      ```

**Compact (`compact`):**
   Removes any `nil` values from an array.

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {% assign compacted = mixed_array | compact %}
      {{ compacted | join: "," }}
      ```

      Output

      ```yaml
      a,b,c
      ```

**Concatenate (`concat`):**
   Concatenates (joins together) multiple arrays. The resulting array contains all the items from the input arrays.

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {% assign fruits = "apples, oranges" | split: ", " %}
      {% assign veggies = "carrots, turnips" | split: ", " %}
      {{ fruits | concat: veggies | join: "," }}
      ```

      Output

      ```yaml
      apples,oranges,carrots,turnips
      ```

**Date Format (`date`):**
   Converts a timestamp into another date format, using the same format syntax as `strftime`.

   **Category:** Date Formatting

   **Examples:**
      Input

      ```twig
      {{ data.time | date: "%Y-%m-%d" }}
      ```

      Output

      ```yaml
      2008-11-07
      ```

**Default (`default`):**
   Sets a fallback value for a variable that is `nil`, `false`, or empty. Has no effect if the input already has a value.

   **Category:** Variable Defaults

   **Examples:**
      Input

      ```twig
      {{ nonexistent_var | default: "fallback" }}
      ```

      Output

      ```yaml
      fallback
      ```

**Divided By (`divided_by`):**
   Divides a number by another number. The result’s type matches the divisor’s: dividing by an integer floors to an integer, dividing by a float returns a float.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 16 | divided_by: 4 }}
      ```

      Output

      ```yaml
      4
      ```

      Input

      ```twig
      {{ 20 | divided_by: 7 }}
      ```

      Output

      ```yaml
      2
      ```

      Input

      ```twig
      {{ 20 | divided_by: 7.0 }}
      ```

      Output

      ```yaml
      2.857142857142857
      ```

**Downcase (`downcase`):**
   Makes each character in a string lowercase.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Parker Moore" | downcase }}
      ```

      Output

      ```yaml
      parker moore
      ```

**Escape (`escape`):**
   Escapes a string’s HTML-unsafe characters (so it can safely be embedded in HTML markup).

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Have you read 'James & the Giant Peach'?" | escape }}
      ```

      Output

      ```yaml
      Have you read &#39;James &amp; the Giant Peach&#39;?
      ```

**Escape Once (`escape_once`):**
   Escapes a string’s HTML-unsafe characters without double-escaping entities that are already escaped.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "1 < 2 & 3" | escape_once }}
      ```

      Output

      ```yaml
      1 &lt; 2 &amp; 3
      ```

      Input

      ```twig
      {{ "1 &lt; 2 &amp; 3" | escape_once }}
      ```

      Output

      ```yaml
      1 &lt; 2 &amp; 3
      ```

**First (`first`):**
   Returns the first item of an array.

   **Category:** Array Selection

   **Examples:**
      Input

      ```twig
      {{ "Ground control to Major Tom." | split: " " | first }}
      ```

      Output

      ```yaml
      Ground
      ```

**Floor (`floor`):**
   Rounds a number down to the nearest whole number. Liquid tries to convert the input to a number before applying the filter.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 1.2 | floor }}
      ```

      Output

      ```yaml
      1
      ```

**Join (`join`):**
   Combines the items in an array into a single string, using the argument as a separator.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {% assign beatles = "John, Paul, George, Ringo" | split: ", " %}
      {{ beatles | join: " and " }}
      ```

      Output

      ```yaml
      John and Paul and George and Ringo
      ```

**Last (`last`):**
   Returns the last item of an array.

   **Category:** Array Selection

   **Examples:**
      Input

      ```twig
      {{ "Ground control to Major Tom." | split: " " | last }}
      ```

      Output

      ```yaml
      Tom.
      ```

**Left Strip (`lstrip`):**
   Removes whitespace (tabs, spaces, newlines) from the left side of a string. Does not affect spaces between words.

   **Category:** String Management

   **Examples:**
      Input

      ```twig
      {{ " So much room " | lstrip }}!
      ```

      Output

      ```yaml
      So much room !
      ```

**Map (`map`):**
   Creates an array of values by extracting the values of a named property from an array of objects.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {{ data.members | map: "user" | join: "," }}
      ```

      Output

      ```yaml
      andie,lonnie,cindy
      ```

**Minus (subtract) (`minus`):**
   Subtracts a number from another number.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 4 | minus: 2 }}
      ```

      Output

      ```yaml
      2
      ```

      Input

      ```twig
      {{ 16 | minus: 4 }}
      ```

      Output

      ```yaml
      12
      ```

**Modulo (`modulo`):**
   Returns the remainder of a division operation.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 3 | modulo: 2 }}
      ```

      Output

      ```yaml
      1
      ```

      Input

      ```twig
      {{ 24 | modulo: 7 }}
      ```

      Output

      ```yaml
      3
      ```

**Newline to Break Tag (`newline_to_br`):**
   Inserts an HTML line break (`<br />`) in front of each newline in a string.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {% capture s %}Hello
      there{% endcapture %}{{ s | newline_to_br }}
      ```

      Output

      ```yaml
      Hello<br />
      there
      ```

**Plus (add) (`plus`):**
   Adds a number to another number.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 4 | plus: 2 }}
      ```

      Output

      ```yaml
      6
      ```

**Prepend (`prepend`):**
   Adds the specified string to the beginning of another string.

   **Category:** String Management

   **Examples:**
      Input

      ```twig
      {{ "apples, oranges, and bananas" | prepend: "Some fruit: " }}
      ```

      Output

      ```yaml
      Some fruit: apples, oranges, and bananas
      ```

**Remove (`remove`):**
   Removes every occurrence of the specified substring from a string.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "I strained to see the train through the rain" | remove: "rain" }}
      ```

      Output

      ```yaml
      I sted to see the t through the
      ```

**Remove First (`remove_first`):**
   Removes only the first occurrence of the specified substring from a string.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "I strained to see the train through the rain" | remove_first: "rain" }}
      ```

      Output

      ```yaml
      I sted to see the train through the rain
      ```

**Replace (`replace`):**
   Replaces every occurrence of the first argument in a string with the second argument.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Take my protein pills and put my helmet on" | replace: "my", "your" }}
      ```

      Output

      ```yaml
      Take your protein pills and put your helmet on
      ```

**Replace First (`replace_first`):**
   Replaces only the first occurrence of the first argument in a string with the second argument.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Take my protein pills and put my helmet on" | replace_first: "my", "your" }}
      ```

      Output

      ```yaml
      Take your protein pills and put my helmet on
      ```

**Reverse (`reverse`):**
   Reverses the order of the items in an array. Cannot reverse a string directly; split it into an array first.

   **Category:** Array Organizing

   **Examples:**
      Input

      ```twig
      {% assign arr = "apples, oranges, peaches, plums" | split: ", " %}
      {{ arr | reverse | join: ", " }}
      ```

      Output

      ```yaml
      plums, peaches, oranges, apples
      ```

**Round (`round`):**
   Rounds a number to the nearest integer, or to a given number of decimal places if an argument is passed.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 1.2 | round }}
      ```

      Output

      ```yaml
      1
      ```

      Input

      ```twig
      {{ 2.7 | round }}
      ```

      Output

      ```yaml
      3
      ```

      Input

      ```twig
      {{ 183.357 | round: 2 }}
      ```

      Output

      ```yaml
      183.36
      ```

**Right Strip (`rstrip`):**
   Removes whitespace (tabs, spaces, newlines) from the right side of a string. Does not affect spaces between words.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ " So much room " | rstrip }}!
      ```

      Output

      ```yaml
      So much room!
      ```

**Size (`size`):**
   Returns the number of characters in a string, or the number of items in an array.

   **Category:** Object Analysis

   **Examples:**
      Input

      ```twig
      {{ "Ground control to Major Tom." | size }}
      ```

      Output

      ```yaml
      28
      ```

**Slice (`slice`):**
   Returns a substring or array slice, starting at the index given by the first argument. An optional second argument gives the length. Negative indices count from the end.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {{ "Liquid" | slice: 0 }}
      ```

      Output

      ```yaml
      L
      ```

      Input

      ```twig
      {{ "Liquid" | slice: 2, 3 }}
      ```

      Output

      ```yaml
      qui
      ```

      Input

      ```twig
      {{ "Liquid" | slice: -3, 2 }}
      ```

      Output

      ```yaml
      ui
      ```

**Split (`split`):**
   Divides a string into an array using the argument as a separator. Commonly used to convert delimited text into an array.

   **Category:** Object Conversion

   **Examples:**
      Input

      ```twig
      {% assign beatles = "John, Paul, George, Ringo" | split: ", " %}
      {{ beatles | join: "|" }}
      ```

      Output

      ```yaml
      John|Paul|George|Ringo
      ```

**Strip (`strip`):**
   Removes whitespace (tabs, spaces, newlines) from both sides of a string. Does not affect spaces between words.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ " So much room " | strip }}!
      ```

      Output

      ```yaml
      So much room!
      ```

**Strip HTML (`strip_html`):**
   Removes any HTML tags from a string.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Have <em>you</em> read <strong>Ulysses</strong>?" | strip_html }}
      ```

      Output

      ```yaml
      Have you read Ulysses?
      ```

**Strip Newlines (`strip_newlines`):**
   Removes any newline characters from a string.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {% capture s %}Hello
      there{% endcapture %}{{ s | strip_newlines }}
      ```

      Output

      ```yaml
      Hellothere
      ```

**Times (multiply) (`times`):**
   Multiplies a number by another number.

   **Category:** Math Operations

   **Examples:**
      Input

      ```twig
      {{ 3 | times: 2 }}
      ```

      Output

      ```yaml
      6
      ```

**Truncate (`truncate`):**
   Shortens a string to the given number of characters. If shortened, an ellipsis (`…​`) is appended and counts against the total; pass a second argument to use a different (or no) ellipsis.

   **Category:** String Management

   **Examples:**
      Input

      ```twig
      {{ "Ground control to Major Tom." | truncate: 20 }}
      ```

      Output

      ```yaml
      Ground control to...
      ```

      Input

      ```twig
      {{ "Ground control to Major Tom." | truncate: 25, ", and so on" }}
      ```

      Output

      ```yaml
      Ground control, and so on
      ```

**Truncate Words (`truncatewords`):**
   Shortens a string to the given number of words. If shortened, an ellipsis (`…​`) is appended; pass a second argument to use a different (or no) ellipsis.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Ground control to Major Tom." | truncatewords: 3 }}
      ```

      Output

      ```yaml
      Ground control to...
      ```

**Uniq (`uniq`):**
   Removes any duplicate items from an array, preserving the first occurrence’s order.

   **Category:** Array Management

   **Examples:**
      Input

      ```twig
      {% assign arr = "ants, bugs, bees, bugs, ants" | split: ", " %}
      {{ arr | uniq | join: "," }}
      ```

      Output

      ```yaml
      ants,bugs,bees
      ```

**Upcase (`upcase`):**
   Makes each character in a string uppercase.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Parker Moore" | upcase }}
      ```

      Output

      ```yaml
      PARKER MOORE
      ```

**URL Decode (`url_decode`):**
   Decodes a string that has been encoded as a URL, or by `url_encode`.

   **Category:** String Recode

   **Examples:**
      Input

      ```twig
      {{ "%27Stop%21%27+said+Fred" | url_decode }}
      ```

      Output

      ```yaml
      'Stop!' said Fred
      ```

**URL Encode (`url_encode`):**
   Converts any URL-unsafe characters in a string into percent-encoded characters. A space becomes a `+` rather than a percent-encoded character.

   **Category:** String Recode

   **Examples:**
      Input

      ```twig
      {{ "john@liquid.com" | url_encode }}
      ```

      Output

      ```yaml
      john%40liquid.com
      ```

      Input

      ```twig
      {{ "Tetsuro Takara" | url_encode }}
      ```

      Output

      ```yaml
      Tetsuro+Takara
      ```

## Filters from schemagraphy

**SGYML Type (`sgyml_type`):**
   **Category:** data-type

## Filters from jekyll-asciidoc

**AsciiDocify (`asciidocify`):**
   Convert an AsciiDoc string to HTML, with or without paragraphing.

   **Category:** String Conversion

   **Examples:**
      Input

      ```twig
      {{ "Test with *bold* and a http://example.com[link]." | asciidocify }}
      ```

      Output

      ```yaml
      <div class="paragraph">
      <p>Test with <strong>bold</strong> and a <a href="http://example.com">link</a>.</p>
      </div>
      ```

      Input

      ```twig
      {{ "Test with *bold* and a http://example.com[link]." | asciidocify: "inline" }}
      ```

      Output

      ```yaml
      Test with <strong>bold</strong> and a <a href="http://example.com">link</a>.
      ```

