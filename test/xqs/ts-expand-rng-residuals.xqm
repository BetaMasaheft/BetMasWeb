xquery version "3.1";

module namespace tsexpandrng = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-rng-residuals";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

(:~
 : Short fragment refs must keep a single leading "#".
 :)
declare %test:assertEquals("#p2") function tsexpandrng:reflike-keeps-hash-fragment() {
	string(expand:reflike(attribute corresp { "#p2" }))
};

declare %test:assertEquals("#ab") function tsexpandrng:reflike-keeps-two-char-fragment() {
	string(expand:reflike(attribute corresp { "#ab" }))
};

declare %test:assertEquals("#p2") function tsexpandrng:reflike-prefixes-bare-short() {
	string(expand:reflike(attribute corresp { "p2" }))
};

(:~
 : Unresolved repository @ref → plain text under repository (xtext), not seg.
 :)
declare %test:assertFalse function tsexpandrng:repository-no-item-is-not-seg() {
	let $repo := <repository xmlns="http://www.tei-c.org/ns/1.0" ref="INS0517BetaMasqalKebra" />
	let $out := expand:refel($repo, ())
	return exists($out/t:seg)
};

declare %test:assertTrue function tsexpandrng:repository-no-item-is-text() {
	let $repo := <repository xmlns="http://www.tei-c.org/ns/1.0" ref="INS0517BetaMasqalKebra" />
	let $out := expand:refel($repo, ())
	return contains(string($out), "No item:") and empty($out/t:seg)
};

(:~
 : Multiple profileDesc siblings get a single calendarDesc (no duplicate ids).
 :)
declare %test:assertEquals(1) function tsexpandrng:calendarDesc-once-per-tei() {
	let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITTESTdualProfile">
		<teiHeader>
			<titleStmt><title>seed</title></titleStmt>
			<profileDesc><abstract><p>a</p></abstract></profileDesc>
			<profileDesc><langUsage><language ident="en">English</language></langUsage></profileDesc>
		</teiHeader>
		<text><body><div><ab>x</ab></div></body></text>
	</TEI>
	let $out := expand:tei2fulltei($tei, ())
	return count($out//t:calendarDesc)
};

declare %test:assertEquals(1) function tsexpandrng:calendar-world-id-once() {
	let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITTESTdualProfile2">
		<teiHeader>
			<titleStmt><title>seed</title></titleStmt>
			<profileDesc><abstract><p>a</p></abstract></profileDesc>
			<profileDesc><langUsage><language ident="en">English</language></langUsage></profileDesc>
		</teiHeader>
		<text><body><div><ab>x</ab></div></body></text>
	</TEI>
	let $out := expand:tei2fulltei($tei, ())
	return count($out//t:calendar[@xml:id = "world"])
};
