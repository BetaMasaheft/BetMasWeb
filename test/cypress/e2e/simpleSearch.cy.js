// simpleSearch.html - the search input (query, id="q") was a plain hardcoded
// <input>, not the app:queryinput template (modules/app.xqm) that as.html
// uses for exactly this purpose (see its doc comment: "makes sure that when
// the page is reloaded with the results the value entered remains in the
// input element"). Results/pagination already round-trip via GET params with
// no client JS, but the box itself went blank on reload, losing the user's
// query even though matching results were still shown below it. Issue #110.

it("GET /simpleSearch.html?query=simple echoes the submitted query back into the search input", () => {
	cy.request("/simpleSearch.html?query=simple")
		.its("body")
		.should(
			"match",
			/<input[^>]*name="query"[^>]*value="simple"[^>]*>|<input[^>]*value="simple"[^>]*name="query"[^>]*>/,
		);
});
