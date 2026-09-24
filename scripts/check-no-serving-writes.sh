#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Explicit non-serving allow-list: installer, editors, expansion/admin jobs,
# and tests which create isolated fixtures.
allowed='^(\./)?(pre-install\.xql|edit/|modules/(expand|batchExpand|titlesData|gitsync|generateFormattedBibliography)\.xqm|test/)'
status=0

while IFS= read -r file; do
	if [[ ! "$file" =~ $allowed ]]; then
		printf 'Disallowed database write in serving module: %s\n' "$file" >&2
		status=1
	fi
done < <(rg -l 'update[[:space:]]+(insert|value|delete)|xmldb:store' --glob '*.xq' --glob '*.xql' --glob '*.xqm' . || true)

exit "$status"
