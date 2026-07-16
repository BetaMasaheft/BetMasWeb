// generated from db/apps/BetMasWeb/restviews/compare.xqm

it("GET /compare", () => {
	cy.request({ url: "/compare", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /compare responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /compare responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /compareSelected", () => {
	cy.request({ url: "/compareSelected", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /compareSelected responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /compareSelected responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/compare (as /manuscripts/BAVet1/compare)", () => {
	cy.request({ url: "/manuscripts/BAVet1/compare", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/compare responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/compare responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/compareSelected (as /manuscripts/BAVet1/compareSelected)", () => {
	cy.request({ url: "/manuscripts/BAVet1/compareSelected", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/compareSelected responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/compareSelected responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/compare (as /BAVet1/compare)", () => {
	cy.request({ url: "/BAVet1/compare", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/compare responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/compare responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/compareSelected (as /BAVet1/compareSelected)", () => {
	cy.request({ url: "/BAVet1/compareSelected", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/compareSelected responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/compareSelected responded with ${res.status}`).to.not.equal(405);
	});
});
