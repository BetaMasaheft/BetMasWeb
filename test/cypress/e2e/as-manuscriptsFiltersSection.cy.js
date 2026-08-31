// modules/app.xqm - app:manuscriptsFiltersSection's reveal condition
// (whether #manuscriptsFilters on as.html renders open on reload). Real
// request-based coverage, not XQSuite: this function reads
// request:get-parameter directly, so only a real request can drive it.
//
// Rendered shapes: hidden is `id="manuscriptsFilters" style="display:
// none"`, active drops @style entirely, leaving `id="manuscriptsFilters">`.
//
// No custom timeouts below - these three cases run in well under 2s
// locally (previously many-minutes-or-hung, fixed by app:include-facet-form
// and app:target-mss no longer rendering full pickers/lists unconditionally),
// comfortably inside Cypress's default responseTimeout.
//
// Assert on a plain boolean, never `expect(res.body).to.match(...)`
// directly: on failure Chai dumps the entire actual string, and res.body
// here is a multi-MB page - slow enough through GitHub Actions' log UI
// to look like a hang (found live, via the app:gender-active regression
// this file's own re-enabling caught).

const HIDDEN = /id="manuscriptsFilters" style="display: none"/;
const VISIBLE = /id="manuscriptsFilters">/;

function expectHidden(body) {
	expect(HIDDEN.test(body), "expected #manuscriptsFilters to render hidden").to.be.true;
	expect(VISIBLE.test(body), "expected #manuscriptsFilters not to render visible").to.be.false;
}

function expectVisible(body) {
	expect(VISIBLE.test(body), "expected #manuscriptsFilters to render visible").to.be.true;
}

it("GET /as.html?work-types=mss (no facet params) - #manuscriptsFilters stays hidden", () => {
	cy.request({ url: "/as.html?work-types=mss", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectHidden(res.body);
	});
});

// language belongs to "General filters", not #manuscriptsFilters.
it("GET /as.html?language=gez (an unrelated facet) - #manuscriptsFilters stays hidden", () => {
	cy.request({ url: "/as.html?work-types=mss&language=gez", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectHidden(res.body);
	});
});

// gender alone is enough to prove the reveal condition's `or` chain fires.
it("GET /as.html?gender=1 - #manuscriptsFilters is visible", () => {
	cy.request({ url: "/as.html?work-types=mss&gender=1", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectVisible(res.body);
	});
});

// Skipped, not deleted: dimensions' guard defeats eXist's range-index
// optimizer, minutes slow against the real corpus - separate, tracked
// issue (BetMasWeb#104, expanded#21). Re-enable once those land.
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
