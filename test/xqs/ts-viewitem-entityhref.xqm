xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for viewItem:entityHref and the item-page render paths that link
 : entity refs (persWithRole, the relations table, the persons-with-role
 : panel).
 :
 : Expanded data stores @ref/@active/@passive as canonical data URIs
 : ($config:BMurl || id). Emitted verbatim as href they send every click on
 : a dev or staging deployment to production.
 :
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/164
 :)
module namespace tsvientity = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-entityhref";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
(: item2 and apprest before viewItem: the three import each other in a cycle,
   and with viewItem loaded first every apprest call raises a
   NullPointerException under test:suite (eXist 6.4). :)
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "../../modules/item.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "../../modules/apprest.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare variable $tsvientity:person := "PRS15339GabraGiw";

declare %private function tsvientity:local() as xs:string {
	$config:appUrl || "/" || $tsvientity:person
};

declare %private function tsvientity:ms() as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="TSentityHrefFixture">
		<teiHeader>
			<fileDesc>
				<sourceDesc>
					<msDesc xml:id="ms">
						<history>
							<provenance><persName ref="{ $config:BMurl || $tsvientity:person }" role="owner" /></provenance>
						</history>
					</msDesc>
				</sourceDesc>
			</fileDesc>
		</teiHeader>
	</TEI>
};

declare %private function tsvientity:hrefs($html as node()*) as xs:string* {
	$html/descendant-or-self::*:a/@href!string()
};

declare %test:assertTrue function tsvientity:canonical-uri-maps-to-app() {
	viewItem:entityHref($config:BMurl || $tsvientity:person) eq tsvientity:local()
};

declare %test:assertTrue function tsvientity:bare-id-maps-to-app() {
	viewItem:entityHref($tsvientity:person) eq tsvientity:local()
};

declare %test:assertTrue function tsvientity:fragment-is-kept() {
	viewItem:entityHref($config:BMurl || "BNFet32#ms_i1") eq $config:appUrl || "/BNFet32#ms_i1"
};

declare %test:assertEquals("https://www.wikidata.org/entity/Q220") function tsvientity:external-uri-unchanged() {
	viewItem:entityHref("https://www.wikidata.org/entity/Q220")
};

declare %test:assertEquals("wd:Q220") function tsvientity:curie-unchanged() {
	viewItem:entityHref("wd:Q220")
};

(:~
 : Callers wrap href attribute value templates, which join a sequence with
 : spaces instead of failing on cardinality. Keep that contract.
 :)
declare %test:assertEquals("PRS1 PRS2") function tsvientity:sequence-joins-like-avt() {
	viewItem:entityHref((attribute ref { "PRS1" }, attribute ref { "PRS2" }))
};

declare %test:assertEmpty function tsvientity:empty-is-empty() {
	viewItem:entityHref(" ")
};

declare %test:assertTrue function tsvientity:perswithrole-links-app() {
	tsvientity:hrefs(viewItem:persWithRole(tsvientity:ms()//t:msDesc)) = tsvientity:local()
};

declare %test:assertTrue function tsvientity:relations-table-links-app() {
	tsvientity:hrefs(apprest:deciderelation(<id>{ $config:BMurl || $tsvientity:person }</id>)) = tsvientity:local()
};

(:~
 : The label is the entity title, not the (now local) URL.
 :)
declare %test:assertFalse function tsvientity:relations-table-label-is-not-url() {
	starts-with(normalize-space(apprest:deciderelation(<id>{ $config:BMurl || $tsvientity:person }</id>)//*:a), "http")
};

declare %test:assertFalse function tsvientity:role-panel-has-no-canonical-href() {
	tsvientity:hrefs(item2:RestPersRole(tsvientity:ms(), "manuscripts")) = $config:BMurl || $tsvientity:person
};

declare %test:assertTrue function tsvientity:role-panel-links-app() {
	tsvientity:hrefs(item2:RestPersRole(tsvientity:ms(), "manuscripts")) = tsvientity:local()
};
