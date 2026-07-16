// generated from db/apps/BetMasWeb/restviews/LitFlowRest.xqm

it("GET /LitFlow", () => {
	cy.request({ url: "/LitFlow", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /LitFlow responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /LitFlow responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/LitFlow (as /manuscripts/BAVet1/LitFlow)", () => {
	cy.request({ url: "/manuscripts/BAVet1/LitFlow", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/LitFlow responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/LitFlow responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/LitFlow (as /BAVet1/LitFlow)", () => {
	cy.request({ url: "/BAVet1/LitFlow", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/LitFlow responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/LitFlow responded with ${res.status}`).to.not.equal(405);
	});
});
