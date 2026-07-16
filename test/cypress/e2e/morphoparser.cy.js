// generated from db/apps/BetMasWeb/parser/modules/morphoparser.xqm

it("GET /morpho", () => {
	cy.request({ url: "/morpho", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /morpho responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /morpho responded with ${res.status}`).to.not.equal(405);
	});
});
