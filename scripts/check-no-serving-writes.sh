#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Explicit non-serving allow-list: installer, editors, expansion/admin jobs,
# and tests which create isolated fixtures.
allowed='^(\./)?(pre-install\.xql$|edit/|test/|modules/(expand|batchExpand|gitsync|generateFormattedBibliography)\.xqm$)'

# Tracked exceptions: modules that still write and are reachable from a
# request handler. Each entry must carry a note in docs/CATALOG.md saying why
# it is still here and which phase removes it. They are reported, not failed.
#
#   modules/titlesData.xqm - dts.xqm calls titles:printSubtitle and
#   titles:printTitleID, which fall through to the persNames/textparts/places
#   list upserts. Phase 4 moves DTS onto the catalog contract.
tracked='^(\./)?modules/titlesData\.xqm$'

if ! command -v rg >/dev/null 2>&1; then
	printf 'ERROR: ripgrep (rg) is required for the no-serving-writes gate\n' >&2
	exit 2
fi

# ripgrep: 0 = matches, 1 = no matches, >=2 = error. Never treat error as clean.
matches="$(mktemp)"
trap 'rm -f "${matches}"' EXIT
set +e
rg -lU 'update[[:space:]]+(insert|value|delete|replace|rename)\b|xmldb:store' \
	--glob '*.xq' --glob '*.xql' --glob '*.xqm' . >"${matches}"
rg_status=$?
set -e
if [ "${rg_status}" -gt 1 ]; then
	printf 'ERROR: ripgrep failed while scanning for serving writes (exit %s)\n' "${rg_status}" >&2
	exit "${rg_status}"
fi

status=0

while IFS= read -r file; do
	[ -n "${file}" ] || continue
	if [[ "$file" =~ $allowed ]]; then
		continue
	fi
	if [[ "$file" =~ $tracked ]]; then
		printf 'Tracked write exception, still serving-reachable: %s\n' "$file" >&2
		continue
	fi
	printf 'Disallowed database write in serving module: %s\n' "$file" >&2
	status=1
done <"${matches}"

exit "$status"
