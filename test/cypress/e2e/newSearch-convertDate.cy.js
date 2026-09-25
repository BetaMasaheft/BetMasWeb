// newSearch.html loads w3.js after dateConversions.js. w3.js walks every
// <time data-calendar> and calls convertDate(); missing that script throws
// ReferenceError and Cypress fails the visit (seen on CI for person hits
// with calendar dates).
//
// Use BM id search for PRS4374Gabreel: floruit nested calendar dates render
// as time[data-calendar] via summaryPers, and bmid is a single xml:id hit
// (~0.5s). Free-text query=Walda is >300 hits (ft:score page-1 only) and
// often omits that carrier; free-text query=PRS4374Gabreel does not match
// lucene the way we need (0 calendar times locally).
it("does not throw convertDate when person results include calendar <time>", () => {
	const appErrors = [];
	cy.visit("/newSearch.html?searchType=bmid&query=PRS4374Gabreel", {
		onBeforeLoad(win) {
			win.addEventListener("error", (e) => {
				appErrors.push(String(e.message || e.error));
			});
		},
	});
	cy.get("time[data-calendar]").should("have.length.gt", 0);
	cy.wrap(null).should(() => {
		expect(
			appErrors.filter((m) => /convertDate is not defined/i.test(m)),
			appErrors.join(" | "),
		).to.have.length(0);
	});
});
