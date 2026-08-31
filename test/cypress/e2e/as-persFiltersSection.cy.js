// modules/app.xqm - app:persFiltersSection's reveal condition (whether
// #persFilters on as.html renders open on reload). Real request-based
// coverage, not XQSuite: this function reads request:get-parameter
// directly, so only a real request can drive it.
//
// Assert on a plain boolean, never `expect(res.body).to.match(...)`
// directly: on failure Chai dumps the entire actual string, and res.body
// here is a multi-MB page - slow enough through GitHub Actions' log UI
// to look like a hang.
//
// No custom timeout on the first three: facet-picker rendering only,
// well under 1s locally, comfortably inside Cypress's default
// responseTimeout. role=translator is different - app:persRoleResults
// does genuine corpus-scale search work (~18s locally), so it keeps an
// explicit, larger timeout.

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
	cy.request({ url: "/as.html", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectHidden(res.body);
	});
});

it("GET /as.html?gender=1 - #persFilters is visible", () => {
	cy.request({ url: "/as.html?gender=1", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectVisible(res.body);
	});
});

it("GET /as.html?persType=scribe - #persFilters is visible", () => {
	cy.request({ url: "/as.html?persType=scribe", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expectVisible(res.body);
	});
});

it("GET /as.html?role=translator - #persFilters is visible", () => {
	cy.request({ url: "/as.html?role=translator", method: "GET", failOnStatusCode: false, timeout: 60000 }).then(
		(res) => {
			expect(res.status, `responded with ${res.status}`).to.eq(200);
			expectVisible(res.body);
		},
	);
});
