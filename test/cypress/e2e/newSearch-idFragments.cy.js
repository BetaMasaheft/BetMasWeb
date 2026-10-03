// Degenerate ID-fragment searches must render an empty result page, not the
// whole corpus and not an exception.
//
// Both q:bmid and q:clavis scan with contains(@xml:id, $fragment) over the
// expanded collection. That predicate stops discriminating for an empty
// fragment - contains($x, "") and contains($x, ()) are true for every record -
// so an absent or blank query used to hand back all 58,167 t:TEI in ~18s
// (bmid) or raise XPTY0004 from format-number (clavis, an HTTP 400).
//
// These reach q:query with exactly two request parameters, which is why none
// of its own guards matched: those require zero or three. The pure-function
// contract and the corpus counts live in test/xqs/ts-queries-idscan.xqm; this
// spec covers only that the request path renders the guarded answer.
//
// A valid-but-short fragment is deliberately absent here. bmid is a paginated
// result page (q:results, 40 rows), not the idlookup typeahead, so it is not
// capped and a one-character search legitimately lists thousands of records.

const degenerate = [
	{ searchType: "bmid", query: "", why: "empty fragment" },
	{ searchType: "bmid", query: "%20%20", why: "whitespace-only fragment" },
	{ searchType: "clavis", query: "", why: "blank fragment" },
	{ searchType: "clavis", query: "abc", why: "non-numeric fragment" },
];

degenerate.forEach(({ searchType, query, why }) => {
	it(`GET /newSearch.html?searchType=${searchType}&query=${query} (${why}) returns an empty result page`, () => {
		cy.request({
			url: `/newSearch.html?searchType=${searchType}&query=${query}`,
			method: "GET",
			failOnStatusCode: false,
			timeout: 20000,
		}).then((res) => {
			expect(res.status, `responded with ${res.status}`).to.eq(200);
			expect(res.body, "response should not contain an exception").to.not.include("XPTY0004");
			expect(res.body, "hit-count should be 0").to.match(/id="hit-count">0</);
		});
	});
});

// The guards must not have been written as a blanket rejection: a real
// fragment still has to reach its records over HTTP.
it("GET /newSearch.html?searchType=bmid&query=LIT1367Exodus still returns its record", () => {
	cy.request({
		url: "/newSearch.html?searchType=bmid&query=LIT1367Exodus",
		method: "GET",
		failOnStatusCode: false,
		timeout: 20000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body, "response should not contain an exception").to.not.include("XPTY0004");
		expect(res.body, "hit-count should not be 0").to.not.match(/id="hit-count">0</);
	});
});

it("GET /newSearch.html?searchType=clavis&query=0050 still returns its work", () => {
	cy.request({
		url: "/newSearch.html?searchType=clavis&query=0050",
		method: "GET",
		failOnStatusCode: false,
		timeout: 20000,
	}).then((res) => {
		expect(res.status, `responded with ${res.status}`).to.eq(200);
		expect(res.body, "response should not contain an exception").to.not.include("XPTY0004");
		expect(res.body, "hit-count should not be 0").to.not.match(/id="hit-count">0</);
	});
});
