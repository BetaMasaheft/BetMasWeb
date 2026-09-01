// newSearch.html's "#filters" panel plain fields (dateRange/height/width/
// margins/qn/birthRange/deathRange/floruitRange/anyDateRange number pairs,
// work-types/images/gender checkboxes) previously carried hardcoded
// defaults and no @checked logic at all - none of them survived a reload.
// q:rangeInput/q:checkboxEcho (modules/queries.xqm) fix that; this checks
// a representative sample across different sections rather than all ~40
// fields individually, since they all funnel through the same two shared
// functions.
//
// folia/qn are deliberately not covered here - #119 (a pre-existing,
// unrelated bug in q:par-folia/q:par-qn's own value-format contract)
// crashes the whole page for those two specific fields regardless of
// this echo work; q:rangeInput-impl's own XQSuite coverage already
// proves the echo logic itself is field-agnostic and correct.

it("GET /newSearch.html echoes dateRange, work-types and gender on reload", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=mss&dateRange=0500&dateRange=1500&gender=1");
	cy.get("#dateFrom").should("have.value", "0500");
	cy.get("#dateTo").should("have.value", "1500");
	cy.get('input[name="work-types"][value="mss"]').should("be.checked");
	cy.get('input[name="work-types"][value="work"]').should("not.be.checked");
	cy.get('input[name="gender"][value="1"]').should("be.checked");
	cy.get('input[name="gender"][value="2"]').should("not.be.checked");
});

it("GET /newSearch.html echoes height, images and anyDateRange on reload", () => {
	cy.visit(
		"/newSearch.html?searchType=text&work-types=mss&height=100&height=300&images=bm&anyDateRange=10&anyDateRange=90",
	);
	cy.get("#heightMin").should("have.value", "100");
	cy.get("#heightMax").should("have.value", "300");
	cy.get('input[name="images"][value="bm"]').should("be.checked");
	cy.get('input[name="images"][value="all"]').should("not.be.checked");
	cy.get("#anyDateFrom").should("have.value", "10");
	cy.get("#anyDateTo").should("have.value", "90");
});

it("GET /newSearch.html without those params keeps the markup's own defaults", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#dateFrom").should("have.value", "0001");
	cy.get("#dateTo").should("have.value", "2000");
	cy.get('input[name="work-types"][value="mss"]').should("not.be.checked");
	cy.get('input[name="gender"][value="1"]').should("not.be.checked");
});
