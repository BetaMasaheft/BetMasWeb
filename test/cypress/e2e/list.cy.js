// generated from db/apps/BetMasWeb/restviews/list.xqm

it("GET /{collection}/{id}/list (as /manuscripts/BAVet1/list)", () => {
	cy.request({ url: "/manuscripts/BAVet1/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/{repoID}/list (as /manuscripts/TEST0001/list)", () => {
	cy.request({ url: "/manuscripts/TEST0001/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/TEST0001/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/TEST0001/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/browse", () => {
	cy.request({ url: "/manuscripts/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /catalogues/{catalogueID}/list (as /catalogues/TEST0001/list)", () => {
	cy.request({ url: "/catalogues/TEST0001/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /catalogues/TEST0001/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /catalogues/TEST0001/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/listChart (as /manuscripts/BAVet1/listChart)", () => {
	cy.request({ url: "/manuscripts/BAVet1/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/browse (as /manuscripts/BAVet1/browse)", () => {
	cy.request({ url: "/manuscripts/BAVet1/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/browse responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/list (as /BAVet1/list)", () => {
	cy.request({ url: "/BAVet1/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/listChart (as /BAVet1/listChart)", () => {
	cy.request({ url: "/BAVet1/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/browse (as /BAVet1/browse)", () => {
	cy.request({ url: "/BAVet1/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/browse responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /art-themes/list", () => {
	cy.request({ url: "/art-themes/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /art-themes/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /art-themes/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/listChart", () => {
	cy.request({ url: "/manuscripts/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/{repoID}/listChart (as /manuscripts/TEST0001/listChart)", () => {
	cy.request({ url: "/manuscripts/TEST0001/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/TEST0001/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/TEST0001/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/place/listChart", () => {
	cy.request({ url: "/manuscripts/place/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/place/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/place/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /catalogues/list", () => {
	cy.request({ url: "/catalogues/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /catalogues/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /catalogues/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /catalogues/{catalogueID}/listChart (as /catalogues/TEST0001/listChart)", () => {
	cy.request({ url: "/catalogues/TEST0001/listChart", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /catalogues/TEST0001/listChart responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /catalogues/TEST0001/listChart responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{unitType}/browse (as /manuscripts/browse)", () => {
	cy.request({ url: "/manuscripts/browse", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/browse responded with ${res.status}`).to.not.equal(405);
	});
});
