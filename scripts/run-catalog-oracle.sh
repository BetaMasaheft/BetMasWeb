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
# Fail on unreviewed when set to 1 (default: warn only).
: "${CATALOG_ORACLE_STRICT:=0}"
export EXISTDB_SERVER EXISTDB_USER EXISTDB_PASS

# Hard fail: invalid Accepts, broken triage helper, or vacuous run.
# Soft (warn): unreviewedCount > 0 unless CATALOG_ORACLE_STRICT=1.
catalog_oracle_gate_ok() {
	jq -e '
		.invalidReviewedEntries == 0
		and .triageValidationPassed == true
		and .resolutionCallsA > 0
		and .resolutionCallsB > 0
	' "$1" >/dev/null
}

catalog_oracle_print_report() {
	local out="$1"
	local unreviewed
	unreviewed="$(jq -r '.unreviewedCount // 0' "$out")"

	printf 'catalog oracle: compared=%s (titles=%s institutions=%s bibl=%s) mismatches=%s unreviewed=%s invalidReviewed=%s mode=%s\n' \
		"$(jq -r '.comparedCases // .resolutionCallsA' "$out")" \
		"$(jq -r '.titleCases' "$out")" \
		"$(jq -r '.institutionCases // 0' "$out")" \
		"$(jq -r '.bibliographyCases' "$out")" \
		"$(jq -r '.mismatchCount' "$out")" \
		"$unreviewed" \
		"$(jq -r '.invalidReviewedEntries // 0' "$out")" \
		"$(jq -r '.comparisonMode' "$out")"

	if [[ "$unreviewed" -eq 0 ]]; then
		return 0
	fi

	printf '\n'
	printf 'UNREVIEWED mismatches (%s) — actionable:\n' "$unreviewed"
	printf '  1. Triage each row (Accept / fix selectors / fix data).\n'
	printf '  2. For Accept: add a pinned row to test/catalog-reviewed-mismatches.xml\n'
	printf '     (see suggested XML below). Re-run the gate after merge.\n'
	printf '\n'
	printf 'KIND\tKEY\tA (legacy)\tB (catalog)\n'
	# Use a rare separator so empty A/B cells survive (tsv + read collapses them).
	jq -r '
		.mismatches[]
		| select(.reviewed == false)
		| [
				.kind,
				.key,
				(.backendA // ""),
				(.backendB // "")
			]
		| join("\u001f")
	' "$out" | while IFS=$'\x1f' read -r kind key a b; do
		printf '%s\t%s\t%s\t%s\n' "$kind" "$key" "$a" "$b"
	done

	printf '\nSuggested Accept rows (edit triage/note before committing):\n'
	local today
	today="$(date -u +%Y-%m-%d)"
	jq -r --arg today "$today" '
		.mismatches[]
		| select(.reviewed == false)
		| "<mismatch kind=\"\(.kind)\" key=\"\(.key)\" triage=\"neutral\" backendA=\"\(.backendA // "" | gsub("&"; "&amp;") | gsub("\""; "&quot;"))\" backendB=\"\(.backendB // "" | gsub("&"; "&amp;") | gsub("\""; "&quot;"))\" note=\"TODO triage \($today)\" />"
	' "$out"

	# GitHub Actions annotations (no-op locally).
	if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
		local line
		while IFS= read -r line; do
			# Escape % and newlines for workflow commands.
			line="${line//'%'/'%25'}"
			line="${line//$'\r'/'%0D'}"
			line="${line//$'\n'/'%0A'}"
			printf '::warning title=Catalog oracle unreviewed::%s\n' "$line"
		done < <(jq -r '
			.mismatches[]
			| select(.reviewed == false)
			| "\(.kind) \(.key): A=\(.backendA // "") B=\(.backendB // "") — add Accept or fix"
		' "$out")
		printf '::warning title=Catalog oracle::%s unreviewed mismatch(es); build continues (set CATALOG_ORACLE_STRICT=1 to fail). Artifact: catalog-oracle-result\n' "$unreviewed"
	fi
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

catalog_oracle_print_report "$OUT"

if ! catalog_oracle_gate_ok "$OUT"; then
	printf '\ncatalog oracle: HARD FAIL (invalid Accepts, triage helper, or vacuous run)\n' >&2
	exit 1
fi

if [[ "$(jq -r '.unreviewedCount // 0' "$OUT")" -gt 0 ]]; then
	if [[ "$CATALOG_ORACLE_STRICT" == "1" ]]; then
		printf '\ncatalog oracle: STRICT fail on unreviewedCount (CATALOG_ORACLE_STRICT=1)\n' >&2
		exit 1
	fi
	printf '\ncatalog oracle: WARN — unreviewed mismatches (not failing the job)\n'
fi
