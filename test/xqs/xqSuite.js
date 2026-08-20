"use strict";

/**
 * Map an XQSuite JSON report into node:test cases.
 * Inspired by exist-markdown's mocha bridge, updated for Node 24 builtins
 * (node:test, fetch, assert) — no mocha/chai.
 *
 * Expects the app package deployed (npm run deploy:dev) so test/xqs ships in the xar.
 * Override with XQS_URL; auth via EXISTDB_USER / EXISTDB_PASS (or XQS_CREDENTIALS).
 */

const { test } = require("node:test");
const assert = require("node:assert/strict");

const defaultUrl = "http://127.0.0.1:8080/exist/rest/db/apps/BetMasWeb/test/xqs/test-runner.xq";
const url = process.env.XQS_URL || defaultUrl;
const credentials =
	process.env.XQS_CREDENTIALS || `${process.env.EXISTDB_USER || "admin"}:${process.env.EXISTDB_PASS || ""}`;

function authHeaders() {
	if (!credentials || credentials === ":") return {};
	return {
		Authorization: `Basic ${Buffer.from(credentials).toString("base64")}`,
	};
}

async function fetchReport(target) {
	const res = await fetch(target, { headers: authHeaders() });
	const body = await res.text();
	assert.ok(res.ok, `XQSuite runner HTTP ${res.status}: ${body.slice(0, 500)}`);
	try {
		return JSON.parse(body);
	} catch {
		assert.fail(`XQSuite runner returned non-JSON: ${body.slice(0, 500)}`);
	}
}

function casesFromSuite(suite) {
	if (!suite || suite.testcase === undefined) return [];
	return Array.isArray(suite.testcase) ? suite.testcase : [suite.testcase];
}

function assertCase(xqstCase) {
	if (Object.hasOwn(xqstCase, "failure")) {
		const detail = xqstCase.failure.message || JSON.stringify(xqstCase.failure);
		assert.fail(`Function ${xqstCase.class} ${detail}`);
	}
	if (Object.hasOwn(xqstCase, "error")) {
		const detail = xqstCase.error.message || JSON.stringify(xqstCase.error);
		assert.fail(`Function ${xqstCase.class} ${detail}`);
	}
}

test("XQSuite", async (t) => {
	const report = await fetchReport(url);
	assert.ok(report.testsuite, `XQSuite runner returned no testsuite: ${JSON.stringify(report).slice(0, 500)}`);
	const suites = Array.isArray(report.testsuite) ? report.testsuite : [report.testsuite];

	for (const suite of suites) {
		const cases = casesFromSuite(suite);
		await t.test(suite.package || "xqsuite", async (st) => {
			if (cases.length === 0) {
				st.skip("no test cases defined");
				return;
			}
			for (const xqstCase of cases) {
				await st.test(xqstCase.name, () => assertCase(xqstCase));
			}
		});
	}
});
