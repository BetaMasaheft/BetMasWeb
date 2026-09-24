#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUERY="$ROOT/test/xqs/catalog-parity-oracle.xq"
OUT="${CATALOG_ORACLE_OUT:-$ROOT/test/catalog-oracle-result.json}"

: "${EXISTDB_SERVER:=http://127.0.0.1:8082/exist}"
: "${EXISTDB_USER:=admin}"
: "${EXISTDB_PASS:=}"
: "${CATALOG_BACKEND_A:=legacy}"
: "${CATALOG_BACKEND_B:=legacy}"
: "${CATALOG_ORACLE_TRANSPORT:=xst}"
export EXISTDB_SERVER EXISTDB_USER EXISTDB_PASS

if [[ "$CATALOG_ORACLE_TRANSPORT" == "rest" ]]; then
	curl --fail --silent --show-error \
		--user "$EXISTDB_USER:$EXISTDB_PASS" \
		--get \
		--data-urlencode "backend-a=$CATALOG_BACKEND_A" \
		--data-urlencode "backend-b=$CATALOG_BACKEND_B" \
		"$EXISTDB_SERVER/rest/db/apps/BetMasWeb/test/xqs/catalog-parity-oracle.xq" |
		jq -r "fromjson" > "$OUT"
else
	xst run --file "$QUERY" --bind \
		"{\"backend-a\":\"$CATALOG_BACKEND_A\",\"backend-b\":\"$CATALOG_BACKEND_B\"}" > "$OUT"
fi
jq -e '.unreviewedCount == 0 and .triageValidationPassed == true' "$OUT" >/dev/null
printf 'catalog oracle: %s title cases, %s bibliography cases, %s mismatches, %s unreviewed\n' \
	"$(jq -r '.titleCases' "$OUT")" \
	"$(jq -r '.bibliographyCases' "$OUT")" \
	"$(jq -r '.mismatchCount' "$OUT")" \
	"$(jq -r '.unreviewedCount' "$OUT")"
