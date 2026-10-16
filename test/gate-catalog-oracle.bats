#!/usr/bin/env bats

# Hermetic checks for the jq fail-closed gate in scripts/run-catalog-oracle.sh
# (no eXist). Sources catalog_oracle_gate_ok via a tiny eval of the function body.

setup() {
	load_gate
}

load_gate() {
	# shellcheck disable=SC1091
	eval "$(
		sed -n '/^catalog_oracle_gate_ok()/,/^}/p' \
			"$BATS_TEST_DIRNAME/../scripts/run-catalog-oracle.sh"
	)"
}

@test "gate ok when counts are clean" {
	printf '%s\n' '{
		"unreviewedCount": 0,
		"invalidReviewedEntries": 0,
		"triageValidationPassed": true,
		"resolutionCallsA": 10,
		"resolutionCallsB": 10
	}' >"$BATS_TEST_TMPDIR/ok.json"
	catalog_oracle_gate_ok "$BATS_TEST_TMPDIR/ok.json"
}

@test "gate fails on unreviewedCount" {
	printf '%s\n' '{
		"unreviewedCount": 1,
		"invalidReviewedEntries": 0,
		"triageValidationPassed": true,
		"resolutionCallsA": 10,
		"resolutionCallsB": 10
	}' >"$BATS_TEST_TMPDIR/bad.json"
	run catalog_oracle_gate_ok "$BATS_TEST_TMPDIR/bad.json"
	[ "$status" -ne 0 ]
}

@test "gate fails on invalidReviewedEntries" {
	printf '%s\n' '{
		"unreviewedCount": 0,
		"invalidReviewedEntries": 2,
		"triageValidationPassed": true,
		"resolutionCallsA": 10,
		"resolutionCallsB": 10
	}' >"$BATS_TEST_TMPDIR/bad.json"
	run catalog_oracle_gate_ok "$BATS_TEST_TMPDIR/bad.json"
	[ "$status" -ne 0 ]
}

@test "gate fails on vacuous resolutionCalls" {
	printf '%s\n' '{
		"unreviewedCount": 0,
		"invalidReviewedEntries": 0,
		"triageValidationPassed": true,
		"resolutionCallsA": 0,
		"resolutionCallsB": 10
	}' >"$BATS_TEST_TMPDIR/bad.json"
	run catalog_oracle_gate_ok "$BATS_TEST_TMPDIR/bad.json"
	[ "$status" -ne 0 ]
}
