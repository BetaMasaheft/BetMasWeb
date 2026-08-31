xquery version "3.1";

module namespace tsexpnorm = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-normalize-dimensions";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";
import module namespace expandnorm = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/expand-normalize-dimensions" at "../../modules/expand-normalize-dimensions.xqm";

declare function tsexpnorm:wrap($body as element()) as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="manuscript" xml:id="MSnormTEST">
		<teiHeader><fileDesc><titleStmt><title>normalize fixture</title></titleStmt></fileDesc></teiHeader>
		<text><body><msDesc><physDesc><objectDesc>{ $body }</objectDesc></physDesc></msDesc></body></text>
	</TEI>
};

declare function tsexpnorm:normalize($body as element()) as element(t:TEI) {
	let $expanded := expand:tei2fulltei(tsexpnorm:wrap($body), ())[self::t:TEI]
	return expandnorm:normalize-tei($expanded)
};

declare variable $tsexpnorm:clean-mm := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent>
			<dimensions type="outer" unit="mm"><height>182</height><width>140</width><depth>45</depth></dimensions>
		</extent>
	</supportDesc>
);

declare %test:assertEquals(1) function tsexpnorm:clean-mm-computed-count() {
	count(tsexpnorm:normalize($tsexpnorm:clean-mm//t:objectDesc/node())//t:dimensions[@subtype = "computed"])
};

declare %test:assertEquals("182") function tsexpnorm:clean-mm-height-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:clean-mm//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare variable $tsexpnorm:comma-cm := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent>
			<dimensions type="outer" unit="cm">
				<height>22,0</height>
				<width>17,2</width>
				<depth>8,5 cm (Nomi)</depth>
			</dimensions>
		</extent>
	</supportDesc>
);

declare %test:assertEquals("220") function tsexpnorm:comma-cm-height-mm() {
	string(
		tsexpnorm:normalize($tsexpnorm:comma-cm//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare %test:assertEquals("85") function tsexpnorm:comma-cm-depth-mm() {
	string(
		tsexpnorm:normalize($tsexpnorm:comma-cm//t:objectDesc/node())//t:dimensions[@subtype = "computed"]/t:depth/@quantity
	)
};

declare variable $tsexpnorm:leaf-range := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="leaf" unit="mm"><height>210-215</height><width>265-270</width></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("210") function tsexpnorm:leaf-range-atLeast() {
	string(
		tsexpnorm:normalize($tsexpnorm:leaf-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@atLeast
	)
};

declare variable $tsexpnorm:unparseable := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer" unit="mm"><height>ca.184</height></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals(0) function tsexpnorm:unparseable-skips-computed() {
	count(tsexpnorm:normalize($tsexpnorm:unparseable//t:objectDesc/node())//t:dimensions[@subtype = "computed"])
};

declare variable $tsexpnorm:written-lines := tsexpnorm:wrap(
	<layoutDesc xmlns="http://www.tei-c.org/ns/1.0"><layout columns="2" writtenLines="17 18" /></layoutDesc>
);

declare %test:assertEquals("18") function tsexpnorm:written-lines-upper-bound() {
	string(
		tsexpnorm:normalize($tsexpnorm:written-lines//t:objectDesc/node())//t:layout[@subtype = "computed"]/@writtenLines
	)
};

declare %test:assertEquals(1) function tsexpnorm:re-expand-idempotent() {
	let $once := tsexpnorm:normalize($tsexpnorm:clean-mm//t:objectDesc/node())
	let $twice := expandnorm:normalize-tei($once)
	return count($twice//t:dimensions[@subtype = "computed"])
};

declare variable $tsexpnorm:inch-block := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer" unit="in"><height>8</height></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("203.2") function tsexpnorm:inch-to-mm() {
	string(
		tsexpnorm:normalize($tsexpnorm:inch-block//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare variable $tsexpnorm:margin-text-range := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="margin" unit="mm"><dim type="top">10-13</dim></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("11.5") function tsexpnorm:margin-text-range-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:margin-text-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:dim[@type = "top"]/@quantity
	)
};

declare %test:assertEquals("10") function tsexpnorm:margin-text-range-atLeast() {
	string(
		tsexpnorm:normalize($tsexpnorm:margin-text-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:dim[@type = "top"]/@atLeast
	)
};

declare variable $tsexpnorm:margin-layout := tsexpnorm:wrap(
	<layoutDesc xmlns="http://www.tei-c.org/ns/1.0">
		<layout><dimensions type="margin" unit="mm"><dim type="top">10-13</dim></dimensions></layout>
	</layoutDesc>
);

declare %test:assertEquals("11.5") function tsexpnorm:margin-layout-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:margin-layout//t:objectDesc/node())//t:layout/t:dimensions[@subtype =
			"computed"]/t:dim[@type = "top"]/@quantity
	)
};

declare variable $tsexpnorm:margin-attr-range := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent>
			<dimensions type="margin" unit="mm"><dim atLeast="15" atMost="20" type="top">15-20</dim></dimensions>
		</extent>
	</supportDesc>
);

declare %test:assertEquals("15") function tsexpnorm:margin-attr-range-atLeast() {
	string(
		tsexpnorm:normalize($tsexpnorm:margin-attr-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:dim[@type = "top"]/@atLeast
	)
};

declare %test:assertEquals("20") function tsexpnorm:margin-attr-range-atMost() {
	string(
		tsexpnorm:normalize($tsexpnorm:margin-attr-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:dim[@type = "top"]/@atMost
	)
};

declare variable $tsexpnorm:margin-spaced-range := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="margin" unit="mm"><dim type="intercolumn">13 - 12</dim></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("12.5") function tsexpnorm:margin-spaced-range-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:margin-spaced-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:dim[@type = "intercolumn"]/@quantity
	)
};

declare variable $tsexpnorm:en-dash-range := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="leaf" unit="mm"><height>24–30</height></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("27") function tsexpnorm:en-dash-range-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:en-dash-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare %test:assertEquals("24") function tsexpnorm:en-dash-range-atLeast() {
	string(
		tsexpnorm:normalize($tsexpnorm:en-dash-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@atLeast
	)
};

declare variable $tsexpnorm:written-lines-single := tsexpnorm:wrap(
	<layoutDesc xmlns="http://www.tei-c.org/ns/1.0"><layout writtenLines="20" /></layoutDesc>
);

declare %test:assertEquals("20") function tsexpnorm:written-lines-single-value() {
	string(
		tsexpnorm:normalize($tsexpnorm:written-lines-single//t:objectDesc/node())//t:layout[@subtype =
			"computed"]/@writtenLines
	)
};

declare variable $tsexpnorm:written-lines-trim := tsexpnorm:wrap(
	<layoutDesc xmlns="http://www.tei-c.org/ns/1.0"><layout writtenLines="22 27 " /></layoutDesc>
);

declare %test:assertEquals("27") function tsexpnorm:written-lines-trim-upper() {
	string(
		tsexpnorm:normalize($tsexpnorm:written-lines-trim//t:objectDesc/node())//t:layout[@subtype =
			"computed"]/@writtenLines
	)
};

declare variable $tsexpnorm:decimal-dot-mm := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer" unit="mm"><height>13.5</height></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("13.5") function tsexpnorm:decimal-dot-mm-height() {
	string(
		tsexpnorm:normalize($tsexpnorm:decimal-dot-mm//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare variable $tsexpnorm:partial-hwd := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer" unit="mm"><height>100</height><width>50</width></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals(0) function tsexpnorm:partial-hwd-no-computed-depth() {
	count(tsexpnorm:normalize($tsexpnorm:partial-hwd//t:objectDesc/node())//t:dimensions[@subtype = "computed"]/t:depth)
};

declare %test:assertEquals(2) function tsexpnorm:partial-hwd-computed-axis-count() {
	count(
		tsexpnorm:normalize($tsexpnorm:partial-hwd//t:objectDesc/node())//t:dimensions[@subtype = "computed"]/(
			t:height | t:width | t:depth
		)
	)
};

declare variable $tsexpnorm:empty-depth-text := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer" unit="mm"><height>100</height><width>50</width><depth /></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals(0) function tsexpnorm:empty-depth-text-no-computed-depth() {
	count(
		tsexpnorm:normalize($tsexpnorm:empty-depth-text//t:objectDesc/node())//t:dimensions[@subtype = "computed"]/t:depth
	)
};

declare %test:assertEquals("22,0") function tsexpnorm:cataloguer-height-unchanged() {
	string(
		tsexpnorm:normalize($tsexpnorm:comma-cm//t:objectDesc/node())//t:dimensions[@type = "outer"][not(
			@subtype = "computed"
		)]/t:height
	)
};

declare %test:assertEquals("212.5") function tsexpnorm:leaf-range-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:leaf-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare %test:assertEquals("215") function tsexpnorm:leaf-range-atMost() {
	string(
		tsexpnorm:normalize($tsexpnorm:leaf-range//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@atMost
	)
};

declare %test:assertTrue function tsexpnorm:computed-dimensions-have-no-text() {
	empty(
		tsexpnorm:normalize($tsexpnorm:clean-mm//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]//text()[normalize-space(.) != ""]
	)
};

declare %test:assertTrue function tsexpnorm:computed-sibling-follows-cataloguer() {
	let $norm := tsexpnorm:normalize($tsexpnorm:clean-mm//t:objectDesc/node())
	let $extent := $norm//t:extent
	return local-name($extent/t:dimensions[1]) = "dimensions" and
		not($extent/t:dimensions[1]/@subtype = "computed") and
		$extent/t:dimensions[2]/@subtype = "computed"
};

declare variable $tsexpnorm:zero-bound := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer" unit="mm"><height atLeast="0" atMost="10">0-10</height></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("0") function tsexpnorm:zero-bound-atLeast() {
	string(
		tsexpnorm:normalize($tsexpnorm:zero-bound//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@atLeast
	)
};

declare %test:assertEquals("5") function tsexpnorm:zero-bound-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:zero-bound//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare variable $tsexpnorm:attrs-only := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer" unit="mm"><height atLeast="100" atMost="120" /></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("110") function tsexpnorm:attrs-only-quantity() {
	string(
		tsexpnorm:normalize($tsexpnorm:attrs-only//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};

declare variable $tsexpnorm:child-unit-cm := tsexpnorm:wrap(
	<supportDesc xmlns="http://www.tei-c.org/ns/1.0">
		<extent><dimensions type="outer"><height unit="cm">12</height></dimensions></extent>
	</supportDesc>
);

declare %test:assertEquals("120") function tsexpnorm:child-unit-cm-to-mm() {
	string(
		tsexpnorm:normalize($tsexpnorm:child-unit-cm//t:objectDesc/node())//t:dimensions[@subtype =
			"computed"]/t:height/@quantity
	)
};
