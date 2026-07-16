// generated from db/apps/BetMasWeb/restviews/workmap.xqm

it("GET /workmap", () => {
	cy.request({ url: "/workmap", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /workmap responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /workmap responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /workmap/KML/{workid} (as /workmap/KML/LIT1367Exodus)", () => {
	cy.request({ url: "/workmap/KML/LIT1367Exodus", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /workmap/KML/LIT1367Exodus responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /workmap/KML/LIT1367Exodus responded with ${res.status}`).to.not.equal(405);
	});
});
