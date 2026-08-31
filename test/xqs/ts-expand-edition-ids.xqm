xquery version "3.1";

module namespace tsexpedids = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-edition-ids";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

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

declare %test:assertTrue function tsexpedids:edition-div-gets-xml-id() {
	count(expand:tei2fulltei($tsexpedids:tei, ())//t:div[@type = "edition"]/@xml:id) eq 1
};

declare %test:assertTrue function tsexpedids:subtype-textparts-not-minted() {
	count(expand:tei2fulltei($tsexpedids:tei, ())//t:div[@subtype]/@xml:id) eq 0
};

declare %test:assertTrue function tsexpedids:no-duplicate-xml-ids() {
	let $out := expand:tei2fulltei($tsexpedids:tei, ())
	return count(distinct-values($out//@xml:id)) eq count($out//@xml:id)
};

declare %test:assertTrue function tsexpedids:refsDecl-edition-citeStructure() {
	exists(expand:tei2fulltei($tsexpedids:tei, ())//t:refsDecl/t:citeStructure[@unit = "edition"][@use = "@xml:id"])
};

declare %test:assertTrue function tsexpedids:lit0428-no-duplicate-xml-ids() {
	let $out := expand:tei2fulltei($tsexpedids:tei-two, ())
	return count(distinct-values($out//@xml:id)) eq count($out//@xml:id)
};

declare %test:assertTrue function tsexpedids:nested-sections-get-unique-ids() {
	let $out := expand:tei2fulltei($tsexpedids:tei-nested, ())
	let $ids := $out//t:div[@type = "section"]/@xml:id
	return count($ids) eq 2 and count(distinct-values($ids)) eq 2
};
