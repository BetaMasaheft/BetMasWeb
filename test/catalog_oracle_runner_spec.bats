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

run_oracle() {
	# Force xst transport so ambient CATALOG_ORACLE_TRANSPORT=rest cannot
	# bypass the stub and hang on curl to a live eXist.
	run env PATH="$STUB_BIN:$PATH" \
		CATALOG_ORACLE_TRANSPORT=xst \
		CATALOG_ORACLE_OUT="$BATS_TEST_TMPDIR/result.json" \
		"$RUNNER"
}

@test "reviewed mismatches do not fail the runner" {
	export ORACLE_FIXTURE='{"titleCases":2,"bibliographyCases":1,"mismatchCount":1,"unreviewedCount":0,"triageValidationPassed":true,"resolutionCallsA":2,"resolutionCallsB":2,"mismatches":[{"triage":"better","reviewed":true}]}'

	run_oracle

	[ "$status" -eq 0 ]
	[[ "$output" == *"mismatches=1"* ]]
	[[ "$output" == *"unreviewed=0"* ]]
}

@test "unreviewed mismatches fail the runner" {
	export ORACLE_FIXTURE='{"titleCases":2,"bibliographyCases":1,"mismatchCount":1,"unreviewedCount":1,"triageValidationPassed":true,"resolutionCallsA":2,"resolutionCallsB":2,"mismatches":[{"triage":"","reviewed":false}]}'

	run_oracle

	[ "$status" -ne 0 ]
}

@test "failed triage validation fails the runner" {
	export ORACLE_FIXTURE='{"titleCases":2,"bibliographyCases":1,"mismatchCount":0,"unreviewedCount":0,"triageValidationPassed":false,"resolutionCallsA":2,"resolutionCallsB":2,"mismatches":[]}'

	run_oracle

	[ "$status" -ne 0 ]
}

@test "zero resolution calls fail the runner" {
	export ORACLE_FIXTURE='{"titleCases":2,"bibliographyCases":1,"mismatchCount":0,"unreviewedCount":0,"triageValidationPassed":true,"resolutionCallsA":0,"resolutionCallsB":0,"mismatches":[]}'

	run_oracle

	[ "$status" -ne 0 ]
}
