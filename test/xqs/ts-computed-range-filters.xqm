xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for computed-dimension / layout range filter paths
 : wired in modules/queries.xqm (BetMasWeb#113).
 :)
module namespace tscrange = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-computed-range-filters";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

declare
	%test:assertEquals(
		"[descendant::t:dimensions[@subtype eq 'computed'][@type eq 'outer']/t:height[@quantity ge 50][@quantity le 300]]"
	)
function tscrange:height-predicate() {
	q:computed-height-filter("50,300")
};

declare
	%test:assertEquals(
		"[descendant::t:dimensions[@subtype eq 'computed'][@type eq 'outer']/t:width[@quantity ge 10][@quantity le 400]]"
	)
function tscrange:width-predicate() {
	q:computed-width-filter("10,400")
};

declare
	%test:assertEquals(
		"[descendant::t:dimensions[@subtype eq 'computed'][@type eq 'outer']/t:depth[@quantity ge 5][@quantity le 80]]"
	)
function tscrange:depth-predicate() {
	q:computed-depth-filter("5,80")
};

declare %test:assertEquals("") function tscrange:height-default-is-no-filter() {
	string(q:computed-height-filter("1,1000"))
};

declare
	%test:assertEquals("[descendant::t:layout[@subtype eq 'computed']/t:writtenLines[@quantity ge 3][@quantity le 17]]")
function tscrange:written-lines-predicate() {
	q:computed-written-lines-filter("3,17")
};

declare
	%test:assertEquals(
		"[descendant::t:dimensions[@subtype eq 'computed'][@type eq 'margin']/t:dim[@type eq 'top'][@quantity ge 5][@quantity le 20]]"
	)
function tscrange:margin-top-predicate() {
	q:computed-margin-filter("5,20", "top")
};

declare %test:assertEquals("[descendant::t:msPartsCount[@quantity ge 3]]") function tscrange:ms-parts-count-predicate(

) {
	q:ms-parts-count-filter("3")
};

declare %test:assertEquals("") function tscrange:ms-parts-count-empty-is-no-filter() {
	string(q:ms-parts-count-filter(""))
};
