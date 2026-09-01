xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/queries.xqm's q:max-written-lines/q:max-folia
 : - the corpus-derived slider bounds backing forms/formWL.html and
 : forms/formfolia.html, replacing the hardcoded literals both widgets
 : used to carry. Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :)
module namespace tsformbounds = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-formbounds";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

(:~
 : Floor is 100 until corpus re-expand emits computed layouts; after
 : re-expand the real max is expected to exceed the old hardcoded bound.
 :)
declare %test:assertXPath("$result ge 100") function tsformbounds:max-written-lines-above-old-hardcoded-value() {
	q:max-written-lines()
};

(:~
 : Until re-expand, computed layout candidates are empty and the bound
 : falls back to 100; after re-expand it tracks the computed corpus max.
 :)
declare %test:assertTrue function tsformbounds:max-written-lines-matches-corpus() {
	let $computed := collection($config:data-rootMS)//t:layout[@subtype =
		"computed"]/@writtenLines[. castable as xs:integer]
	return if (exists($computed)) then
		q:max-written-lines() = max($computed)
	else
		q:max-written-lines() = 100
};

(:~
 : q:max-folia must never return one of the 3 known-bad EMML values
 : (BetaMasaheft/Manuscripts#3505) - this is the one behavior the
 : exclusion predicate exists to guarantee.
 :)
declare
	%test:assertXPath("not($result = (1483, 2927, 5533))")
function tsformbounds:max-folia-excludes-known-bad-values() {
	q:max-folia()
};

declare %test:assertXPath("$result gt 1000") function tsformbounds:max-folia-above-old-hardcoded-value() {
	q:max-folia()
};
