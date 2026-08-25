// BetMasWeb#82: bibliography is server-rendered; the browser must not call Zotero.
describe("bibliography without live Zotero", () => {
	it("GET /help.html fills citations without api.zotero.org", () => {
		cy.intercept("https://api.zotero.org/**").as("zotero");
		cy.visit("/help.html");
		cy.get("#bibliography li").should("have.length.at.least", 1);
		cy.get("#bibliography li").first().invoke("text").should("match", /\S/);
		cy.get("@zotero.all").should("have.length", 0);
	});

	it("GET /bibliography does not load NewBiblio or biblio.js", () => {
		cy.request("/bibliography").then((res) => {
			expect(res.status).to.not.equal(500);
			expect(res.body).to.not.include("NewBiblio.js");
			expect(res.body).to.not.include("biblio.js");
		});
	});
});
