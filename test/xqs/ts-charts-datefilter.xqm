xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for charts:chart's date-bucketing (modules/charts.xqm):
 : charts:hit-years (per-hit year extraction) and charts:dateFilter
 : (bucket membership test against a precomputed years-by-hit map).
 : charts:chart calls charts:dateFilter 13 times per results page, each
 : previously re-scanning every hit's full descendant::t:origDate subtree
 : from scratch - these tests pin the extraction/bucketing semantics so a
 : single-pass rewrite can't silently change which manuscripts land in
 : which era/century bucket.
 :)
module namespace tscharts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-charts-datefilter";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "../../modules/charts.xqm";

declare %private function tscharts:hit($notBefore as xs:string?, $notAfter as xs:string?) as element(t:TEI) {
	<t:TEI>
		<t:origDate>
			{
				if (exists($notBefore)) then
					attribute notBefore { $notBefore }
				else (
				)
			}
			{
				if (exists($notAfter)) then
					attribute notAfter { $notAfter }
				else (
				)
			}
		</t:origDate>
	</t:TEI>
};

declare %test:assertEquals(1650) function tscharts:hit-years-plain-4-digit-year() {
	charts:hit-years(tscharts:hit("1650", ()))
};

declare %test:assertEquals(1650) function tscharts:hit-years-truncates-full-date-at-hyphen() {
	charts:hit-years(tscharts:hit("1650-06-01", ()))
};

declare %test:assertTrue function tscharts:hit-years-collects-both-bounds() {
	let $years := charts:hit-years(tscharts:hit("1650", "1700"))
	return $years = 1650 and $years = 1700 and count($years) = 2
};

declare %test:assertTrue function tscharts:hit-years-blank-bound-excluded() {
	let $years := charts:hit-years(tscharts:hit("", "1700"))
	return $years = (1700)
};

declare %test:assertTrue function tscharts:hit-years-no-origDate-is-empty() {
	empty(charts:hit-years(<t:TEI />))
};

declare %private function tscharts:years-map($hits as element()*) as map(*) {
	map:merge($hits!map:entry(generate-id(.), charts:hit-years(.)))
};

declare %test:assertEquals(1) function tscharts:dateFilter-matches-on-notBefore-in-range() {
	let $hits := (tscharts:hit("1650", ()), tscharts:hit("1200", ()))
	return count(charts:dateFilter(1500, 1799, $hits, tscharts:years-map($hits)))
};

declare %test:assertEquals(1) function tscharts:dateFilter-matches-on-notAfter-in-range-even-if-notBefore-is-not() {
	(: same "any bound, any origDate" semantics as the original descendant:: scan :)
	let $hits := tscharts:hit("1200", "1650")
	return count(charts:dateFilter(1500, 1799, $hits, tscharts:years-map($hits)))
};

declare %test:assertEquals(0) function tscharts:dateFilter-excludes-hits-entirely-outside-range() {
	let $hits := tscharts:hit("1200", "1250")
	return count(charts:dateFilter(1500, 1799, $hits, tscharts:years-map($hits)))
};

declare %test:assertEquals(2) function tscharts:dateFilter-multiple-hits-same-bucket() {
	let $hits := (tscharts:hit("1650", ()), tscharts:hit("1700", ()), tscharts:hit("1200", ()))
	return count(charts:dateFilter(1500, 1799, $hits, tscharts:years-map($hits)))
};

declare %test:assertEquals(0) function tscharts:dateFilter-hit-with-no-origDate-never-matches() {
	let $hits := <t:TEI />
	return count(charts:dateFilter(1, 2000, $hits, tscharts:years-map($hits)))
};
