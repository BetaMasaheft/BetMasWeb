#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUERY="$ROOT/test/xqs/catalog-parity-oracle.xq"
OUT="${CATALOG_ORACLE_OUT:-$ROOT/test/catalog-oracle-result.json}"

# Defaults: legacy vs catalog parity (override via env). Local runs keep xst transport.
: "${EXISTDB_SERVER:=http://127.0.0.1:8082/exist}"
: "${EXISTDB_USER:=admin}"
: "${EXISTDB_PASS:=}"
: "${CATALOG_BACKEND_A:=legacy}"
: "${CATALOG_BACKEND_B:=catalog}"
: "${CATALOG_ORACLE_TRANSPORT:=xst}"
: "${CATALOG_ORACLE_LIMIT:=}"
: "${CATALOG_ORACLE_TIMEOUT:=3600}"
export EXISTDB_SERVER EXISTDB_USER EXISTDB_PASS

# Fail closed on unreviewed diffs, invalid Accept rows, broken triage helper, or vacuous run.
catalog_oracle_gate_ok() {
	jq -e '
		.unreviewedCount == 0
		and .invalidReviewedEntries == 0
		and .triageValidationPassed == true
		and .resolutionCallsA > 0
		and .resolutionCallsB > 0
	' "$1" >/dev/null
}

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
catalog_oracle_gate_ok "$OUT"
printf 'catalog oracle: compared=%s (titles universe=%s institutions universe=%s bibl universe=%s) mismatches=%s unreviewed=%s invalidReviewed=%s mode=%s\n' \
	"$(jq -r '.comparedCases // .resolutionCallsA' "$OUT")" \
	"$(jq -r '.titleCases' "$OUT")" \
	"$(jq -r '.institutionCases // 0' "$OUT")" \
	"$(jq -r '.bibliographyCases' "$OUT")" \
	"$(jq -r '.mismatchCount' "$OUT")" \
	"$(jq -r '.unreviewedCount' "$OUT")" \
	"$(jq -r '.invalidReviewedEntries // 0' "$OUT")" \
	"$(jq -r '.comparisonMode' "$OUT")"
