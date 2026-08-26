xquery version "3.1";

module namespace tsexpandtit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-titles";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

(:~
 : Minimal TEI whose xml:id is not in BetMasData — expand must not emit HTML spans.
 :)
declare variable $tsexpandtit:tei := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	type="work"
	xml:id="LITTESTmissingTitle88"
>
	<teiHeader>
		<titleStmt><title xml:lang="en">seed</title></titleStmt>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text><body><div type="edition"><ab>x</ab></div></body></text>
</TEI>;

(:~
 : Unresolved main id → TEI seg with @corresp, not HTML span.
 :)
declare %test:assertEquals("seg") function tsexpandtit:printTitleMainID-is-tei-seg() {
	local-name(expand:printTitleMainID("LITTESTmissingTitle88"))
};

declare %test:assertEquals("LITTESTmissingTitle88") function tsexpandtit:printTitleMainID-corresp() {
	string(expand:printTitleMainID("LITTESTmissingTitle88")/@corresp)
};

declare %test:assertFalse function tsexpandtit:printTitleMainID-not-html-span() {
	let $out := expand:printTitleMainID("LITTESTmissingTitle88")
	return local-name($out) = "span" or contains(string($out/@class), "w3-tag")
};

(:~
 : titles:printTitleID HTML fallbacks (web module style) must convert to seg.
 :)
declare %test:assertEquals("seg") function tsexpandtit:asTeiTitle-converts-span() {
	let $span := <span class="w3-tag w3-red">No item: BrownEth14</span>
	return local-name(expand:asTeiTitle($span, "BrownEth14"))
};

declare %test:assertEquals("BrownEth14") function tsexpandtit:asTeiTitle-span-corresp() {
	string(expand:asTeiTitle(<span class="w3-tag w3-red">No item: BrownEth14</span>, "BrownEth14")/@corresp)
};

(:~
 : Expanded titleStmt/@type=full must carry seg, never span.
 :)
declare %test:assertEquals("seg") function tsexpandtit:titleStmt-full-is-seg() {
	let $out := expand:tei2fulltei($tsexpandtit:tei/t:teiHeader/t:titleStmt, ())
	return local-name($out/t:title[@type = "full"]/*[1])
};

declare %test:assertFalse function tsexpandtit:titleStmt-full-has-no-span() {
	let $out := expand:tei2fulltei($tsexpandtit:tei/t:teiHeader/t:titleStmt, ())
	return exists($out//*:span)
};
