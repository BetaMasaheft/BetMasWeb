// generated from db/apps/BetMasWeb/modules/dts.xqm

it("GET /BetMas/api/dts/{api}/template (as /BetMas/api/dts/collections/template)", () => {
	cy.request({ url: "/BetMas/api/dts/collections/template", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BetMas/api/dts/collections/template responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BetMas/api/dts/collections/template responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /BetMas/api/dts/indexes", () => {
	cy.request({ url: "/BetMas/api/dts/indexes", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BetMas/api/dts/indexes responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BetMas/api/dts/indexes responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /BetMas/api/dts/annotations", () => {
	cy.request({ url: "/BetMas/api/dts/annotations", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BetMas/api/dts/annotations responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BetMas/api/dts/annotations responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /BetMas/api/dts/annotations/{coll} (as /BetMas/api/dts/annotations/manuscripts)", () => {
	cy.request({ url: "/BetMas/api/dts/annotations/manuscripts", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BetMas/api/dts/annotations/manuscripts responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BetMas/api/dts/annotations/manuscripts responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /BetMas/api/dts/annotations/{coll}/{indexName} (as /BetMas/api/dts/annotations/manuscripts/test-index)", () => {
	cy.request({
		url: "/BetMas/api/dts/annotations/manuscripts/test-index",
		method: "GET",
		failOnStatusCode: false,
	}).then((res) => {
		expect(
			res.status,
			`GET /BetMas/api/dts/annotations/manuscripts/test-index responded with ${res.status}`,
		).to.not.equal(500);
		expect(
			res.status,
			`GET /BetMas/api/dts/annotations/manuscripts/test-index responded with ${res.status}`,
		).to.not.equal(405);
	});
});

it("GET /BetMas/api/dts/annotations/{coll}/items/{BMid} (as /BetMas/api/dts/annotations/manuscripts/items/BAVet1)", () => {
	cy.request({
		url: "/BetMas/api/dts/annotations/manuscripts/items/BAVet1",
		method: "GET",
		failOnStatusCode: false,
	}).then((res) => {
		expect(
			res.status,
			`GET /BetMas/api/dts/annotations/manuscripts/items/BAVet1 responded with ${res.status}`,
		).to.not.equal(500);
		expect(
			res.status,
			`GET /BetMas/api/dts/annotations/manuscripts/items/BAVet1 responded with ${res.status}`,
		).to.not.equal(405);
	});
});

it("GET /BetMas/api/dts/annotations/{coll}/items/{BMid}/{indexName} (as /BetMas/api/dts/annotations/manuscripts/items/BAVet1/test-index)", () => {
	cy.request({
		url: "/BetMas/api/dts/annotations/manuscripts/items/BAVet1/test-index",
		method: "GET",
		failOnStatusCode: false,
	}).then((res) => {
		expect(
			res.status,
			`GET /BetMas/api/dts/annotations/manuscripts/items/BAVet1/test-index responded with ${res.status}`,
		).to.not.equal(500);
		expect(
			res.status,
			`GET /BetMas/api/dts/annotations/manuscripts/items/BAVet1/test-index responded with ${res.status}`,
		).to.not.equal(405);
	});
});
