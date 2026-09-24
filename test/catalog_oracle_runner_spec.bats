#!/usr/bin/env bats

setup() {
	RUNNER="$BATS_TEST_DIRNAME/../scripts/run-catalog-oracle.sh"
	STUB_BIN="$BATS_TEST_TMPDIR/bin"
	mkdir -p "$STUB_BIN"
	cat > "$STUB_BIN/xst" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$ORACLE_FIXTURE"
EOF
	chmod +x "$STUB_BIN/xst"
}

@test "reviewed mismatches do not fail the runner" {
	export ORACLE_FIXTURE='{"titleCases":2,"bibliographyCases":1,"mismatchCount":1,"unreviewedCount":0,"triageValidationPassed":true,"mismatches":[{"triage":"better","reviewed":true}]}'

	run env PATH="$STUB_BIN:$PATH" CATALOG_ORACLE_OUT="$BATS_TEST_TMPDIR/result.json" "$RUNNER"

	[ "$status" -eq 0 ]
	[[ "$output" == *"1 mismatches, 0 unreviewed"* ]]
}

@test "unreviewed mismatches fail the runner" {
	export ORACLE_FIXTURE='{"titleCases":2,"bibliographyCases":1,"mismatchCount":1,"unreviewedCount":1,"triageValidationPassed":true,"mismatches":[{"triage":"","reviewed":false}]}'

	run env PATH="$STUB_BIN:$PATH" CATALOG_ORACLE_OUT="$BATS_TEST_TMPDIR/result.json" "$RUNNER"

	[ "$status" -ne 0 ]
}

@test "failed triage validation fails the runner" {
	export ORACLE_FIXTURE='{"titleCases":2,"bibliographyCases":1,"mismatchCount":0,"unreviewedCount":0,"triageValidationPassed":false,"mismatches":[]}'

	run env PATH="$STUB_BIN:$PATH" CATALOG_ORACLE_OUT="$BATS_TEST_TMPDIR/result.json" "$RUNNER"

	[ "$status" -ne 0 ]
}
