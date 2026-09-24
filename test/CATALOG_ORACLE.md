# Catalog parity oracle

`scripts/run-catalog-oracle.sh` runs `test/xqs/catalog-parity-oracle.xq` against
the configured eXist-db. Phase 2 compares `legacy` vs `catalog` (or any pair
via bindings) across record IDs, text-part `title/@corresp` IDs, retired IDs,
and distinct `bm:` pointers in expanded. Both backend resolvers run
independently even when the backend names match.

The runner fails when any of:

- `unreviewedCount` is nonzero
- `triageValidationPassed` is false
- `resolutionCallsA` or `resolutionCallsB` is 0 (vacuous compare)

Reviewed differences belong in `test/catalog-reviewed-mismatches.xml` with a
`better`, `worse`, or `neutral` triage. Missing or invalid triage is
unreviewed and therefore fails the gate. Bindings:
`CATALOG_BACKEND_A` / `CATALOG_BACKEND_B`. Optional `CATALOG_ORACLE_LIMIT` for
sampled runs. Transport: `CATALOG_ORACLE_TRANSPORT=rest` (curl; preferred in
CI) or `xst` (default locally).

```sh
EXISTDB_SERVER=http://127.0.0.1:8080 \
EXISTDB_USER=admin EXISTDB_PASS= \
CATALOG_ORACLE_TRANSPORT=rest \
CATALOG_BACKEND_A=legacy CATALOG_BACKEND_B=catalog \
scripts/run-catalog-oracle.sh
```
