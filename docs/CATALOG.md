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

The deployment initializer copies configured environment variables into
`services.xml`, following the same mechanism as other service configuration.
No backend is flipped by this phase.

The CI no-writes gate rejects `update insert|value|delete|replace|rename` and
`xmldb:store` outside an explicit allow-list (install, editors, expansion/
admin entry points, tests). One **tracked serving-reachable exception** remains:
`modules/titlesData.xqm`, which DTS still calls and which can upsert list
files. The gate prints that path as a tracked exception rather than failing;
Phase 4 moves DTS onto the catalog contract and removes the exception.

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
