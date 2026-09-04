xquery version "3.1";

(:~
 : citeStructure/@unit must be a single token (no whitespace) for expanded RNG.
 :)
module namespace tsexpcite = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-citeunit";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

declare
	%test:arg("raw", "page break")
	%test:assertEquals("page-break")
	%test:arg("raw", "title subscriptio translation")
	%test:assertEquals("title-subscriptio-translation")
	%test:arg("raw", "  folio  ")
	%test:assertEquals("folio")
	%test:arg("raw", "")
	%test:assertEquals("unit")
function tsexpcite:citeUnit-tokenises($raw as xs:string) {
	expand:citeUnit($raw)
};

(:~
 : Edition with pb/lb/cb and a multi-token subtype — units must stay token-safe.
 :)
declare variable $tsexpcite:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITciteunit88">
	<teiHeader>
		<titleStmt><title xml:lang="en">seed</title></titleStmt>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text>
		<body>
			<div type="edition">
				<div subtype="title subscriptio translation" type="textpart" xml:lang="gez">
					<ab><pb n="1" /><cb n="a" /><lb n="1" />
						text
					</ab>
				</div>
			</div>
		</body>
	</text>
</TEI>;

declare %test:assertEquals(0) function tsexpcite:no-whitespace-units() {
	count(expand:tei2fulltei($tsexpcite:tei, ())//t:citeStructure/@unit[contains(., " ")])
};

declare %test:assertEquals("title-subscriptio-translation") function tsexpcite:multi-subtype-unit() {
	string((expand:tei2fulltei($tsexpcite:tei, ())//t:citeStructure[@use = "@subtype"]/@unit)[1])
};

declare %test:assertEquals("pb") function tsexpcite:pb-unit() {
	string((expand:tei2fulltei($tsexpcite:tei, ())//t:citeStructure[@match = ("pb", "t:pb")]/@unit)[1])
};

declare %test:assertEquals("lb") function tsexpcite:lb-unit() {
	string((expand:tei2fulltei($tsexpcite:tei, ())//t:citeStructure[@match = ("lb", "t:lb")]/@unit)[1])
};

declare %test:assertEquals("cb") function tsexpcite:cb-unit() {
	string((expand:tei2fulltei($tsexpcite:tei, ())//t:citeStructure[@match = ("cb", "t:cb")]/@unit)[1])
};
