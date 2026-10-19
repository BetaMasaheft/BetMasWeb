#!/usr/bin/env bats

# Hermetic checks for the jq gate + report helpers in scripts/run-catalog-oracle.sh
# (no eXist). Sources functions via sed of the script body.

setup() {
	load_gate
}

load_gate() {
	# shellcheck disable=SC1091
	eval "$(
		sed -n \
			-e '/^catalog_oracle_gate_ok()/,/^}/p' \
			-e '/^catalog_oracle_print_report()/,/^}/p' \
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

@test "gate ok on unreviewedCount (warn path; not a hard fail)" {
	printf '%s\n' '{
		"unreviewedCount": 1,
		"invalidReviewedEntries": 0,
		"triageValidationPassed": true,
		"resolutionCallsA": 10,
		"resolutionCallsB": 10
	}' >"$BATS_TEST_TMPDIR/warn.json"
	catalog_oracle_gate_ok "$BATS_TEST_TMPDIR/warn.json"
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

@test "report lists unreviewed keys and suggested Accept XML" {
	printf '%s\n' '{
		"unreviewedCount": 1,
		"invalidReviewedEntries": 0,
		"triageValidationPassed": true,
		"resolutionCallsA": 10,
		"resolutionCallsB": 10,
		"comparedCases": 10,
		"titleCases": 5,
		"institutionCases": 3,
		"bibliographyCases": 2,
		"mismatchCount": 1,
		"comparisonMode": "resolved-values+bibl-presence",
		"mismatches": [
			{
				"kind": "institutions",
				"key": "INS1034BahrDarGiyorgis",
				"reviewed": false,
				"backendA": "",
				"backendB": "Bāhǝr Dār"
			}
		]
	}' >"$BATS_TEST_TMPDIR/report.json"
	run catalog_oracle_print_report "$BATS_TEST_TMPDIR/report.json"
	[ "$status" -eq 0 ]
	[[ "$output" == *"unreviewed=1"* ]]
	[[ "$output" == *"INS1034BahrDarGiyorgis"* ]]
	[[ "$output" == *"UNREVIEWED mismatches"* ]]
	[[ "$output" == *'<mismatch kind="institutions" key="INS1034BahrDarGiyorgis"'* ]]
	[[ "$output" == *'backendB="Bāhǝr Dār"'* ]]
}
