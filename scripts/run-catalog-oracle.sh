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
: "${CATALOG_ORACLE_LIMIT:=}"
: "${CATALOG_ORACLE_TIMEOUT:=3600}"
export EXISTDB_SERVER EXISTDB_USER EXISTDB_PASS

if [[ "$CATALOG_ORACLE_TRANSPORT" == "rest" ]]; then
	args=(
		--fail --silent --show-error
		--user "$EXISTDB_USER:$EXISTDB_PASS"
		--get
		--max-time "$CATALOG_ORACLE_TIMEOUT"
		--data-urlencode "backend-a=$CATALOG_BACKEND_A"
		--data-urlencode "backend-b=$CATALOG_BACKEND_B"
	)
	if [[ -n "$CATALOG_ORACLE_LIMIT" ]]; then
		args+=(--data-urlencode "limit=$CATALOG_ORACLE_LIMIT")
	fi
	curl "${args[@]}" \
		"$EXISTDB_SERVER/rest/db/apps/BetMasWeb/test/xqs/catalog-parity-oracle.xq" |
		jq -r 'if type == "string" then fromjson else . end' > "$OUT"
else
	bind=$(jq -nc \
		--arg a "$CATALOG_BACKEND_A" \
		--arg b "$CATALOG_BACKEND_B" \
		--argjson lim "${CATALOG_ORACLE_LIMIT:-null}" \
		'{ "backend-a": $a, "backend-b": $b } + (if $lim == null then {} else { limit: $lim } end)')
	xst run --file "$QUERY" --bind "$bind" > "$OUT"
fi
jq -e '.unreviewedCount == 0 and .triageValidationPassed == true and .resolutionCallsA > 0 and .resolutionCallsB > 0' "$OUT" >/dev/null
printf 'catalog oracle: compared=%s (titles universe=%s bibl universe=%s) mismatches=%s unreviewed=%s mode=%s\n' \
	"$(jq -r '.comparedCases // .resolutionCallsA' "$OUT")" \
	"$(jq -r '.titleCases' "$OUT")" \
	"$(jq -r '.bibliographyCases' "$OUT")" \
	"$(jq -r '.mismatchCount' "$OUT")" \
	"$(jq -r '.unreviewedCount' "$OUT")" \
	"$(jq -r '.comparisonMode' "$OUT")"
