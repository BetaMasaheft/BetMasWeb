# Catalog parity oracle

`scripts/run-catalog-oracle.sh` runs `test/xqs/catalog-parity-oracle.xq` against
the configured eXist-db. The **exist-db CI** workflow (`.github/workflows/exist.yml`)
runs the full oracle on every PR to `main`/`master` after XQSuite and before
Cypress (`npm run gate:catalog-oracle`, REST on `:8080`, no `CATALOG_ORACLE_LIMIT`).
On failure, CI uploads `test/catalog-oracle-result.json` as an artifact.

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

The runner fails when any of:

- `unreviewedCount` is nonzero
- `triageValidationPassed` is false
- `resolutionCallsA` or `resolutionCallsB` is 0 (vacuous compare)

Reviewed differences belong in `test/catalog-reviewed-mismatches.xml` with a
`better`, `worse`, or `neutral` triage. Missing or invalid triage is
unreviewed and therefore fails the gate. Phase 5 carries nine
`kind="institutions"` `neutral` rows (HP2 engineering Accept on the live
image, 2026-10-14; supersedes the Phase 3 seven), plus title/bibl Accepts
from the 2026-10-15 full-oracle pass after the institutions+titles flips;
remove them if selectors or data are later aligned. Institution labels are
compared via maps built once per backend (not per id). Bindings:
`CATALOG_BACKEND_A` / `CATALOG_BACKEND_B`. Optional `CATALOG_ORACLE_LIMIT` for
sampled runs. Transport: `CATALOG_ORACLE_TRANSPORT=rest` (curl; preferred in
CI and for full runs on `:8082`) or `xst` (default locally). Prefer
`EXISTDB_SERVER=http://127.0.0.1:8082/exist` for long REST runs (nginx `:8080`
XML-RPC timeouts).

```sh
EXISTDB_SERVER=http://127.0.0.1:8082/exist \
EXISTDB_USER=admin EXISTDB_PASS= \
CATALOG_ORACLE_TRANSPORT=rest \
CATALOG_ORACLE_TIMEOUT=14400 \
CATALOG_BACKEND_A=legacy CATALOG_BACKEND_B=catalog \
scripts/run-catalog-oracle.sh
```
