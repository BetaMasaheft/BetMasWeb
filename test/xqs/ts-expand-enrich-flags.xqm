xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for expand enrich flags (BetMasWeb#312).
 : Defaults on preserve today's bake; options map can turn bibl/titles off.
 :
 : Prefer assertEmpty / assertExists / assertEquals / assertXPath on the
 : value under test so failures show expected vs $result (not opaque
 : assertTrue on a boolean computed inside the function).
 : @see https://exist-db.org/exist/apps/doc/xqsuite
 :)
module namespace tsexpenrich = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-enrich-flags";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";
import module namespace batchExpand = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/batchExpand" at "../../modules/batchExpand.xqm";

declare variable $tsexpenrich:src-col := "/db/apps/BetMasData/works/_enrichFlagsTest";

declare variable $tsexpenrich:out-col := "/db/apps/expanded/works/_enrichFlagsTest";

declare variable $tsexpenrich:id := "LITTESTenrichFlags77";

declare variable $tsexpenrich:bm-ptr := "bm:Heldman1993AfrZion";

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
				<bibl><ptr target="{ $tsexpenrich:bm-ptr }" /></bibl>
			</p>
		</sourceDesc>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text><body><div type="edition"><ab>x</ab></div></body></text>
</TEI>;

(:~
 : Minimal TEI for t:ref enrich-titles gates (authFile + empty @corresp).
 : Non-authFile @corresp fill requires @type (historical branch predicate).
 :)
declare variable $tsexpenrich:ref-tei := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	type="work"
	xml:id="LITTESTenrichFlagsRef"
>
	<teiHeader>
		<titleStmt><title xml:lang="en">ref enrich fixture</title></titleStmt>
		<publicationStmt><p>test</p></publicationStmt>
		<sourceDesc><p>seed</p></sourceDesc>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text>
		<body>
			<div type="edition">
				<ab xml:id="enrichFlagsRefAb">
					<ref type="authFile" corresp="PRS1111" />
					<ref type="internal" corresp="#missingAnchor" />
				</ab>
			</div>
		</body>
	</text>
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

declare %private function tsexpenrich:heldman-bibl($doc as node()) as element(t:bibl)? {
	$doc//t:bibl[t:ptr/@target = $tsexpenrich:bm-ptr][1]
};

declare %private function tsexpenrich:ref-ab($doc as node()) as element(t:ab)? {
	$doc//t:ab[@xml:id = "enrichFlagsRefAb"][1]
};

declare
	%test:name("default enrich-bibl is on")
	%test:assertTrue
function tsexpenrich:default-enrich-bibl-on() {
	expand:enrich-bibl()
};

declare
	%test:name("default enrich-titles is on")
	%test:assertTrue
function tsexpenrich:default-enrich-titles-on() {
	expand:enrich-titles()
};

declare
	%test:name("default expand:file embeds biblStruct title for bm: ptr")
	%test:assertXPath("exists($result/ptr[@target = 'bm:Heldman1993AfrZion'])")
	%test:assertXPath("exists($result/title)")
function tsexpenrich:bibl-on-embeds-struct() {
	tsexpenrich:heldman-bibl(expand:file(tsexpenrich:path()))
};

declare
	%test:name("enrich-bibl false keeps ptr only (no embedded bibl children)")
	%test:assertXPath("exists($result/ptr[@target = 'bm:Heldman1993AfrZion'])")
	%test:assertXPath(
		"empty($result/(title | author | editor | pubPlace | publisher | date | series | biblScope | note))"
	)
function tsexpenrich:bibl-off-keeps-ptr-only() {
	tsexpenrich:heldman-bibl(expand:file(tsexpenrich:path(), map { "enrich-bibl": false() }))
};

declare
	%test:name("enrich-titles false leaves empty @ref persName without text")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) = ''")
function tsexpenrich:titles-off-leaves-empty-ref() {
	expand:tei2fulltei($tsexpenrich:tei, (), map { "enrich-titles": false() })
		//t:persName[@ref][1]
};

declare
	%test:name("enrich-titles false omits title[@type=full]")
	%test:assertEmpty
function tsexpenrich:titles-off-omits-full-title() {
	expand:tei2fulltei(
		$tsexpenrich:tei/t:teiHeader/t:titleStmt,
		(),
		map { "enrich-titles": false() }
	)/t:title[@type = "full"]
};

declare
	%test:name("enrich-titles true keeps title[@type=full]")
	%test:assertExists
function tsexpenrich:titles-on-keeps-full-title() {
	expand:tei2fulltei(
		$tsexpenrich:tei/t:teiHeader/t:titleStmt,
		(),
		map { "enrich-titles": true() }
	)/t:title[@type = "full"]
};

declare
	%test:name("enrich-titles false leaves authFile ref text empty")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) = ''")
function tsexpenrich:titles-off-leaves-authFile-empty() {
	tsexpenrich:ref-ab(
		expand:tei2fulltei($tsexpenrich:ref-tei, (), map { "enrich-titles": false() })
	)/t:ref[@type = "authFile"][1]
};

declare
	%test:name("enrich-titles false leaves typed @corresp ref text empty")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) = ''")
function tsexpenrich:titles-off-leaves-corresp-ref-empty() {
	tsexpenrich:ref-ab(
		expand:tei2fulltei($tsexpenrich:ref-tei, (), map { "enrich-titles": false() })
	)/t:ref[not(@type = "authFile")][1]
};

declare
	%test:name("enrich-titles true fills authFile ref text")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) != ''")
function tsexpenrich:titles-on-fills-authFile() {
	tsexpenrich:ref-ab(
		expand:tei2fulltei($tsexpenrich:ref-tei, (), map { "enrich-titles": true() })
	)/t:ref[@type = "authFile"][1]
};

declare
	%test:name("enrich-titles true fills typed @corresp ref text")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) != ''")
function tsexpenrich:titles-on-fills-corresp-ref() {
	tsexpenrich:ref-ab(
		expand:tei2fulltei($tsexpenrich:ref-tei, (), map { "enrich-titles": true() })
	)/t:ref[not(@type = "authFile")][1]
};

declare
	%test:name("enrich-opts absent → empty map (module defaults)")
	%test:assertEmpty
function tsexpenrich:enrich-opts-absent-empty() {
	map:keys(batchExpand:enrich-opts(()))
};

declare
	%test:name("enrich-opts bibl → enrich-bibl true, enrich-titles false")
	%test:assertEquals("true", "false")
function tsexpenrich:enrich-opts-bibl-only() {
	let $o := batchExpand:enrich-opts("bibl")
	return (string(map:get($o, "enrich-bibl")), string(map:get($o, "enrich-titles")))
};

declare
	%test:name("enrich-opts empty allowlist → both false")
	%test:assertEquals("false", "false")
function tsexpenrich:enrich-opts-empty-allowlist-both-off() {
	let $o := batchExpand:enrich-opts("")
	return (string(map:get($o, "enrich-bibl")), string(map:get($o, "enrich-titles")))
};

declare
	%test:name("batchExpand enrich-bibl false stores ptr-only bibl")
	%test:assertXPath("exists($result/ptr[@target = 'bm:Heldman1993AfrZion'])")
	%test:assertXPath(
		"empty($result/(title | author | editor | pubPlace | publisher | date | series | biblScope | note))"
	)
function tsexpenrich:batch-bibl-off-stores-ptr-only() {
	let $_src := tsexpenrich:ensure-src()
	let $_ := batchExpand:expandCollection($tsexpenrich:src-col, map { "enrich-bibl": false() })
	return tsexpenrich:heldman-bibl(doc($tsexpenrich:out-col || "/" || $tsexpenrich:id || ".xml"))
};
