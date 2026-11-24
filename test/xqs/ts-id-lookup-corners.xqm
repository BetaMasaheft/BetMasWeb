xquery version "3.1" encoding "UTF-8";

(:~
 : Corner-case contract for id()-based TEI lookup (titles + dtsclient).
 : Fixtures prove behaviour vs //@xml:id scan:
 : - duplicate @xml:id TEIs → both returned (printTitle "More than 1")
 : - TEI + non-TEI share @xml:id → TEI still found ([self::t:TEI] filter)
 : - non-TEI only → empty (same as //t:TEI[@xml:id=…])
 :)
module namespace tsidcorners = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-id-lookup-corners";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xmldb = "http://exist-db.org/xquery/xmldb";

import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";
import module namespace dtsc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtsc" at "../../modules/dtsclient.xqm";

declare variable $tsidcorners:col := "/db/apps/BetMasWeb/test/_idLookupCorner";

declare %private function tsidcorners:col-nodes() as node()* {
	collection($tsidcorners:col)
};

declare %test:setUp function tsidcorners:setUp() {
	if (xmldb:collection-available($tsidcorners:col)) then
		xmldb:remove($tsidcorners:col)
	else (
	),
	xmldb:create-collection("/db/apps/BetMasWeb/test", "_idLookupCorner"),
	xmldb:store(
		$tsidcorners:col,
		"dup-a.xml",
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="CORNERdup1"><teiHeader /><text /></TEI>
	),
	xmldb:store(
		$tsidcorners:col,
		"dup-b.xml",
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="CORNERdup1"><teiHeader /><text /></TEI>
	),
	xmldb:store(
		$tsidcorners:col,
		"tei-ok.xml",
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="CORNERonlyTei"><teiHeader /><text /></TEI>
	),
	xmldb:store(
		$tsidcorners:col,
		"div-same-id.xml",
		<div xmlns="http://www.tei-c.org/ns/1.0" xml:id="CORNERonlyTei"><ab>not tei</ab></div>
	),
	xmldb:store(
		$tsidcorners:col,
		"div-only.xml",
		<div xmlns="http://www.tei-c.org/ns/1.0" xml:id="CORNERdivOnly"><ab>x</ab></div>
	)
};

declare %test:tearDown function tsidcorners:tearDown() {
	if (xmldb:collection-available($tsidcorners:col)) then
		xmldb:remove($tsidcorners:col)
	else (
	)
};

(: --- duplicates: id() must not collapse; printTitle keeps "More than 1" --- :)

declare
	%test:name("corner: duplicate xml:id — id() TEI count matches //@xml:id") %test:assertEquals(2, 2, 2, 2)
function tsidcorners:dup-counts() {
	let $c := tsidcorners:col-nodes()
	return (
		count($c//t:TEI[@xml:id = "CORNERdup1"]),
		count(($c/id("CORNERdup1"))[self::t:TEI]),
		count(titles:tei-by-main-id("CORNERdup1", $c)),
		count(dtsc:expanded-tei("CORNERdup1", $c))
	)
};

declare
	%test:name("corner: duplicate xml:id — printTitleMainID reports More than 1")
	%test:assertEquals("More than 1 CORNERdup1")
function tsidcorners:dup-printTitle() {
	titles:printTitleMainID("CORNERdup1", $tsidcorners:col)
};

(: --- mixed TEI + non-TEI same xml:id: must still return the TEI --- :)

declare
	%test:name("corner: mixed TEI+div same xml:id — bare id() sees both") %test:assertEquals(2)
function tsidcorners:mixed-bare-id-sees-both() {
	count(tsidcorners:col-nodes()/id("CORNERonlyTei"))
};

declare
	%test:name("corner: mixed TEI+div — helpers keep only TEI (xpath parity)") %test:assertEquals(1, 1, 1, "TEI", "TEI")
function tsidcorners:mixed-titles-filters-to-tei() {
	(: Without [self::t:TEI], id() returns TEI+div (count 2) and this fails. :)
	let $c := tsidcorners:col-nodes()
	let $via-xpath := $c//t:TEI[@xml:id = "CORNERonlyTei"]
	let $via-titles := titles:tei-by-main-id("CORNERonlyTei", $c)
	let $via-dtsc := dtsc:expanded-tei("CORNERonlyTei", $c)
	return (count($via-xpath), count($via-titles), count($via-dtsc), local-name($via-titles), local-name($via-dtsc))
};

(: --- non-TEI only: both paths miss for TEI lookup --- :)

declare
	%test:name("corner: div-only xml:id — TEI lookups empty (xpath and id)") %test:assertEquals(0, 0, 0)
function tsidcorners:div-only-misses-tei() {
	let $c := tsidcorners:col-nodes()
	return (
		count($c//t:TEI[@xml:id = "CORNERdivOnly"]),
		count(titles:tei-by-main-id("CORNERdivOnly", $c)),
		count(dtsc:expanded-tei("CORNERdivOnly", $c))
	)
};

declare
	%test:name("corner: div-only — bare id() still finds the div") %test:assertEquals(1, "div")
function tsidcorners:div-only-bare-id-finds-div() {
	let $n := tsidcorners:col-nodes()/id("CORNERdivOnly")
	return (count($n), local-name($n))
};
