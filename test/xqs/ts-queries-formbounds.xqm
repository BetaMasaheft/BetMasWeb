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
 : Sanity bound - the real corpus max is a few hundred, nowhere near
 : the old hardcoded "100". A regression that silently reverted to a
 : too-small literal would still pass a bare "returns an integer" test,
 : so assert a floor as well.
 :)
declare %test:assertXPath("$result gt 100") function tsformbounds:max-written-lines-above-old-hardcoded-value() {
	q:max-written-lines()
};

(:~
 : Compares two dynamically-computed values (the cached bound vs a fresh
 : corpus scan) - no static literal to hand assertXPath, so this stays
 : assertTrue.
 :)
declare %test:assertTrue function tsformbounds:max-written-lines-matches-corpus() {
	q:max-written-lines() = max(collection($config:data-rootMS)//t:layout/@writtenLines[. castable as xs:integer])
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
