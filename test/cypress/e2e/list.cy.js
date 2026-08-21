// generated from db/apps/BetMasWeb/restviews/list.xqm

it("GET /{collection}/{id}/list (as /manuscripts/BAVet1/list)", () => {
	cy.request({ url: "/manuscripts/BAVet1/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/{repoID}/list (as /manuscripts/TEST0001/list)", () => {
	cy.request({ url: "/manuscripts/TEST0001/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/TEST0001/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/TEST0001/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/browse", () => {
	cy.request({ url: "/manuscripts/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(405);
	});
});

// Skipped: same retry-storm timeout as items.cy.js's "main" test -
// iterates manuscripts including BAVet1. See that test's comment.
it.skip("GET /catalogues/{catalogueID}/list (as /catalogues/TEST0001/list)", () => {
	cy.request({ url: "/catalogues/TEST0001/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /catalogues/TEST0001/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /catalogues/TEST0001/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/listChart (as /manuscripts/BAVet1/listChart)", () => {
	cy.request({ url: "/manuscripts/BAVet1/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/browse (as /manuscripts/BAVet1/browse)", () => {
	cy.request({ url: "/manuscripts/BAVet1/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/browse responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/list (as /BAVet1/list)", () => {
	cy.request({ url: "/BAVet1/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/listChart (as /BAVet1/listChart)", () => {
	cy.request({ url: "/BAVet1/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/browse (as /BAVet1/browse)", () => {
	cy.request({ url: "/BAVet1/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/browse responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /art-themes/list", () => {
	cy.request({ url: "/art-themes/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /art-themes/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /art-themes/list responded with ${res.status}`).to.not.equal(405);
	});
});

// Skipped: same retry-storm timeout as items.cy.js's "main" test -
// iterates manuscripts including BAVet1. See that test's comment.
it.skip("GET /manuscripts/listChart", () => {
	cy.request({ url: "/manuscripts/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/{repoID}/listChart (as /manuscripts/TEST0001/listChart)", () => {
	cy.request({ url: "/manuscripts/TEST0001/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/TEST0001/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/TEST0001/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/place/listChart", () => {
	cy.request({ url: "/manuscripts/place/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/place/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/place/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

// Regression #21: institution records store the full wikidata URI, not the
// "wd:" shorthand this endpoint accepts as a place param - the eq
// comparison never matched, $repositoriesIDS came up empty, and eXist's
// range-index optimizer threw XPTY0004 instead of just returning 0 hits.
it("GET /manuscripts/place/listChart?place=wd:{Qid} does not error and finds real manuscripts (regression #21)", () => {
	cy.request({ url: "/manuscripts/place/listChart?place=wd:Q1055", method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /manuscripts/place/listChart?place=wd:Q1055 responded with ${res.status}`).to.eq(200);
			expect(res.body, "response should not contain an XPTY0004 error").to.not.include("XPTY0004");
			expect(res.body, "hit-count should not be 0").to.not.match(/w3-tag w3-gray">0</);
		},
	);
});

it("GET /catalogues/list", () => {
	cy.request({ url: "/catalogues/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /catalogues/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /catalogues/list responded with ${res.status}`).to.not.equal(405);
	});
});

// Skipped: same retry-storm timeout as items.cy.js's "main" test -
// iterates manuscripts including BAVet1. See that test's comment.
it.skip("GET /catalogues/{catalogueID}/listChart (as /catalogues/TEST0001/listChart)", () => {
	cy.request({ url: "/catalogues/TEST0001/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /catalogues/TEST0001/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /catalogues/TEST0001/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{unitType}/browse (as /manuscripts/browse)", () => {
	cy.request({ url: "/manuscripts/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(405);
	});
});
