# Catalog facade

`modules/catalog.xqm` is the shared Web/API contract for labels, institution
options, text parts, bibliography entries, and retired identifiers.

Each consumer reads its own `CATALOG_BACKEND_<CONSUMER>` value from
`services.xml`; names are uppercased and non-alphanumeric characters become
underscores. Supported values are `legacy` and `catalog`. Missing or invalid
values always select `legacy`.

Current consumers and variables:

- `exptit`: `CATALOG_BACKEND_EXPTIT`
- Web lists: `CATALOG_BACKEND_WEB_LIST`
- item bibliography rendering: `CATALOG_BACKEND_VIEW_ITEM`
- API titles: `CATALOG_BACKEND_API_TITLES`
- API repository list: `CATALOG_BACKEND_API_REST`
- bibliography resolution: `CATALOG_BACKEND_BIBL` (Phase 4; set to `catalog` in deployment)
- institutions / labels: `CATALOG_BACKEND_INSTITUTIONS`, `CATALOG_BACKEND_LABEL`,
  `CATALOG_BACKEND_LABELS`, `CATALOG_BACKEND_EXPTIT`, … (Phase 5; set to
  `catalog` in BetMas compose)

`viewItem` / `list` / `zc:bibl-page-entry` resolve bibliography through the
`bibl` consumer (`CATALOG_BACKEND_BIBL`), not `view-item` / `web-list`.

Missing or unset `CATALOG_BACKEND_*` still selects `legacy` (same for every
consumer: `catalog:backend` → `config:service-url(..., "legacy")`). Phase 4/5
expect BetMas compose / `finish.xq` to set the flipped consumers to `catalog`
explicitly. BetMasWeb's own `docker-compose.yml` has no betmas service env
block.

When `CATALOG_BACKEND_EXPTIT=catalog`:

- `expand:file` / `expand:backfillTitleCache` do **not** write
  `lists/titleCache.xml` (`expand:writes-title-cache()`).
- `catalog:resolve-label` (catalog backend) ignores `titleCache.xml` and
  prefers `/db/apps/catalogs/labels.xml`, then expanded `title[@type=full]`.
- `lists:title-lookup-map()` returns empty so form/facet batch paths fall
  through to `exptit` / catalog instead of serving a stale cache map.

Legacy backends still read/write `titleCache` for oracle Arm A. `titles:updateTitleCache`
itself remains callable (tests / allow-listed); expand is the production writer
that is gated.

The **exist-db CI** job also runs the catalog parity oracle (`gate:catalog-oracle`)
on PRs (REST `:8080`, Accept pins in `test/catalog-reviewed-mismatches.xml`) —
see `test/CATALOG_ORACLE.md`.

The CI no-writes gate rejects `update insert|value|delete|replace|rename` and
`xmldb:store` outside an explicit allow-list (install, editors, expansion/
admin entry points, tests). One **tracked serving-reachable exception** remains:
`modules/titlesData.xqm`, which DTS still calls and which can upsert list
files. The gate prints that path as a tracked exception rather than failing.
Phase 4 did not touch `titlesData`; a later phase moves DTS onto the catalog
contract and removes the exception. Until then the titlesData write exception
remains.

## Backends

- `legacy` resolves through `modules/catalog-legacy.xqm` (frozen pre-Phase-2
  lists / deleted / expanded chain).
- `catalog` uses Phase 3 artifacts under `/db/apps/catalogs/` when present,
  otherwise queries expanded/BetMasData via shared selectors in
  `modules/catalog-selectors.xqm`.

External place labels (`wd:` / `gn:` / `pleiades:`) go through
`modules/catalog-places.xqm` (process-local `cache:put`, no DB write) for both
backends so Web and API agree.

## Inscription labels

`selectors:manuscript-label` matches `t:objectDesc[@form = "Inscription"]`.
The pre-2026-09 `titlesData` copy used an unprefixed `objectDesc` predicate
that never matched namespaced TEI, so inscriptions fell through to the
repository branch. The prefixed form is intentional; see
`test/xqs/ts-catalog-selectors.xqm`.

## Bibliography lookup performance

`catalog:bibl` must use **single-value** `@id` equality (then an optional
underscore-id fallback). A general comparison such as
`[@id = ($id, replace($id, ":", "_"))]` forces a full scan of
`bibliography.xml` (~14 s per lookup on the release-expanded image vs ~10 ms
indexed). That alone timed out `/works/…/text` in CI. Same rule for any other
large list/catalog document under `/db/apps/lists` or `/db/apps/catalogs`.

## Tests

- **bats** — smoke only (container / package / logs).
- **XQSuite** — contract and selectors (`test/xqs/ts-catalog-*.xqm`).
- **Cypress** — HTTP integration (e.g. work-text HTML regression in
  `test/cypress/e2e/items.cy.js`).
- **Oracle** — `scripts/run-catalog-oracle.sh` with
  `CATALOG_ORACLE_TRANSPORT=rest` in CI; requires `resolutionCallsA/B > 0` and
  zero unreviewed mismatches. See `test/CATALOG_ORACLE.md`.

## Formatting

Run Prettier before every commit on this repo (`npm run format:write`, or at
least `npm run format:check`). CI `format-check` fails the PR otherwise;
XQuery/JS/Markdown under the facade workstream have already tripped it more
than once.
