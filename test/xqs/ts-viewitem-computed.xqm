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
							<layout columns="2" subtype="computed" type="catalogue" writtenLines="18" />
						</layoutDesc>
					</objectDesc>
				</physDesc>
			</msDesc>
		</body>
	</text>
</TEI>;

declare %private function tsvicomputed:render-extent() as xs:string {
	serialize(viewItem:TEI2HTML($tsvicomputed:tei//t:extent))
};

declare %private function tsvicomputed:render-layoutDesc() as xs:string {
	serialize(viewItem:TEI2HTML($tsvicomputed:tei//t:layoutDesc))
};

declare %test:assertTrue function tsvicomputed:extent-shows-cataloguer-height() {
	contains(tsvicomputed:render-extent(), "22,0")
};

declare %test:assertTrue function tsvicomputed:extent-hides-computed-quantity() {
	not(contains(tsvicomputed:render-extent(), "quantity=&quot;220&quot;"))
};

declare %test:assertTrue function tsvicomputed:layoutDesc-one-layout-note() {
	contains(tsvicomputed:render-layoutDesc(), "Layout note 1") and
		not(contains(tsvicomputed:render-layoutDesc(), "Layout note 2"))
};

declare %test:assertTrue function tsvicomputed:layoutDesc-shows-cataloguer-lines() {
	contains(tsvicomputed:render-layoutDesc(), "17-18")
};
