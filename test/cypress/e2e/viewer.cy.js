// generated from db/apps/BetMasWeb/restviews/viewer.xqm

it("GET /{collection}/{id}/viewer (as /manuscripts/BAVet1/viewer)", () => {
	cy.request({ url: "/manuscripts/BAVet1/viewer", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/viewer responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/viewer responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/viewer", () => {
	cy.request({ url: "/manuscripts/viewer", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/viewer responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/viewer responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/viewer (as /BAVet1/viewer)", () => {
	cy.request({ url: "/BAVet1/viewer", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/viewer responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/viewer responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/{repoid}/list/viewer (as /manuscripts/TEST0001/list/viewer)", () => {
	cy.request({ url: "/manuscripts/TEST0001/list/viewer", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/TEST0001/list/viewer responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/TEST0001/list/viewer responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /chojnacki/viewer", () => {
	cy.request({ url: "/chojnacki/viewer", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /chojnacki/viewer responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /chojnacki/viewer responded with ${res.status}`).to.not.equal(405);
	});
});
