// #fields was previously guarded by q:searchTypeFieldset checking
// searchType = "fields" - a value #SType's real options (q:querytype,
// modules/queries.xqm) never actually include, so it could never open on
// any real request (found in code review of #118). q:fieldsSection reveals
// it based on whether any of its own ten field-scoped search rows
// (q:fieldInputXXX) has a submitted value instead - see
// newSearch-searchTypeReveal.cy.js for #xpath/#sparqls/#otherclavis, which
// are unaffected (their fields don't have this bug's shape).

it("GET /newSearch.html?title-field=... reveals #fields without any client interaction", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary&title-field=Mary");
	cy.get("#fields").should("be.visible");
});

it("GET /newSearch.html?searchType=text&query=Mary (no field params) leaves #fields hidden", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#fields").should("not.be.visible");
});
