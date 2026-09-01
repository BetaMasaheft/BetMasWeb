// newSearch.html's #manuscriptsFilters/#worksFilters/#persFilters/
// #placesFilters were only ever shown by initCollectionFilter()'s
// (resources/js/selectForm.js) #collectionfilter change handler - a pure
// client-side convenience with no persisted state, so a reload always
// lost the section a user had open. q:manuscriptsFiltersSection and its
// three siblings (modules/queries.xqm) reveal each section server-side
// when any of its OWN submitted params is active, deliberately ignoring
// #collectionfilter's own dropdown value - same precedent as as.html's
// app:worksFiltersSection (PR #101).
//
// work-types=work&author=... is deliberately avoided here - #120 (a
// pre-existing, unrelated bug in q:text's search execution) crashes the
// whole page for that specific combination regardless of this reveal
// work; author alone (no work-types) is used instead to prove
// #worksFiltersSection's own reveal logic without tripping it.

it("GET /newSearch.html with no section-specific params keeps all four sections hidden", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#manuscriptsFilters").should("not.be.visible");
	cy.get("#worksFilters").should("not.be.visible");
	cy.get("#persFilters").should("not.be.visible");
	cy.get("#placesFilters").should("not.be.visible");
});

it("GET /newSearch.html?script=geez reveals only #manuscriptsFilters", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=mss&script=geez");
	cy.get("#manuscriptsFilters").should("be.visible");
	cy.get("#worksFilters").should("not.be.visible");
	cy.get("#persFilters").should("not.be.visible");
	cy.get("#placesFilters").should("not.be.visible");
});

// "author" is shared between q:MssPersRoles' production-role search and
// q:WorkAuthors' own "author" param. A bare author=... request should
// reveal #worksFilters only; #manuscriptsFilters needs real manuscripts
// evidence (another mss field, or author together with work-types=mss).
it("GET /newSearch.html?author=... reveals only #worksFilters, not #manuscriptsFilters", () => {
	cy.visit("/newSearch.html?searchType=text&author=PRS12345");
	cy.get("#manuscriptsFilters").should("not.be.visible");
	cy.get("#worksFilters").should("be.visible");
	cy.get("#persFilters").should("not.be.visible");
	cy.get("#placesFilters").should("not.be.visible");
});

it("GET /newSearch.html?author=...&work-types=mss reveals both manuscripts and works sections", () => {
	cy.visit("/newSearch.html?searchType=text&author=PRS12345&work-types=mss");
	cy.get("#manuscriptsFilters").should("be.visible");
	cy.get("#worksFilters").should("be.visible");
});

it("GET /newSearch.html?gender=1 reveals only #persFilters", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=pers&gender=1");
	cy.get("#manuscriptsFilters").should("not.be.visible");
	cy.get("#worksFilters").should("not.be.visible");
	cy.get("#persFilters").should("be.visible");
	cy.get("#placesFilters").should("not.be.visible");
});

it("GET /newSearch.html?placetype=region reveals only #placesFilters", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=place&placetype=region");
	cy.get("#manuscriptsFilters").should("not.be.visible");
	cy.get("#worksFilters").should("not.be.visible");
	cy.get("#persFilters").should("not.be.visible");
	cy.get("#placesFilters").should("be.visible");
});
