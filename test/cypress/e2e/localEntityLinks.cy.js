// Item pages must link entities on this deployment, not production.
// Expanded data stores refs as canonical https://betamasaheft.eu/{id} URIs;
// render code that emits them verbatim (href or the place popup's
// data-href) sends dev/staging users to prod. Links to prod-only resources
// without an entity id (e.g. /Guidelines/) are fine and not matched here.
// https://github.com/BetaMasaheft/BetMasWeb/issues/164

const canonicalEntityLink = /(?:data-)?href="https:\/\/betamasaheft\.eu\/[A-Za-z]+\d[^"]*"/g;

const pages = [
	"/manuscripts/ESdd033/main",
	"/manuscripts/BNFet32/main",
	"/works/LIT1709Kebran/main",
	"/works/LIT1367Exodus/main",
	"/persons/PRS10036Wansleb/main",
];

pages.forEach((path) => {
	it(`${path} has no canonical entity links`, () => {
		cy.request({ url: path, timeout: 90000 }).then((res) => {
			expect(res.status).to.eq(200);
			const found = [...new Set(res.body.match(canonicalEntityLink) || [])];
			expect(found, `prod entity links on ${path}`).to.deep.equal([]);
		});
	});
});
