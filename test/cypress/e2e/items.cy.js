// generated from db/apps/BetMasWeb/restviews/items.xqm

// Skipped: hangs past 30s. BAVet1's real IIIF manifest points at
// digi.vatlib.it, which the server retries with no backoff until 429.
// Reported in #19 (closed by #22, but still reproduces post-#22).
// Structural fix: the fixture-serving iipsrv planned for Phase 1.
it.skip("GET /{collection}/{id}/main (as /manuscripts/BAVet1/main)", () => {
	cy.request({ url: "/manuscripts/BAVet1/main", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/text (as /manuscripts/BAVet1/text)", () => {
	cy.request({ url: "/manuscripts/BAVet1/text", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/text responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/text responded with ${res.status}`).to.not.equal(405);
	});
});

// Regression: Roaster document unwrap / work-text 500 (was bats work_text_spec).
it("GET /works/LIT1709Kebran/text returns HTML (not XPTY0004 JSON error)", () => {
	cy.request({
		url: "/works/LIT1709Kebran/text",
		method: "GET",
		failOnStatusCode: false,
		timeout: 90000
	}).then((res) => {
		expect(res.status, `GET /works/LIT1709Kebran/text responded with ${res.status}`).to.equal(200);
		expect(res.body, "body should be HTML").to.match(/<!DOCTYPE html|<html/i);
		expect(res.body, "body should not be an XPTY0004 JSON error").to.not.include("XPTY0004");
	});
});

it("GET /{collection}/{id}/analytic (as /manuscripts/BAVet1/analytic)", () => {
	cy.request({ url: "/manuscripts/BAVet1/analytic", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/analytic responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/analytic responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/graph (as /manuscripts/BAVet1/graph)", () => {
	cy.request({ url: "/manuscripts/BAVet1/graph", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/graph responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/graph responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/geoBrowser (as /manuscripts/BAVet1/geoBrowser)", () => {
	cy.request({ url: "/manuscripts/BAVet1/geoBrowser", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/geoBrowser responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/geoBrowser responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /corpus/{path} (as /corpus/test)", () => {
	cy.request({ url: "/corpus/test", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /corpus/test responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /corpus/test responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/main (as /BAVet1/main)", () => {
	cy.request({ url: "/BAVet1/main", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/main responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/main responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/text (as /BAVet1/text)", () => {
	cy.request({ url: "/BAVet1/text", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/text responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/text responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/analytic (as /BAVet1/analytic)", () => {
	cy.request({ url: "/BAVet1/analytic", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/analytic responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/analytic responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/graph (as /BAVet1/graph)", () => {
	cy.request({ url: "/BAVet1/graph", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/graph responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/graph responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/geoBrowser (as /BAVet1/geoBrowser)", () => {
	cy.request({ url: "/BAVet1/geoBrowser", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/geoBrowser responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/geoBrowser responded with ${res.status}`).to.not.equal(405);
	});
});
