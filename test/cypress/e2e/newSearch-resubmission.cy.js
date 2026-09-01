// #gsf is one <form> wrapping every "#filters" panel field. CSS
// display:none alone doesn't stop a browser from submitting a hidden
// field's value - only `disabled` does. Before this fix, a plain keyword
// search resubmitted every inactive field's own hardcoded markup default
// (dateRange="0001"/"2000" etc.), which q:any-active can't tell apart from
// a genuinely-submitted value, springing the entire panel and every
// guarded corpus-scan section open on every single search.
//
// curl-based tests can't verify this: curl doesn't parse HTML forms or
// respect `disabled` at all, it just sends whatever params it's given -
// only a real browser's own form-submission behavior proves the fix.

it("submitting a bare keyword search does not resubmit the panel's hardcoded defaults (regression)", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#advanced").should("not.be.visible");
	// query is already filled from the URL - just resubmit the form as-is
	cy.get("#submit-data").click();
	cy.url().should("not.include", "dateRange");
	cy.url().should("not.include", "height");
	cy.url().should("not.include", "qn=");
	cy.get("#advanced").should("not.be.visible");
	cy.get("#manuscriptsFilters").should("not.be.visible");
});

it("opening the panel live via '+' makes General filters submittable", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#showfilters").click();
	cy.get("#advanced").should("be.visible");
	cy.get("#dateFrom").clear().type("1500");
	cy.get("#dateTo").clear().type("1600");
	cy.get("#submit-data").click();
	cy.url().should("include", "dateRange=1500");
	cy.url().should("include", "dateRange=1600");
});

it("picking a collection type live makes that section submittable, others stay excluded", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#showfilters").click();
	cy.get("#collectionfilter").select("mss");
	cy.get("#manuscriptsFilters").should("be.visible");
	cy.get("#heightMin").clear().type("100");
	cy.get("#heightMax").clear().type("300");
	cy.get("#submit-data").click();
	cy.url().should("include", "height=100");
	cy.url().should("include", "height=300");
	// works/persons/places were never opened - their own defaults must
	// still be excluded even though the form as a whole was submitted
	cy.url().should("not.include", "divtype");
	cy.url().should("not.include", "gender");
	cy.url().should("not.include", "anyDateRange");
});
