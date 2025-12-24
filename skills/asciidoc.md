# AI Agent’s Guide to Writing in AsciiDoc

This document is intended for AI agents operating within a DocOps Lab environment.

Original sources for this document include:

<!-- detect the origin url based on the slug (origin) -->
- [Documentation Style Guide](/docs/asciidoc-styles/)

If you learn nothing else form this guide, learn this: DocOps Lab is an AsciiDoc shop, and we _do not_ author in Markdown; we instead try to model excellent AsciiDoc authoring and syntax.

Table of Contents

- Avoid Slop Syntax
- Automated Style Enforcement
- General AsciiDoc Syntax Guidelines
- DocOps Lab Specific Syntax Guidelines
- Inline Syntax
- Inline Semantics
      - Syntax Preferences
- Block Syntax
- Block Semantics
      - Use Delimited Blocks
      - Example Blocks
- Special Syntax
- Attributes
      - Attribute Formatting
- Vale Configuration and Usage
- Consumer Mode (Other Projects)

## Avoid Slop Syntax

The biggest mistake AI agents make when writing AsciiDoc syntax is that they slip into Markdown.

**DO NOT use Markdown** syntax or conventions when generating AsciiDoc markup.

Use AsciiDoc description-list markup instead of bulleted lists when topical or parameterized information is to be conveyed.

DO use DLs

```asciidoc
some topic or term::
The description of that term, possibly as a complete sentence or paragraph with a period.
```

DO NOT use arbitrarily formatted lists

```asciidoc
* *This kind of thing*: Followed by more information, is non-semantic.
```

Definition DO NOT do it in Markdown

```markdown
- **That awful double-asterisk notation** : Followed by a colon outside the bolding (no!) and then the "description". Just don't.
```

You will almost NEVER be asked to author in Markdown, except when leaving notes to yourself, in which case your unfortunate bias towards Markdown is acceptable.

DocOps Lab is an AsciiDoc shop. With a few exceptions, all technical documentation is sourced in AsciiDoc format using a particular (standards-compliant) syntax style.

Structured/reference documentation is typically stored in YAML-formatted files, often with AsciiDoc-formatted text blocks.

Some documentation in DocOps Lab projects is written in Markdown format, such as documents intended for AI consumption (such as for agent orientation/instruction or for RAG retrieval).

## Automated Style Enforcement

DocOps Lab projects using the `docopslab-dev` tool automatically enforce documentation style guidelines. This is done using [**Vale**](https://vale.sh), a prose and source-syntax linter.

To check documentation style:

Check prose for style issues

```
bundle exec rake labdev:lint:text
```

Check for AsciiDoc markup syntax issues

```
bundle exec rake labdev:lint:adoc
```

Check both syntax markup _and_ prose

```
bundle exec rake labdev:lint:docs
```

DocOps Lab maintains a general-audience style guide in the AYL DocStack project repository and website. That guide is reproduced here.

## General AsciiDoc Syntax Guidelines

DocOps Lab documentation largely follows the conventions outlined in the [Recommended Practices](https://asciidoctor.org/docs/asciidoc-recommended-practices/) and[Writer’s Guide](https://asciidoctor.org/docs/asciidoc-writers-guide/) documents maintained by the Asciidoctor project.

Reinforcements and exceptions:

- Use `.adoc` extensions _execpt_ for Liquid templates used to render AsciiDoc files, which use `.asciidoc`.
- Use one sentence per line formatting.

   - Let hard-returns signal spaces between sentences.
   - Also do this for major colon- or semicolon-delimited sentences.
- Use ATX-style titles and section headings.
- For DRYness, use attributes for common URLs and paths (see Attribute Formatting).

## DocOps Lab Specific Syntax Guidelines

## Inline Syntax

### Inline Semantics

The main purpose of inline semantics is to provide a clear indication of the role of the text to the reader — including artificial readers.

We can convey semantics by way of:

- declaration by element, role, or class
- text style based on declaration
- browser effects based on declaration and additional data

We use the following inline semantic coding in DocOps Lab publications.

### Syntax Preferences

Use inline semantics liberally, even if you only insert the heavier syntax on a second or third pass.

Formatting with simple `*`, `_`, and ``` characters on first drafting makes lots of sense — or even missing some of these altogether until the second pass.

But before you merge new text documents into your codebase, add role-based inline semantics wherever they are supported.

Let the reader know and make use of special text, most importantly any **verbatim inline text**.

Even if you are not ready to add such fine-grained tests to your pipeline, consider the value of having all your commands for a given runtime app labeled ahead of time (such as `.app-ruby`), and the advantage to the reader, as well.

## Block Syntax

### Block Semantics

Use semantic indicators deliberately.

The more you assert about a block of text you are writing, the better the placement and content of that block will be.

Semantic assertions reside in the source markup, which may convey means of interpreting that same data visually in the output, as an indication to the reader.

For instance, _warning_ admonitions should only deliver warning content, and the user should clearly see that a warning is interrupting the flow of the content in which it appears.

```asciidoc
[WARNING]
====
Avoid misusing or overusing admonition blocks.
====
```

Semantic notations in our source remind us to treat the content properly.

```asciidoc
[WARNING]
====
Avoid misusing or overusing admonition blocks.
This will be hypocritically violated throughout this guide.
====
```

True as it may be, the second sentence in that admonition should be removed from the block. It can either be its own block, or it can be allowed to fade into the surrounding content.

Sometimes the entire admonition may end up deserving this treatment.

### Use Delimited Blocks

Generally, use explicit boundary lines to wrap significant blocks, rather than relying on other syntax cues to establish the “type” of block is intended. These lines are called [_linewise delimiters_](https://docs.asciidoctor.org/asciidoc/latest/blocks/delimited/#linewise-delimiters).

For example, use the following syntax to wrap the contents of an admonition block:

Example 1. Example admonition block syntax with linewise delimiter

```asciidoc
[NOTE]
====
The content of an admonition block should be sandwiched between `====` lines.
Use one-sentence-per-line even in admonitions.
====
```

The standard linewise delimiters for various AsciiDoc blocks are as follows:

<table>
<tr>
<td class="hdlist1">
<code>====</code>
</td>
<td class="hdlist2">
<p>For <em>admonitions</em> and <em>examples</em></p>
</td>
</tr>
<tr>
<td class="hdlist1">
<code>----</code>
</td>
<td class="hdlist2">
<p>For code listing (verbatim) blocks</p>
</td>
</tr>
<tr>
<td class="hdlist1">
<code>....</code>
</td>
<td class="hdlist2">
<p>For literal (verbatim) blocks</p>
</td>
</tr>
<tr>
<td class="hdlist1">
<code> **** </code>
</td>
<td class="hdlist2">
<p>For sidebar blocks</p>
</td>
</tr>
<tr>
<td class="hdlist1">
<code>|===</code>
</td>
<td class="hdlist2">
<p>For tables</p>
</td>
</tr>
<tr>
<td class="hdlist1">
<code> ____ </code>
</td>
<td class="hdlist2">
<p>For quote blocks</p>
</td>
</tr>
<tr>
<td class="hdlist1">
<code>++++</code>
</td>
<td class="hdlist2">
<p>For raw/passthrough blocks</p>
</td>
</tr>
<tr>
<td class="hdlist1">
<code>--</code>
</td>
<td class="hdlist2">
<p>For open blocks</p>
</td>
</tr>
</table>

For code listings, literals, or really any block that might contain text that could be confused with the delimiter, vary the length by using a greater number of delimiter characters on the _outer_ block.

Example “example” block containing an admonition block

```asciidoc
[example]
========
[NOTE]
====
This is an example block containing an admonition block.
====
========
```

#### Exception: Brief admonitions

Some blocks do not require delimiters. In cases of _repeated_, _nearly identical_ blocks, containing just one line of content, you can use the _single-line_ syntax where it is available.

Example single-line admonition block syntax

```asciidoc
NOTE: This is a single-line admonition block.
```

**Exception to this exception** :
   We do not recommend the same-line syntax for admonition blocks other than `NOTE` and `TIP`. For `IMPORTANT`, `CAUTION`, and `WARNING`, use at least the 2-line syntax, if not explicit delimiters.

   ```asciidoc
   [IMPORTANT]
   This is a critical notice, but it's not warning you of danger.
   ```

#### Exception: Single-line terminal commands

Another common case is 1-line terminal commands, for which this guide recommends using a literal block with a `prompt` role added.

```asciidoc
[.prompt]
 echo "Hello, world!"
```

The single preceding space notation affirms the use of a literal block for any consecutive lines of content preceded by a single space. For multi-line terminal commands/output, use the `…​.` syntax to distinguish the block.

#### Exception to the exceptions

Whenever additional options must be set for a block, such as a title or role, use the linewise delimiter syntax — even in one-liner cases.

```asciidoc
[.prompt,subs="+attributes"]
....
echo "Hello, {what}!"
....
```

### Example Blocks

Use example blocks liberally. If something fits the description of being an example — especially if the words “example” or “sample” are used in the title, caption, or surrounding text referring to a given block of _anything_…​ then **wrap it in an example block**.

Instances of the following block types may commonly be instances of examples, and just as commonly they may not be.

- figures (diagrams, illustrations, screenshots)
- tables
- code listings
- literal blocks (sample prompts, logs, etc)
- rich-text snippets (rendered results, a user story, etc)

Whenever any such instances _are examples_, prepend and append them with example blocks, and prefer to title them at the exampple-block level rather than the inner-content level.

Example of a code block treated as an example

```asciidoc
:example-caption: Example

.require statement in Ruby
====
[source,ruby]
----
require 'jekyll'
----
====
```

## Special Syntax

### Attributes

### Attribute Formatting

AsciiDoc attributes are often used to store reusable matter. In certain contexts, attributes should follow a formatting convention that makes them easier to name and recall.

#### Boolean Attributes

Use toggles to set or conditionalize states such as:

- intended audience type or role

   - `audience-agent`
   - `audience-beginner`
   - ``
- target platform or format

   - `env-github`
   - `site-gen-jekyll`
   - `backend-pdf`

These kinds of attributes are passed depending on how the AsciiDoc is converted. Platform and format indicators tend to get argued by the converter at runtime.

But you can also look check for statuses that might be set in previous files depending on the use-case of the output.

Testing for _existence_ of a target platform

```asciidoc
ifdef::audience-level-beginner[]
As a beginner, you will see extra content in parts of this guide.

If you are an expert, skip to the <<expert-guide>>.
endif::[]
```

Testing for _non-existence_ of a target audience type.

```asciidoc
ifndef::audience-agent[]
This content is _not_ to appear in docs generated for AI agents.
endif::[]
```

It is generally advised to create two versions of any such indicator that may need to be resolve a variable placeholder later.

Setting open-ended key and boolean simultaneously

```asciidoc
:audience-level: beginner
:audience-level-beginner: true

Later we can reference the {audience-level}, which might be overwritten by an attribute passed at runtime.
```

#### URL Attributes

Format URL-storing attributes like so:

```asciidoc
:syntax_area_descriptive-slug_form:
```

Where:

- `syntax_` is one of

   - `href_` (external)
   - `xref_` (local)
   - none (skip it — presumed to be a straight URL)
- `area_` is a component or category like `docs_` or `pages_`, mainly to ensure unique slugs across divisions
- `form` is the way the resource is presented:

   - `link` (includes linked text _and_ the URL)
   - `url` (just the URL)

Examples

```asciidoc
:docopslab_hub_url: https://github.com/DocOps
:href_docopslab_aylstack_url: {docopslab_hub_url}/aylstack/
:href_docopslab_aylstack_link: link:{href_docopslab_aylstack_url}[AYL DocStack]
```

## Vale Configuration and Usage

Vale configuration and styles are managed in coordination with the link:`docopslab-dev` gem.

Our implementation of Vale allows for local project overrides while maintaining a centralized database of styles.

Linting for documentation quality and consistency, both AsciiDoc markup syntax and prose quality/correctness.

This tool provides a custom styles package and a modified configuration system, enabling multi-file merging.

**Base config** :
   `.config/.vendor/docopslab/vale.ini` (from source)

**Project config** :
   `.config/vale.local.ini` (inherits via `BasedOnStyles`)

**Ephemeral config** :
   `.config/vale.ini` (merged from base and target)

**Sync command** :
   `bundle exec rake labdev:sync:vale`

### Consumer Mode (Other Projects)

For all other projects, the gem works in a standard package consumption mode:

- The project’s `vale.ini` should list all desired packages, including a URL to the stable, published `DocOpsLabStyles.zip`.
- The `labdev:sync:styles` task simply runs `vale sync` in the proper context, downloading all listed packages into a local `.vale/styles` directory.

> **TIP:** The `labdev:sync:vale` task updates both the base config and the styles package.

The `.config/vale.ini` for consumer projects (based on the gem’s template) should look like this:

```ini
# CONSUMER MODE CONFIG

StylesPath = .vale/styles

# List all packages, including the URL to the central DocOpsLabStyles package.
# TODO: Update with the real URL.
Packages = RedHat, proselint, write-good, https://example.com/path/to/DocOpsLabStyles.zip

[*.adoc]
BasedOnStyles = RedHat, DocOpsLab-Authoring, DocOpsLab-AsciiDoc
```

This dual-mode system provides a robust workflow for both developing and consuming the centralized Vale styles.

> **NOTE:** For full Vale configuration settings (“keys”) reference, see [the Vale documentation](https://vale.sh/docs/vale-ini).
> **NOTE:** For information on managing DocOps Lab’s Vale styles, see [the `docopslab-dev` gem README](https://github.com/DocOps/lab/blob/main/gems/docopslab-dev/README.adoc).

