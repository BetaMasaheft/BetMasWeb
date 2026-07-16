// generated from db/apps/BetMasWeb/restviews/litcompare.xqm

it("GET /litcomp", () => {
	cy.request({ url: "/litcomp", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /litcomp responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /litcomp responded with ${res.status}`).to.not.equal(405);
	});
});
