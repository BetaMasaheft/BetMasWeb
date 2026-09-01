// newSearch.html's "#filters" advanced-search panel used to be an empty
// <fieldset>, populated only by a one-time AJAX fetch of the now-deleted,
// never-templated filters.html.txt (#116). It's inlined and server-templated
// now: q:filtersPanelFieldset reveals #advanced on reload when any of its
// ~60 possible fields is submitted, and each section's own q:includeXXX
// guard (#117) renders real content only when that section is active,
// leaving every other section as a cheap empty placeholder - the whole
// point being that a plain, unfiltered load stays as fast as before.

// work-types checkboxes live inside the advanced panel itself
// (filters.html.txt's own markup), so a plain free-text query with no
// work-types and no other panel field is the actual "panel untouched" case.
it("GET /newSearch.html?query=Mary (no advanced filters used) keeps #advanced hidden", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#advanced").should("not.be.visible");
	cy.get("#generalRangeIndexes").should("exist").children().should("have.length", 0);
	cy.get("#mssRangeIndexes").should("exist").children().should("have.length", 0);
});

it("GET /newSearch.html?ident=geez reveals #advanced and populates only the general section", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=mss&ident=geez");
	cy.get("#advanced").should("be.visible");
	cy.get("#generalRangeIndexes").children().should("have.length.greaterThan", 0);
	cy.get('#generalRangeIndexes input[name="ident"]').should("exist");
	// an unrelated section stays an empty, cheap placeholder
	cy.get("#mssRangeIndexes").children().should("have.length", 0);
});

it("GET /newSearch.html?script=geez reveals #advanced and populates only the manuscripts range-index section", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=mss&script=geez");
	cy.get("#advanced").should("be.visible");
	cy.get("#mssRangeIndexes").children().should("have.length.greaterThan", 0);
	cy.get("#generalRangeIndexes").children().should("have.length", 0);
});
