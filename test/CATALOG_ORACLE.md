# Catalog parity oracle

`scripts/run-catalog-oracle.sh` runs `test/xqs/catalog-parity-oracle.xq` against
the configured eXist-db. The **exist-db CI** workflow (`.github/workflows/exist.yml`)
runs the full oracle on every PR to `main`/`master` after XQSuite and before
Cypress (`npm run gate:catalog-oracle`, REST on `:8080`, no `CATALOG_ORACLE_LIMIT`).
Compose in this repo only publishes **`:8080`** (Jetty via the CI stack). CI
uploads `test/catalog-oracle-result.json` whenever that file exists (`if: always()`).

Phase 2 compares `legacy` vs `catalog` (or any pair via bindings) across record
IDs, text-part `title/@corresp` IDs, retired IDs,
institution IDs (`catalog:institutions`, one-sided = mismatch), and distinct
`bm:` pointers in expanded. Both backend resolvers run
independently even when the backend names match.

## Comparison mode

JSON field `comparisonMode` is `resolved-values+bibl-presence`:

| Kind           | Compared value                                                                                                                                                                                                                                                                                                                            |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `title`        | Normalized label string (`catalog:label`)                                                                                                                                                                                                                                                                                                 |
| `institutions` | Institution label via maps built once per backend                                                                                                                                                                                                                                                                                         |
| `bibliography` | Presence only: `"hit"` if `catalog:bibl` returns an entry with **non-empty** `b:citation`, else `""`. Full-entry `serialize()` equality is not used — EthioStudies vs lists markup/citation text may differ (Phase 4 D1). Shared rule: `oraclelib:bibl-presence` in `test/xqs/catalog-oracle-lib.xqm` (XQSuite: `ts-catalog-oracle.xqm`). |

The runner **always prints a summary** (and, when needed, a table of unreviewed
rows plus suggested Accept XML). Empty CI logs used to happen because the old
script `exit`ed on the gate check before printing.

| Condition                                     | Default CI behaviour                                                                                   |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `unreviewedCount` > 0                         | **Warning** (`::warning::` annotations + log). Job stays green. Set `CATALOG_ORACLE_STRICT=1` to fail. |
| `invalidReviewedEntries` ≠ 0                  | **Hard fail**                                                                                          |
| `triageValidationPassed` is false             | **Hard fail**                                                                                          |
| `resolutionCallsA` or `resolutionCallsB` is 0 | **Hard fail** (vacuous compare)                                                                        |

Hermetic jq checks for that gate live in `test/gate-catalog-oracle.bats`.

## Reviewed Accepts

Reviewed differences belong in `test/catalog-reviewed-mismatches.xml` with a
`better`, `worse`, or `neutral` triage. Missing or invalid triage counts toward
`invalidReviewedEntries` and fails the gate.

Optional `@backendA` / `@backendB` **pin** the resolved values seen at Accept
time (for bibliography: `""` / `"hit"` presence tokens). When pins are present,
`oraclelib:review-covers` requires an exact match — an inverted or drifted diff
for the same `kind`+`key` becomes unreviewed again. Omit pins only when values
are unknown; prefer pinning for new Accepts.

Phase 5 carries nine `kind="institutions"` `neutral` rows (HP2 engineering
Accept on the live image, 2026-10-14; supersedes the Phase 3 seven), plus
title/bibl Accepts from the 2026-10-15 full-oracle pass and CI 2026-10-16
IHABook D2 rows; remove them if selectors or data are later aligned. Institution
labels are compared via maps built once per backend (not per id). Bindings:
`CATALOG_BACKEND_A` / `CATALOG_BACKEND_B`. Optional `CATALOG_ORACLE_LIMIT` for
sampled runs.

## Transport

| Context             | Transport     | Host                                                                                                      |
| ------------------- | ------------- | --------------------------------------------------------------------------------------------------------- |
| **exist-db CI**     | `rest` (curl) | `http://127.0.0.1:8080/exist` (only port published by `docker-compose.yml`)                               |
| **Local default**   | `xst`         | `http://127.0.0.1:8082/exist` (direct Jetty when the full BetMas stack maps 8082)                         |
| **Local long REST** | `rest`        | Prefer `:8082` when available — nginx on `:8080` has historically timed out long XML-RPC/REST oracle runs |

```sh
# CI-shaped (REST on :8080) — curl timeout must stay under the workflow step budget
EXISTDB_SERVER=http://127.0.0.1:8080/exist \
EXISTDB_USER=admin EXISTDB_PASS= \
CATALOG_ORACLE_TRANSPORT=rest \
CATALOG_ORACLE_TIMEOUT=3300 \
CATALOG_BACKEND_A=legacy CATALOG_BACKEND_B=catalog \
npm run gate:catalog-oracle

# Local long REST when :8082 is published
EXISTDB_SERVER=http://127.0.0.1:8082/exist \
EXISTDB_USER=admin EXISTDB_PASS= \
CATALOG_ORACLE_TRANSPORT=rest \
CATALOG_ORACLE_TIMEOUT=14400 \
CATALOG_BACKEND_A=legacy CATALOG_BACKEND_B=catalog \
scripts/run-catalog-oracle.sh
```
