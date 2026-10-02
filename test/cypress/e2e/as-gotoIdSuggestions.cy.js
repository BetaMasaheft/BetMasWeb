// resources/js/lookup.js - the #GoTo suggestion list on as.html
//
// The loop here iterated `i < data.total` and indexed `data.items[i]`.
// /api/idlookup caps how many matches it returns, so ?total (the true
// count across the whole corpus) can be hundreds while the array holds
// only the cap - the loop ran off the end and threw on `data.items[i].id`,
// leaving the list empty. The array and ?total are separate concerns: the
// array says what arrived, ?truncated says why it is short, and only the
// array may drive the loop.
//
// The bare-object case is pre-existing but lands in the same path: eXist
// serialises a single-element sequence as an object rather than a
// one-element array, so `data.items[0]` was undefined for an exact hit.
//
// #GoTo only queries /api/idlookup while the "ID" radio (value 1, checked
// by default) is selected - the "Title" radio switches to /api/search.
//
// No custom timeouts: as.html loads in ~1-2s locally and each lookup is a
// single local GET.

const CAP = 100;

function suggest(needle) {
	cy.visit("/as.html?work-types=mss");
	cy.get('input[name="AttestedInType"][value="1"]').check({ force: true });
	// needs >4 characters before lookup.js will query at all
	cy.get("#GoTo").type(needle).blur();
}

it("a broad id shows a capped list that says it is truncated", () => {
	// "ation" matches 388 ids - more than the cap, more than 4 characters
	suggest("ation");

	cy.get("#gotohits option").should("have.length", CAP + 1);
	cy.get("#gotohits option").first().should("have.attr", "disabled");
	cy.get("#gotohits option").first().should("contain", "showing first 100 of 388 matches");

	// Every real suggestion must carry its id; the broken loop emitted
	// "undefined" here, and an over-running loop throws outright.
	cy.get("#gotohits option:not([disabled])").each(($opt) => {
		expect($opt.attr("value"), "suggestion has no id").to.match(/^[\w-]+$/);
	});
});

it("a single match shows one suggestion and no truncation notice", () => {
	// exercises the bare-object response: one match is not a one-element array
	suggest("Tabit");

	cy.get("#gotohits option").should("have.length", 1);
	cy.get("#gotohits option")
		.invoke("val")
		.should("match", /^[\w-]*Tabit[\w-]*$/);
	cy.get("#gotohits option").should("not.contain", "showing first");
});

it("a result set of exactly the cap is not flagged as truncated", () => {
	// "LOC51" matches exactly 100: nothing was dropped, so nothing is withheld
	suggest("LOC51");

	cy.get("#gotohits option").should("have.length", CAP);
	cy.get("#gotohits option").should("not.contain", "showing first");
});

it("an id with no matches leaves the list empty without erroring", () => {
	suggest("isTab");

	cy.get("#gotohits option").should("have.length", 0);
});
