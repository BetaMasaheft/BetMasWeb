// generated from db/apps/BetMasWeb/restviews/ids.xqm

// Full-corpus scan, genuinely slow not flaky - bumped, not skipped.
it("GET /listIds", () => {
	cy.request({ url: "/listIds", method: "GET", failOnStatusCode: false, timeout: 60000 }).then((res) => {
		expect(res.status, `GET /listIds responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /listIds responded with ${res.status}`).to.not.equal(405);
		expect(res.status).to.eq(200);
		expect(res.body).to.include("BAVet1");
		expect(res.body).to.include("INS0003BAV");
	});
});
