// generated from db/apps/BetMasWeb/restviews/genderInfo.xqm

it("GET /gender", () => {
	cy.request({ url: "/gender", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /gender/data", () => {
	cy.request({ url: "/gender/data", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender/data responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender/data responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /gender/rels", () => {
	cy.request({ url: "/gender/rels", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender/rels responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender/rels responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /gender/table", () => {
	cy.request({ url: "/gender/table", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender/table responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender/table responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /gender/table/female", () => {
	cy.request({ url: "/gender/table/female", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender/table/female responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender/table/female responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /gender/table/male", () => {
	cy.request({ url: "/gender/table/male", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender/table/male responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender/table/male responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /gender/page", () => {
	cy.request({ url: "/gender/page", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender/page responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender/page responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /gender/graph", () => {
	cy.request({ url: "/gender/graph", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /gender/graph responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /gender/graph responded with ${res.status}`).to.not.equal(405);
	});
});
