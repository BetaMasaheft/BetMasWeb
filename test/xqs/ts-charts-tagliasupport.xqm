xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for charts:chart's taglia (height+width) bucketing
 : (modules/charts.xqm): charts:hit-taglias (per-hit extraction) and
 : charts:tagliasupport (bucket-ratio test against a precomputed
 : taglias-by-hit map). Inside charts:chart, tagliasupport was called
 : once per (taglia-group x date-bucket) pair - up to ~168 calls per
 : results page - each re-scanning its whole date-bucket's extents from
 : scratch; that repeated scan measured ~12.6s of a ~13.8s charts:chart
 : call. These tests pin the extraction/ratio semantics so a
 : precomputed-map rewrite can't silently change the reported ratios.
 :)
module namespace tstaglia = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-charts-tagliasupport";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "../../modules/charts.xqm";

declare %private function tstaglia:extent($height as xs:integer, $width as xs:integer) as element(t:extent) {
	<t:extent>
		<t:dimensions subtype="computed" type="outer">
			<t:height quantity="{ $height }" />
			<t:width quantity="{ $width }" />
			<t:depth quantity="20" />
		</t:dimensions>
	</t:extent>
};

declare %private function tstaglia:hit($extents as element(t:extent)*) as element(t:TEI) {
	<t:TEI>{ $extents }</t:TEI>
};

declare %test:assertEquals(250) function tstaglia:hit-taglias-sums-height-and-width() {
	charts:hit-taglias(tstaglia:hit(tstaglia:extent(100, 150)))
};

declare %test:assertTrue function tstaglia:hit-taglias-one-value-per-extent() {
	let $taglias := charts:hit-taglias(tstaglia:hit((tstaglia:extent(100, 150), tstaglia:extent(50, 50))))
	return count($taglias) = 2 and $taglias = 250 and $taglias = 100
};

declare %test:assertTrue function tstaglia:hit-taglias-extent-without-depth-excluded() {
	let $incomplete := <t:extent>
		<t:dimensions subtype="computed" type="outer"><t:height quantity="100" /><t:width quantity="150" /></t:dimensions>
	</t:extent>
	return empty(charts:hit-taglias(tstaglia:hit($incomplete)))
};

declare %private function tstaglia:taglias-map($hits as element()*) as map(*) {
	map:merge($hits!map:entry(generate-id(.), charts:hit-taglias(.)))
};

declare %test:assertEquals(".5") function tstaglia:tagliasupport-ratio-of-matching-extents-to-total() {
	(:
	 : format-number(..., "#.#") - pre-existing pattern, unchanged by this
	 : rewrite - omits the leading zero, so 1/2 renders as ".5" not "0.5"
	 :)
	let $hits := (tstaglia:hit(tstaglia:extent(100, 150)), tstaglia:hit(tstaglia:extent(10, 10)))
	return charts:tagliasupport($hits, 2, 200, 299, tstaglia:taglias-map($hits))
};

declare %test:assertEquals(".0") function tstaglia:tagliasupport-no-matches-in-range() {
	let $hits := tstaglia:hit(tstaglia:extent(10, 10))
	return charts:tagliasupport($hits, 1, 200, 299, tstaglia:taglias-map($hits))
};

declare %test:assertEquals(1) function tstaglia:tagliasupport-counts-every-matching-extent-on-a-hit() {
	(: same "for $ms in $mssDate//t:extent[...]" semantics as the original scan - a hit with two matching extents counts twice :)
	let $hits := tstaglia:hit((tstaglia:extent(100, 150), tstaglia:extent(120, 140)))
	return xs:double(charts:tagliasupport($hits, 2, 200, 299, tstaglia:taglias-map($hits)))
};
