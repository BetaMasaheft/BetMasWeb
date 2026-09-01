xquery version "3.1";

module namespace tsvicomputed = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-computed";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare variable $tsvicomputed:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="manuscript" xml:id="MSviewTEST">
	<teiHeader>
		<fileDesc>
			<titleStmt><title>view computed skip</title></titleStmt>
			<publicationStmt><p /></publicationStmt>
		</fileDesc>
	</teiHeader>
	<text>
		<body>
			<msDesc xml:id="MSviewTEST">
				<physDesc>
					<objectDesc>
						<supportDesc>
							<extent>
								<dimensions type="outer" unit="cm"><height>22,0</height></dimensions>
								<dimensions subtype="computed" type="outer" unit="mm"><height quantity="220" unit="mm" /></dimensions>
							</extent>
						</supportDesc>
						<layoutDesc>
							<layout columns="2" writtenLines="17 18" />
							<layout columns="2" subtype="computed" type="catalogue"><writtenLines quantity="18" /></layout>
						</layoutDesc>
					</objectDesc>
				</physDesc>
			</msDesc>
		</body>
	</text>
</TEI>;

declare %private function tsvicomputed:extent-html() as node()* {
	viewItem:TEI2HTML($tsvicomputed:tei//t:extent)
};

declare %private function tsvicomputed:layoutDesc-html() as node()* {
	viewItem:TEI2HTML($tsvicomputed:tei//t:layoutDesc)
};

declare %test:assertEquals(1) function tsvicomputed:extent-dimension-heading-count() {
	count(tsvicomputed:extent-html()//*:h5[contains(., "Dimensions")])
};

declare %test:assertEquals("22,0") function tsvicomputed:extent-cataloguer-height() {
	string((tsvicomputed:extent-html()//*:span[@class = "lead"])[1])
};

declare %test:assertEquals(0) function tsvicomputed:extent-computed-quantity-attr-count() {
	count(tsvicomputed:extent-html()//@quantity)
};

declare %test:assertEquals(1) function tsvicomputed:layoutDesc-layout-note-count() {
	count(tsvicomputed:layoutDesc-html()//*:h4[starts-with(., "Layout note")])
};

declare %test:assertEquals("Layout note 1") function tsvicomputed:layoutDesc-first-layout-note() {
	string((tsvicomputed:layoutDesc-html()//*:h4[starts-with(., "Layout note")])[1])
};

declare %test:assertEquals("Number of lines: 17-18") function tsvicomputed:layoutDesc-cataloguer-lines() {
	string((tsvicomputed:layoutDesc-html()//*:p[starts-with(., "Number of lines:")])[1])
};
