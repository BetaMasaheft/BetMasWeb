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

it("GET /as.html?work-types=mss (no facet params) - #manuscriptsFilters stays hidden", () => {
	cy.request({
		url: "/as.html?work-types=mss",
		method: "GET",
		failOnStatusCode: false,
		timeout: 30000,
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
		timeout: 30000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body).to.match(HIDDEN);
	});
});

// One request covering four independent branches of the reveal condition's
// big `or` chain at once, rather than one full as.html round-trip per
// facet: app:folia-active (slider-shaped), app:gender-active (plain
// presence check), app:list-param-active (the shared helper backing most
// list-style facets - scribe is one of a dozen callers, all the same code
// path), and target-ins (institutions).
//
// numberOfParts was tried here first and dropped: app:query's own
// numberOfParts predicate - "[count(descendant::t:msPart) ge ...]" -
// counts msPart descendants per document with no index involved, and
// alone (no other filter active) took over 200s against the real corpus -
// a genuine, pre-existing performance problem, unrelated to this
// function's own reveal logic. gender is the presence-check-shaped facet
// used instead, confirmed fast (~23s, same as the zero-filter baseline).
it("GET /as.html with folia/gender/scribe/target-ins active - #manuscriptsFilters is visible", () => {
	cy.request({
		url: "/as.html?work-types=mss&folia=5,120&gender=1&scribe=PRS1&target-ins=INS0003BAV",
		method: "GET",
		failOnStatusCode: false,
		timeout: 45000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body).to.match(VISIBLE);
	});
});

// dimensions is its own case, not folded into the combined request above:
// its nine fields all share app:range-filter's matches(normalize-space(.),
// ...) guard, which defeats eXist's range-index optimizer - a real,
// filtered dimensions search on this corpus takes several minutes, not
// seconds. The timeout below is generous on purpose, not a mistake: a run
// taking this long is expected, not a hang.
it("GET /as.html?height=150,250 (dimensions) - #manuscriptsFilters is visible", () => {
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
