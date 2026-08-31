// modules/app.xqm - app:manuscriptsFiltersSection's reveal condition
// (whether #manuscriptsFilters on as.html renders open on reload). Real
// request-based coverage, not XQSuite: this function reads
// request:get-parameter directly for each of its ~30 facets rather than
// relying on templates:apply's positional auto-injection - the
// html-templating package's templates:call dispatch caps auto-resolved
// function parameters at 20, which this function exceeds - so a
// test-supplied $model has no effect on its behavior. Only a real HTTP
// request can drive it, which is what these tests do.
//
// Rendered shapes (confirmed live): hidden is
// `id="manuscriptsFilters" style="display: none"`, active drops the whole
// @style attribute, leaving `id="manuscriptsFilters">` with nothing before
// the closing bracket - the regexes below match those exact shapes.
//
// Timeouts here are generous (real corpus-scale render, CI's shared
// runner is slower than local) but bounded, not the many-minutes-or-hung
// values this file carried before app:target-mss was fixed to stop
// rendering its full ~20,000-manuscript unscoped list on every as.html
// load regardless of filters.
//
// Assert on a plain boolean, never `expect(res.body).to.match(...)`
// directly: res.body is the full rendered page (multi-MB), and Chai's
// default failure message for a failed .match() includes the entire
// actual string - a genuinely CI-breaking mistake found live, not a
// theoretical one: a real assertion failure here (the app:gender-active
// regression fixed alongside this) dumped ~2.6MB into one log line,
// which is fast to print locally but took long enough streaming through
// GitHub Actions' log UI to look exactly like a many-minutes hang.

const HIDDEN = /id="manuscriptsFilters" style="display: none"/;
const VISIBLE = /id="manuscriptsFilters">/;

function expectHidden(body) {
	expect(HIDDEN.test(body), "expected #manuscriptsFilters to render hidden").to.be.true;
	expect(VISIBLE.test(body), "expected #manuscriptsFilters not to render visible").to.be.false;
}

function expectVisible(body) {
	expect(VISIBLE.test(body), "expected #manuscriptsFilters to render visible").to.be.true;
}

// Even the zero-filter case runs a real search against the full corpus, so
// this has real latency on its own - timeouts throughout this file are
// sized for that, not for a hang.
it("GET /as.html?work-types=mss (no facet params) - #manuscriptsFilters stays hidden", () => {
	cy.request({
		url: "/as.html?work-types=mss",
		method: "GET",
		failOnStatusCode: false,
		timeout: 90000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectHidden(res.body);
	});
});

// language belongs to "General filters", not #manuscriptsFilters - a
// non-manuscripts facet being active must not reveal this section.
it("GET /as.html?language=gez (an unrelated facet) - #manuscriptsFilters stays hidden", () => {
	cy.request({
		url: "/as.html?work-types=mss&language=gez",
		method: "GET",
		failOnStatusCode: false,
		timeout: 90000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectHidden(res.body);
	});
});

// gender alone is enough to prove the reveal condition's `or` chain fires:
// app:gender-active is a plain presence check, so this exercises the
// "visible" branch at roughly the same cost as the zero-filter baseline
// above, without pulling in app:folia-active - folia shares the same
// range-index-defeating guard as dimensions (see below) and would make
// this request minutes slow for no extra coverage.
it("GET /as.html?gender=1 - #manuscriptsFilters is visible", () => {
	cy.request({
		url: "/as.html?work-types=mss&gender=1",
		method: "GET",
		failOnStatusCode: false,
		timeout: 90000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectVisible(res.body);
	});
});

// Skipped, not deleted: dimensions' nine fields all share
// app:range-filter's matches(normalize-space(.), ...) guard, which defeats
// eXist's range-index optimizer, so a real filtered dimensions search
// against the full corpus takes minutes, not seconds - too slow for CI's
// shared runner even with a generous timeout. A fix (retyped range-index
// fields, normalized source values) is in progress in
// BetaMasaheft/BetMasWeb#104 and BetaMasaheft/expanded#21; re-enable this
// once those land and the corpus is reindexed.
it.skip("GET /as.html?height=150,250 (dimensions) - #manuscriptsFilters is visible", () => {
	cy.request({
		url: "/as.html?work-types=mss&height=150,250",
		method: "GET",
		failOnStatusCode: false,
		timeout: 330000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectVisible(res.body);
	});
});
