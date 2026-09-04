// generated from db/apps/BetMasWeb/restviews/permanentItems.xqm

// real commit touching VaticanBAV/et/BAVet1.xml in betamasaheft/Manuscripts, so the
// success path (not just the not-500/not-405 smoke check) is actually exercised
const sha = "cbe98c2c1adbc0366cb81bc08b1bbde9cf2ac615";

// This route's render (PermRestItem:ITEM, same untemplated item/manuscript
// page as the {collection}/{id}/main variant below) is slow enough to
// occasionally brush against a single cy.request()'s timeout. The
// `responseTimeout` key used here previously isn't a real cy.request()
// option (Cypress's own option is `timeout` - see cypress.d.ts's
// RequestOptions/Timeoutable) - so it silently had no effect and this call
// was still bound by Cypress's default 30s the whole time.
// @see https://github.com/BetaMasaheft/BetMasWeb/issues/144
it("GET /permanent/{sha}/{id}/main (as /permanent/{sha}/BAVet1/main)", () => {
	cy.request({
		url: `/permanent/${sha}/BAVet1/main`,
		method: "GET",
		failOnStatusCode: false,
		timeout: 45000,
	}).then((res) => {
		expect(res.status, `GET /permanent/${sha}/BAVet1/main responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /permanent/${sha}/BAVet1/main responded with ${res.status}`).to.not.equal(405);
	});
});

// This route resolves the id against the corpora collection, not
// manuscripts - BAVet1 (reused above) doesn't belong there and 500s.
// Real commit touching corpus8.xml in betamasaheft/corpora instead.
const corpusSha = "12c4b9c285696c700149261bf5dc0295acd7772e";

it("GET /permanent/{sha}/{id}/corpus (as /permanent/{sha}/corpus8/corpus)", () => {
	cy.request({ url: `/permanent/${corpusSha}/corpus8/corpus`, method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /permanent/${corpusSha}/corpus8/corpus responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /permanent/${corpusSha}/corpus8/corpus responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /permanent/{sha}/{collection}/{id}/main (as /permanent/{sha}/manuscripts/BAVet1/main)", () => {
	cy.request({
		url: `/permanent/${sha}/manuscripts/BAVet1/main`,
		method: "GET",
		failOnStatusCode: false,
		timeout: 45000,
	}).then((res) => {
		expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /permanent/${sha}/manuscripts/BAVet1/main responded with ${res.status}`).to.not.equal(405);
	});
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
