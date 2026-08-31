xquery version "3.1";

module namespace tsexpedids = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-edition-ids";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

(:~
 : Return comma-separated @xml:id values that appear more than once.
 :)
declare function tsexpedids:duplicate-ids($root as node()) as xs:string {
	let $ids := $root//@xml:id
	return string-join(
		for $id in distinct-values($ids)
		where count($ids[. = $id]) gt 1
		return string($id),
		", "
	)
};

(:~
 : Edition with three subtype textparts and no @xml:id — mirrors LIT0183EtanaMogar.
 :)
declare variable $tsexpedids:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LIT0183EtanaMogar">
	<teiHeader>
		<titleStmt><title xml:lang="en">seed</title></titleStmt>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text>
		<body>
			<div type="edition">
				<div subtype="inscriptio" type="textpart" xml:lang="gez"><ab>a</ab></div>
				<div subtype="incipit" type="textpart" xml:lang="gez"><ab>b</ab></div>
				<div subtype="explicit" type="textpart" xml:lang="gez"><ab>c</ab></div>
			</div>
		</body>
	</text>
</TEI>;

(:~
 : Two subtype textparts — mirrors LIT0428Malke.
 :)
declare variable $tsexpedids:tei-two := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LIT0428Malke">
	<teiHeader>
		<titleStmt><title xml:lang="en">seed</title></titleStmt>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text>
		<body>
			<div type="edition">
				<div subtype="incipit" type="textpart" xml:lang="gez"><ab>b</ab></div>
				<div subtype="explicit" type="textpart" xml:lang="gez"><ab>c</ab></div>
			</div>
		</body>
	</text>
</TEI>;

(:~
 : Nested div without @n/@subtype still needs a unique minted id.
 :)
declare variable $tsexpedids:tei-nested := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	type="work"
	xml:id="LITTESTnested88"
>
	<teiHeader>
		<titleStmt><title xml:lang="en">seed</title></titleStmt>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text>
		<body><div type="edition"><div type="section"><ab>x</ab></div><div type="section"><ab>y</ab></div></div></body>
	</text>
</TEI>;

declare %test:assertEquals(1) function tsexpedids:edition-div-xml-id-count() {
	count(expand:tei2fulltei($tsexpedids:tei, ())//t:div[@type = "edition"]/@xml:id)
};

declare %test:assertEquals(0) function tsexpedids:subtype-textpart-xml-id-count() {
	count(expand:tei2fulltei($tsexpedids:tei, ())//t:div[@subtype]/@xml:id)
};

declare %test:assertEquals("") function tsexpedids:lit0183-no-duplicate-xml-ids() {
	tsexpedids:duplicate-ids(expand:tei2fulltei($tsexpedids:tei, ()))
};

declare %test:assertEquals("@xml:id") function tsexpedids:refsDecl-edition-citeStructure-use() {
	string(expand:tei2fulltei($tsexpedids:tei, ())//t:refsDecl/t:citeStructure[@unit = "edition"]/@use)
};

declare %test:assertEquals("edition") function tsexpedids:refsDecl-edition-citeStructure-unit() {
	string(expand:tei2fulltei($tsexpedids:tei, ())//t:refsDecl/t:citeStructure[@use = "@xml:id"]/@unit)
};

declare %test:assertEquals("") function tsexpedids:lit0428-no-duplicate-xml-ids() {
	tsexpedids:duplicate-ids(expand:tei2fulltei($tsexpedids:tei-two, ()))
};

declare %test:assertEquals(2) function tsexpedids:nested-section-xml-id-count() {
	count(expand:tei2fulltei($tsexpedids:tei-nested, ())//t:div[@type = "section"]/@xml:id)
};

declare %test:assertEquals("") function tsexpedids:nested-sections-no-duplicate-xml-ids() {
	tsexpedids:duplicate-ids(expand:tei2fulltei($tsexpedids:tei-nested, ())//t:div[@type = "section"])
};
