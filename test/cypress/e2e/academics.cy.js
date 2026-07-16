// generated from db/apps/BetMasWeb/modules/academics.xqm

it("GET /BetMas/api/academics", () => {
	cy.request({ url: "/BetMas/api/academics", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BetMas/api/academics responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BetMas/api/academics responded with ${res.status}`).to.not.equal(405);
		// fixture PRS10036Wansleb.xml is tagged as an academic (type="pers" scholar entry)
		expect(res.status).to.eq(200);
		expect(JSON.stringify(res.body)).to.include("PRS10036Wansleb");
	});
});
