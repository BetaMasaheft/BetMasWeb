xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for dtslib:PrevNextRef with nested citeStructure items that
 : repeat values across levels (BetMasWeb#93).
 :)
module namespace tsdtsprev = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-dtslib-prevnext";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace dtslib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib" at "../../modules/dtslib.xqm";

(:~
 : Minimal TEI: chapter items 1|2 and verse items 1|2 (duplicates across levels).
 : Content model: nested citeStructure then desc (TEI sequence).
 :)
declare variable $tsdtsprev:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="LITTESTdupItems">
	<teiHeader>
		<encodingDesc>
			<refsDecl>
				<citeStructure delim="." match="//div[@type='edition']" unit="edition" use="@xml:id">
					<citeStructure match="div" unit="chapter" use="@n">
						<citeStructure match="div" unit="verse" use="@n">
							<desc><list><item>1</item><item>2</item></list></desc>
						</citeStructure>
						<desc><list><item>1</item><item>2</item></list></desc>
					</citeStructure>
				</citeStructure>
			</refsDecl>
		</encodingDesc>
	</teiHeader>
	<text>
		<body>
			<div type="edition">
				<div n="1" subtype="chapter" type="textpart">
					<div n="1" subtype="verse" type="textpart"><ab>a</ab></div>
					<div n="2" subtype="verse" type="textpart"><ab>b</ab></div>
				</div>
				<div n="2" subtype="chapter" type="textpart">
					<div n="1" subtype="verse" type="textpart"><ab>c</ab></div>
					<div n="2" subtype="verse" type="textpart"><ab>d</ab></div>
				</div>
			</div>
		</body>
	</text>
</TEI>;

declare variable $tsdtsprev:edition := $tsdtsprev:tei//t:div[@type = "edition"];

(:~
 : next from chapter "1" must be a single string "2" (not XPTY0004 from duplicate index-of).
 :)
declare %test:assertEquals("2") function tsdtsprev:next-from-1-is-2() {
	dtslib:PrevNextRef($tsdtsprev:edition, "1", "next")
};

(:~
 : prev from chapter "2" must be a single string "1".
 :)
declare %test:assertEquals("1") function tsdtsprev:prev-from-2-is-1() {
	dtslib:PrevNextRef($tsdtsprev:edition, "2", "prev")
};

(:~
 : next past the last chapter yields empty (not an error).
 :)
declare %test:assertEmpty function tsdtsprev:next-from-last-is-empty() {
	dtslib:PrevNextRef($tsdtsprev:edition, "2", "next")
};
