// generated from db/apps/BetMasWeb/restviews/collatex.xqm

it("GET /collate", () => {
	cy.request({ url: "/collate", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /collate responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /collate responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/collate (as /manuscripts/BAVet1/collate)", () => {
	cy.request({ url: "/manuscripts/BAVet1/collate", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/collate responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/collate responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/collate (as /BAVet1/collate)", () => {
	cy.request({ url: "/BAVet1/collate", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/collate responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/collate responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /api/collatex", () => {
	cy.request({ url: "/api/collatex", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /api/collatex responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /api/collatex responded with ${res.status}`).to.not.equal(405);
	});
});

it("POST /api/collatex", () => {
	cy.request({ url: "/api/collatex", method: "POST", failOnStatusCode: false }).then((res) => {
		expect(res.status, `POST /api/collatex responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `POST /api/collatex responded with ${res.status}`).to.not.equal(405);
	});
});
