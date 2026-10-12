# Vendored CrossRef schema

The `crossref5.5.0/` directory is the complete XSD closure needed to validate a
CrossRef 5.5.0 `doi_batch` deposit offline — the deposit schema plus every
`include`/`import` it transitively requires (common, JATS, MathML3, xlink, and
the W3C `xml.xsd`).

## Source

- Repository: <https://gitlab.com/crossref/schema> (`schemas/`)
- Commit: `0dfa3bde531b43107b5f7e899c1a65047e22155b` (2026-09-10)

## Edits to the upstream files

Only mechanical, load-time compatibility changes were made; no schema content
(elements, types, enumerations, assertions) was removed on disk.

1. **Relative layout.** The files are flattened into `crossref5.5.0/` with the
   referenced `standard-modules/` subtree, preserving every relative
   `schemaLocation`.
2. **External `schemaLocation`s repointed (3).** Absolute W3C URLs for `xml.xsd`
   and MathML3 in `crossref5.5.0.xsd` and `common5.5.0.xsd` now point at the
   vendored `standard-modules/` copies, so no network access is needed.
3. **XML declaration normalized.** `crossref5.5.0.xsd` and `common5.5.0.xsd`
   declared `<?xml version="1.1"?>`; changed to `1.0` (they use no XML 1.1
   features) because libxml2 mishandles the 1.1 declaration.

The upstream XSD 1.1 `<xsd:assert>` constraints remain in the files. libxml2 is
XSD 1.0 only, so they are stripped **in memory** at validation time — see
`CrossrefDeposit::Validator`.

## Re-vendoring a newer schema version

1. Clone the schema repo and copy the `crossrefX.Y.Z.xsd` closure (follow its
   `include`/`import` chain) plus `standard-modules/` into a new
   `crossrefX.Y.Z/` directory.
2. Repoint any absolute `schemaLocation`s to the vendored copies and normalize
   any `<?xml version="1.1"?>` declarations to `1.0`.
3. Update `SCHEMA_VERSION` in `lib/crossref_deposit.rb`.
