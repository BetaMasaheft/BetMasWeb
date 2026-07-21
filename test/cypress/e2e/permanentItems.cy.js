// generated from db/apps/BetMasWeb/restviews/permanentItems.xqm

// real commit touching VaticanBAV/et/BAVet1.xml in betamasaheft/Manuscripts, so the
// success path (not just the not-500/not-405 smoke check) is actually exercised
const sha = "cbe98c2c1adbc0366cb81bc08b1bbde9cf2ac615";

it("GET /permanent/{sha}/{id}/main (as /permanent/{sha}/BAVet1/main)", () => {
	cy.request({ url: `/permanent/${sha}/BAVet1/main`, method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /permanent/${sha}/BAVet1/main responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /permanent/${sha}/BAVet1/main responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /permanent/{sha}/{id}/corpus (as /permanent/{sha}/BAVet1/corpus)", () => {
	cy.request({ url: `/permanent/${sha}/BAVet1/corpus`, method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /permanent/${sha}/BAVet1/corpus responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /permanent/${sha}/BAVet1/corpus responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /permanent/{sha}/{collection}/{id}/main (as /permanent/{sha}/manuscripts/BAVet1/main)", () => {
	cy.request({ url: `/permanent/${sha}/manuscripts/BAVet1/main`, method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(
				500,
			);
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(
				405,
			);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/text (as /permanent/{sha}/manuscripts/BAVet1/text)", () => {
	cy.request({ url: `/permanent/${sha}/manuscripts/BAVet1/text`, method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/text responded with ${res.status}`).to.not.equal(
				500,
			);
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/text responded with ${res.status}`).to.not.equal(
				405,
			);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/analytic (as /permanent/{sha}/manuscripts/BAVet1/analytic)", () => {
	cy.request({ url: `/permanent/${sha}/manuscripts/BAVet1/analytic`, method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/analytic responded with ${res.status}`).to.not.equal(
				500,
			);
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/analytic responded with ${res.status}`).to.not.equal(
				405,
			);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/graph (as /permanent/{sha}/manuscripts/BAVet1/graph)", () => {
	cy.request({ url: `/permanent/${sha}/manuscripts/BAVet1/graph`, method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/graph responded with ${res.status}`).to.not.equal(
				500,
			);
			expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/graph responded with ${res.status}`).to.not.equal(
				405,
			);
		},
	);
});

it("GET /permanent/{sha}/{collection}/{id}/geoBrowser (as /permanent/{sha}/manuscripts/BAVet1/geoBrowser)", () => {
	cy.request({ url: `/permanent/${sha}/manuscripts/BAVet1/geoBrowser`, method: "GET", failOnStatusCode: false }).then(
		(res) => {
			expect(
				res.status,
				`GET /permanent/${sha}/manuscripts/BAVet1/geoBrowser responded with ${res.status}`,
			).to.not.equal(500);
			expect(
				res.status,
				`GET /permanent/${sha}/manuscripts/BAVet1/geoBrowser responded with ${res.status}`,
			).to.not.equal(405);
		},
	);
});
