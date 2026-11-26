xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for expand enrich flags (BetMasWeb#312).
 : Default: enrich-bibl off, enrich-titles on. Options map / ?enrich= can
 : turn bibl on or titles off.
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
declare variable $tsexpenrich:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="{ $tsexpenrich:id }">
	<teiHeader>
		<titleStmt><title xml:lang="en">enrich flags fixture</title><editor key="xyz" role="generalEditor" /></titleStmt>
		<publicationStmt><p>test</p></publicationStmt>
		<sourceDesc><p><persName ref="PRS1111" /><bibl><ptr target="{ $tsexpenrich:bm-ptr }" /></bibl></p></sourceDesc>
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
					<ref corresp="PRS1111" type="authFile" />
					<ref corresp="#missingAnchor" type="internal" />
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

declare %test:name("default enrich-bibl is off") %test:assertFalse function tsexpenrich:default-enrich-bibl-off() {
	expand:enrich-bibl()
};

declare %test:name("default enrich-titles is on") %test:assertTrue function tsexpenrich:default-enrich-titles-on() {
	expand:enrich-titles()
};

declare
	%test:name("default expand:file keeps ptr only (no embedded bibl children)")
	%test:assertXPath("exists($result/ptr[@target = 'bm:Heldman1993AfrZion'])")
	%test:assertXPath(
		"empty($result/(title | author | editor | pubPlace | publisher | date | series | biblScope | note))"
	)
function tsexpenrich:default-bibl-off-keeps-ptr-only() {
	tsexpenrich:heldman-bibl(expand:file(tsexpenrich:path()))
};

declare
	%test:name("enrich-bibl true embeds biblStruct title for bm: ptr")
	%test:assertXPath("exists($result/ptr[@target = 'bm:Heldman1993AfrZion'])")
	%test:assertXPath("exists($result/title)")
function tsexpenrich:bibl-on-embeds-struct() {
	tsexpenrich:heldman-bibl(expand:file(tsexpenrich:path(), map {"enrich-bibl": true()}))
};

declare
	%test:name("enrich-bibl false keeps ptr only (no embedded bibl children)")
	%test:assertXPath("exists($result/ptr[@target = 'bm:Heldman1993AfrZion'])")
	%test:assertXPath(
		"empty($result/(title | author | editor | pubPlace | publisher | date | series | biblScope | note))"
	)
function tsexpenrich:bibl-off-keeps-ptr-only() {
	tsexpenrich:heldman-bibl(expand:file(tsexpenrich:path(), map {"enrich-bibl": false()}))
};

declare
	%test:name("enrich-titles false leaves empty @ref persName without text")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) = ''")
function tsexpenrich:titles-off-leaves-empty-ref() {
	expand:tei2fulltei($tsexpenrich:tei, (), map {"enrich-titles": false()})//t:persName[@ref][1]
};

(:~
 : Contract: titles off omits title[@type=full] (no empty placeholder element).
 :)
declare
	%test:name("enrich-titles false omits title[@type=full] (not empty element)") %test:assertEmpty
function tsexpenrich:titles-off-omits-full-title() {
	expand:tei2fulltei($tsexpenrich:tei/t:teiHeader/t:titleStmt, (), map {"enrich-titles": false()})/t:title[@type =
		"full"]
};

declare
	%test:name("enrich-titles true keeps title[@type=full]") %test:assertExists
function tsexpenrich:titles-on-keeps-full-title() {
	expand:tei2fulltei($tsexpenrich:tei/t:teiHeader/t:titleStmt, (), map {"enrich-titles": true()})/t:title[@type =
		"full"]
};

declare
	%test:name("enrich-titles false leaves authFile ref text empty")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) = ''")
function tsexpenrich:titles-off-leaves-authFile-empty() {
	tsexpenrich:ref-ab(expand:tei2fulltei($tsexpenrich:ref-tei, (), map {"enrich-titles": false()}))/t:ref[@type =
		"authFile"][1]
};

declare
	%test:name("enrich-titles false leaves typed @corresp ref text empty")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) = ''")
function tsexpenrich:titles-off-leaves-corresp-ref-empty() {
	tsexpenrich:ref-ab(expand:tei2fulltei($tsexpenrich:ref-tei, (), map {"enrich-titles": false()}))/t:ref[not(
		@type = "authFile"
	)][1]
};

declare
	%test:name("enrich-titles true fills authFile ref text")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) != ''")
function tsexpenrich:titles-on-fills-authFile() {
	tsexpenrich:ref-ab(expand:tei2fulltei($tsexpenrich:ref-tei, (), map {"enrich-titles": true()}))/t:ref[@type =
		"authFile"][1]
};

declare
	%test:name("enrich-titles true fills typed @corresp ref text")
	%test:assertExists
	%test:assertXPath("normalize-space(string($result)) != ''")
function tsexpenrich:titles-on-fills-corresp-ref() {
	tsexpenrich:ref-ab(expand:tei2fulltei($tsexpenrich:ref-tei, (), map {"enrich-titles": true()}))/t:ref[not(
		@type = "authFile"
	)][1]
};

declare
	%test:name("enrich-opts absent → empty map (module defaults)") %test:assertEmpty
function tsexpenrich:enrich-opts-absent-empty() {
	map:keys(batchExpand:enrich-opts(()))
};

declare
	%test:name("enrich-opts bibl → enrich-bibl true, enrich-titles false") %test:assertEquals("true", "false")
function tsexpenrich:enrich-opts-bibl-only() {
	let $o := batchExpand:enrich-opts("bibl")
	return (string(map:get($o, "enrich-bibl")), string(map:get($o, "enrich-titles")))
};

declare
	%test:name("enrich-opts empty allowlist → both false") %test:assertEquals("false", "false")
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
	let $_ := batchExpand:expandCollection($tsexpenrich:src-col, map {"enrich-bibl": false()})
	return tsexpenrich:heldman-bibl(doc($tsexpenrich:out-col || "/" || $tsexpenrich:id || ".xml"))
};

(:~
 : Task 2 CI shape: ?enrich=titles → bibl off, titles on.
 :)
declare
	%test:name("enrich-opts titles → enrich-bibl false, enrich-titles true") %test:assertEquals("false", "true")
function tsexpenrich:enrich-opts-titles-only() {
	let $o := batchExpand:enrich-opts("titles")
	return (string(map:get($o, "enrich-bibl")), string(map:get($o, "enrich-titles")))
};

declare
	%test:name("batchExpand ?enrich=titles stores ptr-only bibl")
	%test:assertXPath("exists($result/ptr[@target = 'bm:Heldman1993AfrZion'])")
	%test:assertXPath(
		"empty($result/(title | author | editor | pubPlace | publisher | date | series | biblScope | note))"
	)
function tsexpenrich:batch-enrich-titles-allowlist-bibl-off() {
	let $_src := tsexpenrich:ensure-src()
	let $_ := batchExpand:expandCollection($tsexpenrich:src-col, batchExpand:enrich-opts("titles"))
	return tsexpenrich:heldman-bibl(doc($tsexpenrich:out-col || "/" || $tsexpenrich:id || ".xml"))
};

declare
	%test:name("citation-by-tag hits EthioStudies citations.xml") %test:assertExists
function tsexpenrich:citation-by-tag-hit() {
	expand:citation-by-tag($tsexpenrich:bm-ptr)
};

declare
	%test:name("biblStruct-by-bm uses single head() hit") %test:assertExists
function tsexpenrich:biblStruct-by-bm-hit() {
	expand:biblStruct-by-bm($tsexpenrich:bm-ptr)
};

(:~
 : Requires EthioStudies package collection.xconf with range create @tag
 : (bibliography repo; pre-install → /db/system/config). Without that index,
 : citation-by-tag still hits via scan but system:trace shows no new-range Full.
 :)
declare
	%test:name("citation-by-tag uses new-range Full (optimization=2)") %test:assertXPath("xs:integer($result) ge 1")
function tsexpenrich:citation-by-tag-new-range-full() {
	let $_ := try { system:clear-trace() } catch * { () }
	let $_en := try { system:enable-tracing(true()) } catch * { () }
	let $cit := expand:citation-by-tag($tsexpenrich:bm-ptr)
	let $tr := try { system:trace() } catch * { () }
	let $_off := try { system:enable-tracing(false()) } catch * { () }
	return if (empty($cit)) then
		0
	else
		count($tr//*:index[@type = "new-range"][@optimization = "2"])
};

declare
	%test:name("with-enrich-defaults materializes both enrich booleans") %test:assertEquals("false", "false")
function tsexpenrich:with-enrich-defaults-overrides() {
	(: titles override only; bibl stays at module default (off). :)
	let $o := expand:with-enrich-defaults(map {"enrich-titles": false()})
	return (string(map:get($o, "enrich-bibl")), string(map:get($o, "enrich-titles")))
};

declare variable $tsexpenrich:ag00001 := "/db/apps/BetMasData/manuscripts/AbbaGarima/AG00001.xml";

(:~
 : AG00001-class assemble-only smoke (flags off). Loose ceiling — guards
 : against regressing back to multi-second enrich on this path.
 :)
declare
	%test:name("AG00001 enrich both-off under 2000ms") %test:assertXPath("xs:double($result) lt 2000")
function tsexpenrich:ag00001-both-off-fast() {
	if (not(doc-available($tsexpenrich:ag00001))) then
		0
	else
		let $t0 := util:system-time()
		let $_ := expand:file($tsexpenrich:ag00001, map {"enrich-bibl": false(), "enrich-titles": false()})
		return ((util:system-time() - $t0) div xs:dayTimeDuration("PT1S")) * 1000
};
