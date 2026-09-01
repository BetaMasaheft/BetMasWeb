xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for the "#filters" advanced-search panel's plain fields
 : (modules/queries.xqm): q:rangeInput (min/max number-pair and
 : single-value inputs) and q:checkboxEcho (work-types/images/gender
 : checkboxes) - both previously carried hardcoded defaults or no
 : @checked logic at all, so none of them survived a reload. Tests the
 : -impl functions directly (pure logic, no live request needed) - see
 : q:rangeInput-impl's own doc comment for why the entry points
 : themselves aren't directly testable this way.
 :)
module namespace tsplainfields = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-plainfields";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

declare %test:assertEquals("42") function tsplainfields:rangeInput-echoes-submitted-value-at-position() {
	let $out := q:rangeInput-impl(<input name="dateRange" value="0001" />, "42", 1)
	return string($out/@value)
};

declare %test:assertEquals("0001") function tsplainfields:rangeInput-keeps-markups-own-default-without-param() {
	let $out := q:rangeInput-impl(<input name="dateRange" value="0001" />, (), 1)
	return string($out/@value)
};

declare %test:assertEquals("1999") function tsplainfields:rangeInput-echoes-second-position-of-a-pair() {
	let $out := q:rangeInput-impl(<input name="dateRange" value="2000" />, ("1000", "1999"), 2)
	return string($out/@value)
};

declare %test:assertEquals("2000") function tsplainfields:rangeInput-keeps-default-when-only-first-position-submitted(

) {
	let $out := q:rangeInput-impl(<input name="dateRange" value="2000" />, ("1000"), 2)
	return string($out/@value)
};

declare %test:assertEquals("dateRange") function tsplainfields:rangeInput-preserves-other-attributes() {
	let $out := q:rangeInput-impl(<input id="dateFrom" name="dateRange" value="0001" />, "42", 1)
	return string($out/@name)
};

declare %test:assertTrue function tsplainfields:checkboxEcho-checked-when-own-value-submitted() {
	let $out := q:checkboxEcho-impl(<input name="work-types" type="checkbox" value="mss" />, ("mss", "work"))
	return $out/@checked = "checked"
};

declare %test:assertFalse function tsplainfields:checkboxEcho-unchecked-when-a-different-value-submitted() {
	let $out := q:checkboxEcho-impl(<input name="work-types" type="checkbox" value="mss" />, ("work"))
	return exists($out/@checked)
};

declare %test:assertFalse function tsplainfields:checkboxEcho-unchecked-without-param() {
	let $out := q:checkboxEcho-impl(<input name="work-types" type="checkbox" value="mss" />, ())
	return exists($out/@checked)
};

declare %test:assertEquals("mss") function tsplainfields:checkboxEcho-preserves-own-value-attribute() {
	let $out := q:checkboxEcho-impl(<input name="work-types" type="checkbox" value="mss" />, ("mss"))
	return string($out/@value)
};
