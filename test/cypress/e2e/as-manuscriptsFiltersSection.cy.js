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

const HIDDEN = /id="manuscriptsFilters" style="display: none"/;
const VISIBLE = /id="manuscriptsFilters">/;

// Even the zero-filter case runs a real search against the full corpus, so
// this has real latency on its own (~20s warm-local; CI's shared runner is
// slower still, especially on a just-started, cache-cold container) -
// timeouts throughout this file are sized for that, not for a hang.
it("GET /as.html?work-types=mss (no facet params) - #manuscriptsFilters stays hidden", () => {
	cy.request({
		url: "/as.html?work-types=mss",
		method: "GET",
		failOnStatusCode: false,
		timeout: 90000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body).to.match(HIDDEN);
		expect(res.body).to.not.match(VISIBLE);
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
		expect(res.body).to.match(HIDDEN);
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
		expect(res.body).to.match(VISIBLE);
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
		expect(res.body).to.match(VISIBLE);
	});
});
