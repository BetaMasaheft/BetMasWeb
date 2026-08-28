// modules/app.xqm - app:persFiltersSection's reveal condition (whether
// #persFilters on as.html renders open on reload). Real request-based
// coverage, not XQSuite: this function now reads request:get-parameter
// directly rather than relying on templates:apply's positional
// auto-injection, same reasoning (and same test-split) as
// as-manuscriptsFiltersSection.cy.js's own app:manuscriptsFiltersSection.

const HIDDEN = /id="persFilters" style="display: none"/;
const VISIBLE = /id="persFilters">/;

it("GET /as.html (no facet params) - #persFilters stays hidden", () => {
	cy.request({ url: "/as.html", method: "GET", failOnStatusCode: false, timeout: 90000 }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body).to.match(HIDDEN);
		expect(res.body).to.not.match(VISIBLE);
	});
});

it("GET /as.html?gender=1 - #persFilters is visible", () => {
	cy.request({ url: "/as.html?gender=1", method: "GET", failOnStatusCode: false, timeout: 90000 }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body).to.match(VISIBLE);
	});
});

it("GET /as.html?persType=scribe - #persFilters is visible", () => {
	cy.request({ url: "/as.html?persType=scribe", method: "GET", failOnStatusCode: false, timeout: 90000 }).then(
		(res) => {
			expect(res.status, `responded with ${res.status}`).to.eq(200);
			expect(res.body).to.match(VISIBLE);
		},
	);
});

it("GET /as.html?role=translator - #persFilters is visible", () => {
	cy.request({ url: "/as.html?role=translator", method: "GET", failOnStatusCode: false, timeout: 90000 }).then(
		(res) => {
			expect(res.status, `responded with ${res.status}`).to.eq(200);
			expect(res.body).to.match(VISIBLE);
		},
	);
});
