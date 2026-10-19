xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for xslt/collationAlone.xsl's quire leaf counts.
 :
 : A quire's leaf count comes from t:dim[@unit='leaf']; when that is missing
 : or not numeric it can be derived from the quire's locus range. Diagrams
 : must only be withheld when neither gives a number, and must never fail
 : with "Cannot convert NaN to an integer".
 :
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/228
 :)
module namespace tscollation = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-collation-leafcount";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

declare variable $tscollation:xslt := doc("/db/apps/BetMasWeb/xslt/collationAlone.xsl");

(:~
 : One t:collation with a quire per entry of $quires, each a map with
 : optional "dim" (string) and "from"/"to" (locus).
 :)
declare %private function tscollation:fixture($quires as map(*)*) as element(t:collation) {
	let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="TScollationFixture">
		<teiHeader>
			<fileDesc>
				<sourceDesc>
					<msDesc>
						<physDesc>
							<objectDesc>
								<supportDesc>
									<collation>
										<list>
											{
												for $q at $i in $quires
												return <item n="{ $i }" xml:id="q{ $i }">
													{
														if (map:contains($q, "dim")) then
															<dim unit="leaf">{ $q?dim }</dim>
														else (
														),
														if (map:contains($q, "from")) then
															<locus from="{ $q?from }" to="{ $q?to }" />
														else (
														)
													}
												</item>
											}
										</list>
									</collation>
								</supportDesc>
							</objectDesc>
						</physDesc>
					</msDesc>
				</sourceDesc>
			</fileDesc>
		</teiHeader>
	</TEI>
	return $tei//t:collation
};

declare %private function tscollation:render($collation as element(t:collation)) as xs:string {
	serialize(transform:transform($collation, $tscollation:xslt, ()))
};

declare %private function tscollation:leaves($collation as element(t:collation), $quire as xs:string) as xs:string {
	let $html := transform:transform($collation, $tscollation:xslt, ())
	return normalize-space($html//*:td[@id = $quire]/following-sibling::*:td[2])
};

declare %private function tscollation:regular() as map(*)* {
	(map {"dim": "8", "from": "1r", "to": "8v"}, map {"dim": "8", "from": "9r", "to": "16v"})
};

declare %test:assertFalse function tscollation:numeric-dims-draw-diagrams() {
	contains(tscollation:render(tscollation:fixture(tscollation:regular())), "w3-amber")
};

(:~
 : ESmakm101's q14 shape: no leaf dim, locus 105r–112v.
 :)
declare %test:assertFalse function tscollation:missing-dim-with-locus-is-not-withheld() {
	contains(
		tscollation:render(tscollation:fixture((tscollation:regular(), map {"from": "17r", "to": "24v"}))),
		"w3-amber"
	)
};

declare %test:assertFalse function tscollation:missing-dim-with-locus-does-not-error() {
	contains(
		tscollation:render(tscollation:fixture((tscollation:regular(), map {"from": "17r", "to": "24v"}))),
		"Collation Processing Error"
	)
};

declare %test:assertEquals("8") function tscollation:missing-dim-leaf-count-from-locus() {
	tscollation:leaves(tscollation:fixture((tscollation:regular(), map {"from": "17r", "to": "24v"})), "q3")
};

declare %test:assertTrue function tscollation:unknown-dim-without-locus-is-withheld() {
	contains(tscollation:render(tscollation:fixture((tscollation:regular(), map {"dim": "unknown"}))), "w3-amber")
};

declare %test:assertTrue function tscollation:missing-dim-without-locus-is-withheld() {
	contains(tscollation:render(tscollation:fixture((tscollation:regular(), map {}))), "w3-amber")
};

declare %test:assertFalse function tscollation:withheld-message-does-not-blame-unknown-only() {
	contains(tscollation:render(tscollation:fixture((tscollation:regular(), map {}))), "non-numeric values (e.g.")
};

declare %test:assertFalse function tscollation:esmakm101-renders-without-error() {
	contains(
		serialize(transform:transform(collection("/db/apps/expanded")/id("ESmakm101")//t:collation, $tscollation:xslt, ())),
		"Collation Processing Error"
	)
};
