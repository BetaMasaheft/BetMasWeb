// newSearch.html loads w3.js without dateConversions.js. w3.js walks
// every <time data-calendar> and calls convertDate(); when person
// search hits include calendar dates, that throws ReferenceError and
// Cypress fails the visit (seen on CI for ?gender=1 with fuller data).
it("does not throw convertDate when person results include calendar <time>", () => {
	const appErrors = [];
	cy.visit("/newSearch.html?searchType=text&work-types=pers&query=Walda", {
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
