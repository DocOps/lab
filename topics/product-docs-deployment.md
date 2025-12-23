# Product Documentation Deployment

This document is intended for AI agents operating within a DocOps Lab environment.

Most DocOps Lab projects have their own documentation sites, also built with Jekyll and AsciiDoc, often including YARD for Ruby API reference generation.

For less-formalized projects, documentation is restricted to `README.adoc` and other `*.adoc` files. These are hosted as GitHub Pages sites from their respective repositories, but using a consistent URL structure centered on the `docopslab.org` domain hosted here.

The URL structure is as follows:

**Project landing page** :
   `https://<project>.docopslab.org/`

   At a minimum, this should be a subset of the `README.adoc` file.

**Product user docs** :
   `https://<project>.docopslab.org/docs/`

**Product developer docs** :
   `https://.docopslab.org/docs/api/(/)`

   The final `<apiname>` directory is only applicable when the product contains multiple distinct APIs.

GH Pages configuration for these sites enables deployment by way of a clean `gh-pages` branch containing only generated documentation artifacts and the `CNAME` file.

