// generated from db/apps/BetMasWeb/restviews/items.xqm

it("GET /{collection}/{id}/main (as /manuscripts/BAVet1/main)", () => {
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
