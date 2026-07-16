// generated from db/apps/BetMasWeb/restviews/permanentItems.xqm

it("GET /permanent/{sha}/{id}/main (as /permanent/0000000/BAVet1/main)", () => {
	cy.request({ url: "/permanent/0000000/BAVet1/main", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /permanent/0000000/BAVet1/main responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /permanent/0000000/BAVet1/main responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /permanent/{sha}/{id}/corpus (as /permanent/0000000/BAVet1/corpus)", () => {
	cy.request({ url: "/permanent/0000000/BAVet1/corpus", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /permanent/0000000/BAVet1/corpus responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /permanent/0000000/BAVet1/corpus responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /permanent/{sha}/{collection}/{id}/main (as /permanent/0000000/manuscripts/BAVet1/main)", () => {
	cy.request({ url: "/permanent/0000000/manuscripts/BAVet1/main", method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /permanent/0000000/manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(
				500,
			);
			expect(res.status, `GET /permanent/0000000/manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(
				405,
			);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/text (as /permanent/0000000/manuscripts/BAVet1/text)", () => {
	cy.request({ url: "/permanent/0000000/manuscripts/BAVet1/text", method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /permanent/0000000/manuscripts/BAVet1/text responded with ${res.status}`).to.not.equal(
				500,
			);
			expect(res.status, `GET /permanent/0000000/manuscripts/BAVet1/text responded with ${res.status}`).to.not.equal(
				405,
			);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/analytic (as /permanent/0000000/manuscripts/BAVet1/analytic)", () => {
	cy.request({ url: "/permanent/0000000/manuscripts/BAVet1/analytic", method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(
				res.status,
				`GET /permanent/0000000/manuscripts/BAVet1/analytic responded with ${res.status}`,
			).to.not.equal(500);
			expect(
				res.status,
				`GET /permanent/0000000/manuscripts/BAVet1/analytic responded with ${res.status}`,
			).to.not.equal(405);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/graph (as /permanent/0000000/manuscripts/BAVet1/graph)", () => {
	cy.request({ url: "/permanent/0000000/manuscripts/BAVet1/graph", method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /permanent/0000000/manuscripts/BAVet1/graph responded with ${res.status}`).to.not.equal(
				500,
			);
			expect(res.status, `GET /permanent/0000000/manuscripts/BAVet1/graph responded with ${res.status}`).to.not.equal(
				405,
			);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/geoBrowser (as /permanent/0000000/manuscripts/BAVet1/geoBrowser)", () => {
	cy.request({ url: "/permanent/0000000/manuscripts/BAVet1/geoBrowser", method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(
				res.status,
				`GET /permanent/0000000/manuscripts/BAVet1/geoBrowser responded with ${res.status}`,
			).to.not.equal(500);
			expect(
				res.status,
				`GET /permanent/0000000/manuscripts/BAVet1/geoBrowser responded with ${res.status}`,
			).to.not.equal(405);
		},
	);
});
