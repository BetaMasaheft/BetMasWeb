// newSearch.html loads w3.js after dateConversions.js. w3.js walks every
// <time data-calendar> and calls convertDate(); missing that script throws
// ReferenceError and Cypress fails the visit (seen on CI for person hits
// with calendar dates). Pin to PRS4374Gabreel — the only person whose
// floruit nested calendar dates render as time[data-calendar] in
// summaryPers — so the hit set stays tiny and ranking-stable (bare
// query=Walda was >300 hits, ft:score page-1 only, and dropped Gabreel
// after betmas-data republish).
it("does not throw convertDate when person results include calendar <time>", () => {
	const appErrors = [];
	cy.visit("/newSearch.html?searchType=text&work-types=pers&query=PRS4374Gabreel", {
		onBeforeLoad(win) {
			win.addEventListener("error", (e) => {
				appErrors.push(String(e.message || e.error));
			});
		},
	});
	cy.get('a[href*="PRS4374Gabreel"]').should("exist");
	cy.get("time[data-calendar]").should("have.length.gt", 0);
	cy.wrap(null).should(() => {
		expect(
			appErrors.filter((m) => /convertDate is not defined/i.test(m)),
			appErrors.join(" | "),
		).to.have.length(0);
	});
});
