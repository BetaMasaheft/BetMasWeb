// modules/app.xqm - app:persFiltersSection's reveal condition (whether
// #persFilters on as.html renders open on reload). Real request-based
// coverage, not XQSuite: this function now reads request:get-parameter
// directly rather than relying on templates:apply's positional
// auto-injection, same reasoning (and same test-split) as
// as-manuscriptsFiltersSection.cy.js's own app:manuscriptsFiltersSection.
//
// Assert on a plain boolean, never `expect(res.body).to.match(...)`
// directly: res.body is the full rendered page (multi-MB), and Chai's
// default failure message for a failed .match() includes the entire
// actual string - slow enough streaming through GitHub Actions' log UI
// to look exactly like a many-minutes hang, found live in
// as-manuscriptsFiltersSection.cy.js's own equivalent pattern.

const HIDDEN = /id="persFilters" style="display: none"/;
const VISIBLE = /id="persFilters">/;

function expectHidden(body) {
	expect(HIDDEN.test(body), "expected #persFilters to render hidden").to.be.true;
	expect(VISIBLE.test(body), "expected #persFilters not to render visible").to.be.false;
}

function expectVisible(body) {
	expect(VISIBLE.test(body), "expected #persFilters to render visible").to.be.true;
}

it("GET /as.html (no facet params) - #persFilters stays hidden", () => {
	cy.request({ url: "/as.html", method: "GET", failOnStatusCode: false, timeout: 90000 }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectHidden(res.body);
	});
});

it("GET /as.html?gender=1 - #persFilters is visible", () => {
	cy.request({ url: "/as.html?gender=1", method: "GET", failOnStatusCode: false, timeout: 90000 }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectVisible(res.body);
	});
});

it("GET /as.html?persType=scribe - #persFilters is visible", () => {
	cy.request({ url: "/as.html?persType=scribe", method: "GET", failOnStatusCode: false, timeout: 90000 }).then(
		(res) => {
			expect(res.status, `responded with ${res.status}`).to.eq(200);
			expectVisible(res.body);
		},
	);
});

it("GET /as.html?role=translator - #persFilters is visible", () => {
	cy.request({ url: "/as.html?role=translator", method: "GET", failOnStatusCode: false, timeout: 90000 }).then(
		(res) => {
			expect(res.status, `responded with ${res.status}`).to.eq(200);
			expectVisible(res.body);
		},
	);
});
