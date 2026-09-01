// newSearch.html's #SType dropdown already restores its *value* correctly
// server-side (q:querytype, modules/queries.xqm) - the sibling fieldsets it's
// supposed to reveal (#fields/#xpath/#sparqls/#otherclavis, all "w3-hide" by
// default) were only shown by selectForm.js's `change` handler, which never
// fires on a plain page load from a pre-selected <option>. Same root cause
// class as as.html's pre-#101 bug. Issue #109.
//
// Each case adds the minimal extra params needed to dodge pre-existing,
// unrelated crashes/hangs on an empty query body for that searchType
// (q:otherclavis's range:field cardinality error, q:sparqlRes's parse
// error, and #3's unfiltered-listing slowness) - not this test's concern.

const cases = [
	{ searchType: "xpath", fieldset: "#xpath", extra: "" },
	{
		searchType: "sparql",
		fieldset: "#sparqls",
		extra: "&query=" + encodeURIComponent("SELECT * WHERE { ?s ?p ?o } LIMIT 1"),
	},
	{ searchType: "otherclavis", fieldset: "#otherclavis", extra: "&clavistype=BHG&query=1" },
	{ searchType: "fields", fieldset: "#fields", extra: "&work-types=mss" },
];

cases.forEach(({ searchType, fieldset, extra }) => {
	it(`GET /newSearch.html?searchType=${searchType} reveals ${fieldset} without any client interaction`, () => {
		cy.visit(`/newSearch.html?searchType=${searchType}${extra}`);
		cy.get(fieldset).should("be.visible");
	});
});

it("GET /newSearch.html?searchType=text&work-types=mss leaves #fields/#xpath/#sparqls/#otherclavis hidden", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=mss");
	cy.get("#fields").should("not.be.visible");
	cy.get("#xpath").should("not.be.visible");
	cy.get("#sparqls").should("not.be.visible");
	cy.get("#otherclavis").should("not.be.visible");
});
