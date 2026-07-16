// generated from db/apps/BetMasWeb/restviews/idlookup.xqm

it("GET /api/idlookup", () => {
	cy.request({ url: "/api/idlookup", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /api/idlookup responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /api/idlookup responded with ${res.status}`).to.not.equal(405);
	});
});
