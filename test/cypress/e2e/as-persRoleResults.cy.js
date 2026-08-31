// app:persRoleResults's result links. Needs a real request (not XQSuite -
// see app.xqm's $preservedParams comment). translator: low-count role (10
// attestations), keeps the full-collection scan fast (~16s locally) -
// still enough to need an explicit timeout above Cypress's default.
it("GET /as.html?role=translator&language=gez - result links keep the language facet, not just role+person", () => {
	cy.request({
		url: "/as.html?work-types=mss&role=translator&language=gez",
		method: "GET",
		failOnStatusCode: false,
		timeout: 60000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		const links = res.body.match(/href="\?[^"]*role=translator[^"]*person=[^"]*"/g);
		expect(links, "no role-results links found").to.not.be.null;
		for (const link of links) {
			expect(link).to.include("language=gez");
		}
	});
});
