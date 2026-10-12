# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bundle exec rake            # default: spec + rubocop (run before declaring work done)
bundle exec rspec           # tests only
bundle exec rspec spec/crossref_deposit/builder_spec.rb          # single file
bundle exec rspec spec/crossref_deposit/builder_spec.rb:42       # single example by line
bundle exec rubocop         # lint only (rubocop-rails-omakase, TargetRubyVersion 3.2)
```

Tests run offline: `webmock/rspec` is loaded globally, so any real HTTP in a spec fails. Specs include the `SampleDeposit` helper (`spec/support/sample_deposit.rb`) for building schema-valid `Book`/`Deposit` fixtures — use `sample_book`/`sample_deposit` with keyword overrides rather than reconstructing value objects inline.

## Architecture

A domain-agnostic library (not a Rails app) that turns plain Ruby value objects into CrossRef deposit XML, validates it offline, and submits it. The pipeline is a one-way flow across two layers:

**Models** (`lib/crossref_deposit/models/`) — immutable value objects. `Book`, `Contributor`, `PublicationDate`, `Isbn`, `Publisher`, `SubmissionReceipt`, and `SubmissionLog::Record` are `Data.define`; `Deposit` and `SubmissionLog` are plain classes. Each leaf model validates *its own direct fields* on construction and raises `InvalidAttributes`. A composite (`Deposit`, `Book`) therefore trusts that its already-constructed children are valid and only checks its own fields — do not re-validate nested objects.

**Services** (`lib/crossref_deposit/services/`):
- `Builder` renders a `Deposit` to XML. **Element order is load-bearing** — the CrossRef `book_metadata` content model is a strict sequence (contributors → titles → edition_number → publication_date → isbn/noisbn → publisher → doi_data). Changing emission order produces schema-invalid XML even when all data is present. Namespaces/schema version come from `SCHEMA_VERSION` in `lib/crossref_deposit.rb`.
- `Validator` compiles the bundled XSD once (memoized, mutex-guarded) and validates XML strings. It strips XSD 1.1 `<xsd:assert>` nodes in memory because libxml2/Nokogiri is XSD 1.0 only (see validator comment + README "Schema & validation"). Share one instance via `CrossrefDeposit.default_validator`.
- `Client` submits over CrossRef's HTTPS deposit servlet via Faraday multipart and fetches results. Injectable `connection:` kwarg is how specs stub HTTP.

**Two distinct validation layers** — keep them separate when reasoning about failures:
1. Attribute validation (construction time, `InvalidAttributes`) — cheap, structural.
2. Schema validation (`Deposit#validate`/`#validate!`/`#valid?` → `ValidationError`) — authoritative check of generated XML against the XSD. The `validator:` kwarg is pluggable (any `#validate(xml) => Array<String>`).

**Asynchronous submission model**: `Client#submit` only confirms queueing (`SubmissionReceipt#queued?`); per-DOI outcome comes later from `Client#fetch_result` → `SubmissionLog`. Submissions are tracked by a unique `file_name`, *not* `doi_batch_id`, because a file that fails to parse never gets a batch id but is always resolvable by name.

## Schema

The full CrossRef 5.5.0 XSD closure is vendored under `vendor/schema/crossref5.5.0/` so validation is fully offline. `vendor/**` is excluded from rubocop. See `vendor/schema/README.md` for provenance and the exact edits to upstream files. When bumping the schema version, update `SCHEMA_VERSION` in `lib/crossref_deposit.rb` (drives schema path, Builder namespace, and `schemaLocation`).

## Scope

v1 registers books (monographs) only. Planned: book chapters, journal articles, resource-only deposits, and an optional mountable Rails engine for push-based result retrieval (would reuse `SubmissionLog`).
