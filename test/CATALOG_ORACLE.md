# Catalog parity oracle

`scripts/run-catalog-oracle.sh` runs `test/xqs/catalog-parity-oracle.xq` against
the configured eXist-db. Phase 1 compares `legacy` with itself across all
record IDs, text-part `title/@corresp` IDs, retired IDs, and distinct `bm:`
pointers in expanded. The run fails unless both mismatch counts are zero.

Reviewed differences belong in `test/catalog-reviewed-mismatches.xml` with a
`better`, `worse`, or `neutral` triage. A future catalog backend adds its
resolver branch to the query and changes the two external backend bindings;
the existing unreviewed-count assertion then becomes the BetMasWeb PR gate.
The runner exposes those bindings as `CATALOG_BACKEND_A` and
`CATALOG_BACKEND_B`.

CI should build and install the BetMasWeb XAR, load the same expanded image as
the XQSuite job, then run:

```sh
EXISTDB_SERVER=http://127.0.0.1:8080 \
EXISTDB_USER=admin EXISTDB_PASS= \
scripts/run-catalog-oracle.sh
```
