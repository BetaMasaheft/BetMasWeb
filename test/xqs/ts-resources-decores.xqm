xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for lists:decoRes (modules/resources.xqm) - /decorations results.
 : Pins the BetMasWeb#156 regression where an XQuery-looking comment left
 : in direct element content serialized as visible text on every
 : manuscript accordion button.
 :)
module namespace tsdecores = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-resources-decores";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "../../modules/resources.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

declare variable $tsdecores:real-id := "AT1002Annunciation";

(:~
 : One miniature decoNote with an authFile ref and a shelfmark idno.
 :)
declare %private function tsdecores:mss-fixture($msid as xs:string) as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="{ $msid }">
		<teiHeader>
			<fileDesc>
				<sourceDesc>
					<msDesc>
						<msIdentifier><idno>{ $msid }-shelfmark</idno></msIdentifier>
						<decoDesc>
							<decoNote type="miniature" xml:id="{ $msid }d1">
								<ref corresp="{ $config:BMurl }{ $tsdecores:real-id }" type="authFile" />
							</decoNote>
						</decoDesc>
					</msDesc>
				</sourceDesc>
			</fileDesc>
		</teiHeader>
	</TEI>
};

declare %private function tsdecores:render($msid as xs:string) as xs:string {
	let $fixture := tsdecores:mss-fixture($msid)
	let $result := lists:decoRes(<a />, map {"hits": $fixture//t:decoNote}, 1, 20)
	return string-join(
		for $x in $result
		return serialize($x)
	)
};

(:~
 : Manuscript buttons must show the shelfmark, not the root()-vs-id()
 : rationale that was mistakenly left in element content.
 :)
declare %test:assertTrue function tsdecores:manuscript-button-omits-inline-xquery-comment() {
	let $html := tsdecores:render("MSTESTdecoresComment77")
	return contains($html, "MSTESTdecoresComment77-shelfmark") and
		not(contains($html, "collection-wide id()")) and
		not(contains($html, "(: $d[1]"))
};
