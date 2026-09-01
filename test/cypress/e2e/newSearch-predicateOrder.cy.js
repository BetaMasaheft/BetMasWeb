// #120: q:text (modules/queries.xqm) crashed whenever a content-matching
// predicate (e.g. "author"'s descendant::t:persName[@role='author']/@ref eq
// ...) landed first in the concatenated XPath predicate chain, ahead of a
// type-establishing predicate like work-types' [@type="work"]. Root-caused
// outside the app (see #120 comments): reordering the same three predicates
// with the content-matching one anywhere but first always worked; with it
// first, eXist's optimizer threw "cannot convert xs:boolean('true') to a
// node set" every time, regardless of which other predicates followed.
//
// request:get-parameter-names() (what q:parameters2arguments iterates)
// returns "author" ahead of "work-types" whenever both are submitted, so
// this crashed on every real request combining them - not a rare edge case.

it("GET /newSearch.html?work-types=work&author=... does not crash (regression #120)", () => {
	cy.request({
		url: "/newSearch.html?searchType=text&work-types=work&author=PRS12345",
		method: "GET",
		failOnStatusCode: false,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body, "response should not contain an exception").to.not.include("error has occurred");
		expect(res.body, "response should not contain the boolean-to-node-set error").to.not.include(
			"cannot convert xs:boolean",
		);
	});
});
