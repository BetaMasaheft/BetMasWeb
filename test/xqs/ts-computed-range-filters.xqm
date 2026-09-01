xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for computed-dimension / layout range filter paths
 : wired in modules/queries.xqm (BetMasWeb#113).
 :)
module namespace tscrange = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-computed-range-filters";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";
import module namespace expandnorm = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/expand-normalize-dimensions" at "../../modules/expand-normalize-dimensions.xqm";

declare variable $tscrange:outer-mm := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="manuscript" xml:id="MSrangeTEST">
	<teiHeader><fileDesc><titleStmt><title>range filter fixture</title></titleStmt></fileDesc></teiHeader>
	<text>
		<body>
			<msDesc>
				<physDesc>
					<objectDesc>
						<supportDesc>
							<extent>
								<dimensions type="outer" unit="mm"><height>220</height><width>170</width><depth>85</depth></dimensions>
							</extent>
						</supportDesc>
						<layoutDesc><layout columns="2" writtenLines="17 18" /></layoutDesc>
					</objectDesc>
				</physDesc>
			</msDesc>
		</body>
	</text>
</TEI>;

declare variable $tscrange:two-parts := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="manuscript" xml:id="MSpartsTEST">
	<teiHeader>
		<fileDesc>
			<sourceDesc>
				<msDesc>
					<msPart xml:id="p1"><msIdentifier /></msPart>
					<msPart xml:id="p2"><msIdentifier /></msPart>
					<msPart xml:id="p3"><msIdentifier /></msPart>
				</msDesc>
			</sourceDesc>
		</fileDesc>
	</teiHeader>
	<text><body><p /></body></text>
</TEI>;

declare %private function tscrange:computed-height-qty($tei as element(t:TEI)) as xs:double {
	xs:double($tei//t:dimensions[@subtype eq "computed"][@type eq "outer"]/t:height/@quantity)
};

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

declare
	%test:assertEquals(
		"[descendant::t:layout[@subtype eq 'computed'][matches(@columns,'^\d+$')][@columns ge 2][@columns le 3]]"
	)
function tscrange:columns-predicate() {
	q:computed-columns-filter("2,3")
};

declare %test:assertEquals("[descendant::t:msPartsCount[@quantity ge 3]]") function tscrange:ms-parts-count-predicate(

) {
	q:ms-parts-count-filter("3")
};

declare %test:assertEquals("") function tscrange:ms-parts-count-empty-is-no-filter() {
	string(q:ms-parts-count-filter(""))
};

declare %test:assertEquals("") function tscrange:malformed-range-no-filter() {
	string(q:computed-height-filter("50,"))
};

declare %test:assertEquals("") function tscrange:non-numeric-ms-parts-no-filter() {
	string(q:ms-parts-count-filter("1] | //t:TEI["))
};

declare %test:assertTrue function tscrange:height-quantity-in-filter-range() {
	let $tei := expandnorm:normalize-tei($tscrange:outer-mm)
	let $q := tscrange:computed-height-qty($tei)
	return $q ge 200 and $q le 250
};

declare %test:assertFalse function tscrange:height-quantity-outside-filter-range() {
	let $tei := expandnorm:normalize-tei($tscrange:outer-mm)
	let $q := tscrange:computed-height-qty($tei)
	return $q ge 300 and $q le 400
};

declare %test:assertEquals("18") function tscrange:written-lines-quantity-on-normalized-tei() {
	let $tei := expandnorm:normalize-tei($tscrange:outer-mm)
	return string($tei//t:layout[@subtype eq "computed"]/t:writtenLines/@quantity)
};

declare %test:assertEquals("2") function tscrange:columns-on-normalized-tei() {
	let $tei := expandnorm:normalize-tei($tscrange:outer-mm)
	return string($tei//t:layout[@subtype eq "computed"]/@columns)
};

declare %test:assertEquals("3") function tscrange:ms-parts-count-on-normalized-tei() {
	let $tei := expandnorm:normalize-tei($tscrange:two-parts)
	return string($tei//t:msPartsCount/@quantity)
};
