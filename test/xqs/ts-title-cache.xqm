xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for the shared works/persons/places/institutions title cache:
 : titles:updateTitleCache (write side), exptit:printTitleID's cache-first
 : fast path (read side), and expand:file's cache-writing side effect.
 :)
module namespace tstitlecache = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-title-cache";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "../../modules/exptit.xqm";
import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

declare variable $tstitlecache:cache-path := "/db/apps/lists/titleCache.xml";

declare variable $tstitlecache:write-id := "LITTESTtitleCacheWrite77";

declare variable $tstitlecache:hit-id := "LITTESTtitleCacheHit77";

declare variable $tstitlecache:hit-title := "a distinctive cached title no fallback path could produce";

declare variable $tstitlecache:src-col := "/db/apps/BetMasData/works/_titleCacheTest";

declare variable $tstitlecache:expand-id := "LITTESTtitleCacheExpand77";

declare variable $tstitlecache:tei := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	type="work"
	xml:id="{ $tstitlecache:expand-id }"
>
	<teiHeader>
		<titleStmt><title xml:lang="en">title cache expand fixture</title></titleStmt>
		<publicationStmt><p>test</p></publicationStmt>
		<sourceDesc><p>test</p></sourceDesc>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text><body><div type="edition"><ab>x</ab></div></body></text>
</TEI>;

declare variable $tstitlecache:backfill-col := "/db/apps/expanded/works/_titleCacheBackfillTest";

declare variable $tstitlecache:backfill-id := "LITTESTtitleCacheBackfill77";

declare variable $tstitlecache:backfill-title := "backfill fixture title";

declare variable $tstitlecache:backfill-tei := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	xml:id="{ $tstitlecache:backfill-id }"
>
	<teiHeader><titleStmt><title type="full">{ $tstitlecache:backfill-title }</title></titleStmt></teiHeader>
	<text><body><div type="edition"><ab>x</ab></div></body></text>
</TEI>;

declare %private function tstitlecache:remove-entry($id as xs:string) {
	if (doc-available($tstitlecache:cache-path)) then
		let $existing := doc($tstitlecache:cache-path)//t:item[@corresp eq $id]
		return if ($existing) then
			update delete $existing
		else (
		)
	else (
	)
};

declare %private function tstitlecache:ensure-src() {
	if (not(xmldb:collection-available("/db/apps/BetMasData/works"))) then
		xmldb:create-collection("/db/apps/BetMasData", "works")
	else (
	),
	if (xmldb:collection-available($tstitlecache:src-col)) then (
	) else
		xmldb:create-collection("/db/apps/BetMasData/works", "_titleCacheTest"),
	xmldb:store($tstitlecache:src-col, $tstitlecache:expand-id || ".xml", $tstitlecache:tei),
	if (not(xmldb:collection-available("/db/apps/expanded/works"))) then
		xmldb:create-collection("/db/apps/expanded", "works")
	else (
	),
	if (xmldb:collection-available($tstitlecache:backfill-col)) then (
	) else
		xmldb:create-collection("/db/apps/expanded/works", "_titleCacheBackfillTest"),
	xmldb:store($tstitlecache:backfill-col, $tstitlecache:backfill-id || ".xml", $tstitlecache:backfill-tei)
};

declare %private function tstitlecache:cleanup() {
	tstitlecache:remove-entry($tstitlecache:write-id),
	tstitlecache:remove-entry($tstitlecache:hit-id),
	tstitlecache:remove-entry($tstitlecache:expand-id),
	tstitlecache:remove-entry($tstitlecache:backfill-id),
	if (xmldb:collection-available($tstitlecache:src-col)) then
		try { xmldb:remove($tstitlecache:src-col) } catch * { () }
	else (
	),
	if (xmldb:collection-available($tstitlecache:backfill-col)) then
		try { xmldb:remove($tstitlecache:backfill-col) } catch * { () }
	else (
	)
};

declare %test:setUp function tstitlecache:setUp() {
	tstitlecache:cleanup(), tstitlecache:ensure-src()
};

declare %test:tearDown function tstitlecache:tearDown() {
	tstitlecache:cleanup()
};

(:~
 : A fresh id gets inserted - also exercises bootstrapping the cache
 : document itself on a container where it doesn't exist yet.
 :)
declare %test:assertEquals("first title") function tstitlecache:insert-stores-new-entry() {
	let $_ := titles:updateTitleCache($tstitlecache:write-id, "first title")
	return string(doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:write-id][1])
};

(:~
 : Calling again for the same id updates in place - no duplicate entries.
 :)
declare %test:assertEquals(1) function tstitlecache:update-does-not-duplicate() {
	let $_1 := titles:updateTitleCache($tstitlecache:write-id, "first title")
	let $_2 := titles:updateTitleCache($tstitlecache:write-id, "second title")
	return count(doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:write-id])
};

declare %test:assertEquals("second title") function tstitlecache:update-replaces-value() {
	let $_1 := titles:updateTitleCache($tstitlecache:write-id, "first title")
	let $_2 := titles:updateTitleCache($tstitlecache:write-id, "second title")
	return string(doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:write-id][1])
};

(:~
 : printTitleID must prefer a cached entry over recomputing - proven by
 : seeding a title no live lookup could produce (the id has no backing
 : record at all).
 :)
declare
	%test:assertEquals("a distinctive cached title no fallback path could produce")
function tstitlecache:printTitleID-prefers-cache() {
	let $_ := titles:updateTitleCache($tstitlecache:hit-id, $tstitlecache:hit-title)
	return string(exptit:printTitleID($tstitlecache:hit-id))
};

(:~
 : No cache entry and no backing record - unchanged existing behaviour.
 :)
declare %test:assertEmpty function tstitlecache:printTitleID-cache-miss-falls-through() {
	exptit:printTitleID("LITTESTtitleCacheNeverCached77")
};

(:~
 : expand:file writes the expanded document's own resolved title into the
 : cache, keyed by its own xml:id.
 :)
declare %test:assertEquals("title cache expand fixture") function tstitlecache:expand-file-populates-cache() {
	let $_ := expand:file($tstitlecache:src-col || "/" || $tstitlecache:expand-id || ".xml")
	return string(doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:expand-id][1])
};

(:~
 : Empty / missing collection must refuse (no silent full-corpus).
 :)
declare %test:assertError("expand:EMPTY") function tstitlecache:backfill-refuse-empty-collection() {
	expand:backfillTitleCache("")
};

declare %test:assertError("expand:EMPTY") function tstitlecache:backfill-refuse-missing-param() {
	expand:backfillTitleCache(())
};

declare %test:assertError("expand:BAD_ROOT") function tstitlecache:backfill-refuse-outside-expanded() {
	expand:backfillTitleCache("/db/apps/BetMasData")
};

declare %test:assertError("expand:BAD_ROOT") function tstitlecache:backfill-refuse-prefix-sibling() {
	expand:backfillTitleCache("/db/apps/expandedEvil")
};

declare %test:assertError("expand:BAD_ROOT") function tstitlecache:backfill-refuse-dotdot-traversal() {
	expand:backfillTitleCache("/db/apps/expanded/../lists")
};

declare %test:assertError("expand:MISSING") function tstitlecache:backfill-refuse-missing-collection() {
	expand:backfillTitleCache("/db/apps/expanded/works/_titleCacheBackfillMissingCol")
};

(:~
 : Harvests the title already present in an expanded document (no
 : re-expansion involved) into the cache, keyed by its own xml:id.
 :)
declare %test:assertEquals("backfill fixture title") function tstitlecache:backfill-populates-cache() {
	let $_ := expand:backfillTitleCache($tstitlecache:backfill-col)
	return string(doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:backfill-id][1])
};

(:~
 : Summary reports exactly one title backfilled.
 :)
declare %test:assertTrue function tstitlecache:backfill-summary-reports-one-title() {
	matches(expand:backfillTitleCache($tstitlecache:backfill-col), "^backfilled 1 title\(s\)$")
};
