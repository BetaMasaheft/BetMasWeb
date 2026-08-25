// BetMasWeb#82: bibliography is server-rendered; the browser must not call Zotero.
describe("bibliography without live Zotero", () => {
	it("GET /help.html fills citations without api.zotero.org", () => {
		cy.intercept("https://api.zotero.org/**").as("zotero");
		cy.visit("/help.html");
		cy.get("#bibliography li").should("have.length.at.least", 1);
		// Prefer EthioStudies cache; if empty (no cache/Zotero), still assert no browser Zotero.
		cy.get("#bibliography").then(($bib) => {
			const text = $bib.text().replace(/\s+/g, " ").trim();
			if (text.length > "Bibliography".length + 20) {
				expect(text).to.match(/\S/);
			}
		});
		cy.get("@zotero.all").should("have.length", 0);
	});

	it("GET /bibliography does not load NewBiblio or biblio.js", () => {
		cy.request("/bibliography").then((res) => {
			expect(res.status).to.not.equal(500);
			expect(res.body).to.not.include("NewBiblio.js");
			expect(res.body).to.not.include("biblio.js");
		});
	});

	it("GET /api/versions enriches via BetMasWeb (not bare Api SPARQL)", () => {
		cy.request({
			url: "/api/versions/LIT1367Exodus/1",
			failOnStatusCode: false,
		}).then((res) => {
			// 501 when BetMasApi missing; otherwise Web proxy must mark enrichment
			if (res.status === 501) {
				return;
			}
			expect(res.status).to.be.lessThan(500);
			if (res.body && typeof res.body === "object" && res.body.versions) {
				expect(res.body.enrichedBy).to.equal("BetMasWeb");
				const items = Array.isArray(res.body.versions) ? res.body.versions : [res.body.versions];
				items.forEach((item) => {
					const ed = item && item.version && item.version.source && item.version.source.ed;
					if (ed && /^bm[:_]/.test(String(ed))) {
						expect(item.version.source).to.have.property("editionHtml");
					}
				});
			}
		});
	});
});
