xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for expand enrich flags (BetMasWeb#312).
 : Defaults on preserve today's bake; options map can turn bibl/titles off.
 :)
module namespace tsexpenrich = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-enrich-flags";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

declare variable $tsexpenrich:src-col := "/db/apps/BetMasData/works/_enrichFlagsTest";

declare variable $tsexpenrich:id := "LITTESTenrichFlags77";

(:~
 : Fixture with a bm: bibl ptr and an empty @ref persName.
 :)
declare variable $tsexpenrich:tei := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	type="work"
	xml:id="{ $tsexpenrich:id }"
>
	<teiHeader>
		<titleStmt>
			<title xml:lang="en">enrich flags fixture</title>
			<editor key="xyz" role="generalEditor" />
		</titleStmt>
		<publicationStmt><p>test</p></publicationStmt>
		<sourceDesc>
			<p>
				<persName ref="PRS1111" />
				<bibl><ptr target="bm:Heldman1993AfrZion" /></bibl>
			</p>
		</sourceDesc>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text><body><div type="edition"><ab>x</ab></div></body></text>
</TEI>;

declare %private function tsexpenrich:ensure-src() {
	if (not(xmldb:collection-available("/db/apps/BetMasData/works"))) then
		xmldb:create-collection("/db/apps/BetMasData", "works")
	else (
	),
	if (xmldb:collection-available($tsexpenrich:src-col)) then (
	) else
		xmldb:create-collection("/db/apps/BetMasData/works", "_enrichFlagsTest"),
	xmldb:store($tsexpenrich:src-col, $tsexpenrich:id || ".xml", $tsexpenrich:tei)
};

declare %private function tsexpenrich:path() as xs:string {
	let $_ := tsexpenrich:ensure-src()
	return $tsexpenrich:src-col || "/" || $tsexpenrich:id || ".xml"
};

(:~ Defaults match today's bake-on behaviour. :)
declare %test:assertTrue function tsexpenrich:default-enrich-bibl-on() {
	expand:enrich-bibl()
};

declare %test:assertTrue function tsexpenrich:default-enrich-titles-on() {
	expand:enrich-titles()
};

(:~ Default expand:file still embeds EthioStudies/Zotero bibl children. :)
declare %test:assertTrue function tsexpenrich:bibl-on-embeds-struct() {
	let $doc := expand:file(tsexpenrich:path())
	let $bibl := $doc//t:bibl[t:ptr/@target = "bm:Heldman1993AfrZion"][1]
	return exists($bibl/t:ptr) and exists($bibl/t:title)
};

(:~
 : Options override: enrich-bibl false → no embedded bibl children beyond the ptr.
 :)
declare %test:assertTrue function tsexpenrich:bibl-off-keeps-ptr-only() {
	let $doc := expand:file(tsexpenrich:path(), map { "enrich-bibl": false() })
	let $bibl := $doc//t:bibl[t:ptr/@target = "bm:Heldman1993AfrZion"][1]
	return exists($bibl/t:ptr) and empty($bibl/(t:title | t:author | t:editor | t:pubPlace | t:publisher | t:date | t:series | t:biblScope | t:note))
};

(:~
 : Options override: enrich-titles false → empty @ref stays empty; no title[@type=full].
 :)
declare %test:assertTrue function tsexpenrich:titles-off-leaves-empty-ref() {
	let $out := expand:tei2fulltei(
		$tsexpenrich:tei,
		(),
		map { "enrich-titles": false() }
	)
	let $pers := $out//t:persName[@ref][1]
	return exists($pers) and not($pers/node()[normalize-space(.) ne ""])
};

declare %test:assertTrue function tsexpenrich:titles-off-omits-full-title() {
	let $out := expand:tei2fulltei(
		$tsexpenrich:tei/t:teiHeader/t:titleStmt,
		(),
		map { "enrich-titles": false() }
	)
	return empty($out/t:title[@type = "full"])
};

(:~ Flags on (explicit) still injects title[@type=full]. :)
declare %test:assertTrue function tsexpenrich:titles-on-keeps-full-title() {
	let $out := expand:tei2fulltei(
		$tsexpenrich:tei/t:teiHeader/t:titleStmt,
		(),
		map { "enrich-titles": true() }
	)
	return exists($out/t:title[@type = "full"])
};
