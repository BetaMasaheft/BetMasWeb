# Phase 2 oracle report

`catalog-oracle-legacy-vs-catalog.json` is a **real** `legacy` vs `catalog`
comparison (`comparisonMode=resolved-values`, both arms resolve).

It was captured with `CATALOG_ORACLE_LIMIT=500` on a fresh compose stack after
the Phase 2 review fixes. Universe sizes remain in the JSON
(`titleCases` / `bibliographyCases`). Full-space runs:

```bash
CATALOG_BACKEND_A=legacy CATALOG_BACKEND_B=catalog \
CATALOG_ORACLE_TRANSPORT=rest CATALOG_ORACLE_TIMEOUT=14400 \
CATALOG_ORACLE_OUT=test/catalog-oracle-legacy-vs-catalog.full.json \
  scripts/run-catalog-oracle.sh
```
