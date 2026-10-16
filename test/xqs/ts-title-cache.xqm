xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for the shared works/persons/places/institutions title cache:
 : titles:updateTitleCache (write side), expand write gating, and catalog
 : label resolution ignoring stale titleCache (Phase 5). Under legacy
 : EXPTIT, exptit:printTitleID may still surface cache hits via the
 : legacy backend; under catalog it must not.
 :)
module namespace tstitlecache = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-title-cache";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "../../modules/exptit.xqm";
import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";
import module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog" at "../../modules/catalog.xqm";

declare variable $tstitlecache:cache-path := "/db/apps/lists/titleCache.xml";

declare variable $tstitlecache:write-id := "LITTESTtitleCacheWrite77";

declare variable $tstitlecache:hit-id := "LITTESTtitleCacheHit77";

declare variable $tstitlecache:hit-title := "a distinctive cached title no fallback path could produce";

declare variable $tstitlecache:stale-id := "LIT1367Exodus";

declare variable $tstitlecache:stale-title := "STALE_TITLE_CACHE_MUST_NOT_WIN";

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

declare variable $tstitlecache:backfill-blank-id := "LITTESTtitleCacheBackfillBlank77";

(:~
 : A document with a blank full title - the backfill must skip this
 : one when writing entries, and its summary count must not include
 : it either.
 :)
declare variable $tstitlecache:backfill-blank-tei := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	xml:id="{ $tstitlecache:backfill-blank-id }"
>
	<teiHeader><titleStmt><title type="full" /></titleStmt></teiHeader>
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
	xmldb:store($tstitlecache:backfill-col, $tstitlecache:backfill-id || ".xml", $tstitlecache:backfill-tei),
	xmldb:store($tstitlecache:backfill-col, $tstitlecache:backfill-blank-id || ".xml", $tstitlecache:backfill-blank-tei)
};

declare %private function tstitlecache:cleanup() {
	tstitlecache:remove-entry($tstitlecache:write-id),
	tstitlecache:remove-entry($tstitlecache:hit-id),
	tstitlecache:remove-entry($tstitlecache:expand-id),
	tstitlecache:remove-entry($tstitlecache:backfill-id),
	tstitlecache:remove-entry($tstitlecache:backfill-blank-id),
	tstitlecache:remove-entry($tstitlecache:stale-id),
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
 : Under legacy EXPTIT, printTitleID still surfaces a cache hit for an id
 : with no backing record. Under catalog, titleCache is ignored — expect
 : empty / non-cache text.
 :)
declare %test:assertTrue function tstitlecache:printTitleID-cache-policy() {
	let $_ := titles:updateTitleCache($tstitlecache:hit-id, $tstitlecache:hit-title)
	let $got := string(exptit:printTitleID($tstitlecache:hit-id))
	return if (catalog:backend("exptit") eq "catalog") then
		$got ne $tstitlecache:hit-title
	else
		$got eq $tstitlecache:hit-title
};

(:~
 : No cache entry and no backing record - unchanged existing behaviour.
 :)
declare %test:assertEmpty function tstitlecache:printTitleID-cache-miss-falls-through() {
	exptit:printTitleID("LITTESTtitleCacheNeverCached77")
};

(:~
 : Hermetic: write gate is false for the catalog backend name (CI-safe).
 :)
declare %test:assertFalse function tstitlecache:writes-title-cache-false-for-catalog() {
	expand:writes-title-cache("catalog")
};

(:~
 : Hermetic: write gate is true for the legacy backend name (CI-safe).
 :)
declare %test:assertTrue function tstitlecache:writes-title-cache-true-for-legacy() {
	expand:writes-title-cache("legacy")
};

(:~
 : Hermetic: 0-arity mirrors catalog:backend("exptit").
 :)
declare %test:assertTrue function tstitlecache:writes-title-cache-mirrors-exptit-backend() {
	expand:writes-title-cache() eq (catalog:backend("exptit") ne "catalog")
};

(:~
 : catalog:label(..., "catalog") must not return a stale titleCache value
 : when labels.xml / expanded full-title disagree with the cache.
 :)
declare %test:assertTrue function tstitlecache:catalog-label-ignores-stale-title-cache() {
	let $_ := titles:updateTitleCache($tstitlecache:stale-id, $tstitlecache:stale-title)
	let $got := normalize-space(string(catalog:label($tstitlecache:stale-id, "catalog")))
	return $got ne "" and $got ne $tstitlecache:stale-title
};

(:~
 : expand:file writes the expanded document's own resolved title into the
 : cache when CATALOG_BACKEND_EXPTIT is legacy; skips the write under catalog
 : (Phase 5 gut of mutable titleCache).
 :)
declare %test:assertTrue function tstitlecache:expand-file-title-cache-policy() {
	let $_ := expand:file($tstitlecache:src-col || "/" || $tstitlecache:expand-id || ".xml")
	let $hit := string(doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:expand-id][1])
	return if (expand:writes-title-cache()) then
		$hit eq "title cache expand fixture"
	else
		$hit eq ""
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
 : re-expansion involved) into the cache under legacy; no-ops under
 : CATALOG_BACKEND_EXPTIT=catalog.
 :)
declare %test:assertTrue function tstitlecache:backfill-title-cache-policy() {
	let $summary := expand:backfillTitleCache($tstitlecache:backfill-col)
	let $hit := string(doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:backfill-id][1])
	return if (catalog:backend("exptit") eq "catalog") then
		starts-with($summary, "skipped title-cache backfill") and $hit eq ""
	else
		$summary eq "backfilled 1 title(s)" and $hit eq "backfill fixture title"
};

(:~
 : Summary reports exactly one title backfilled under legacy - the fixture
 : collection also has a blank-title document that must be skipped. Under
 : catalog the whole backfill is skipped.
 :)
declare %test:assertTrue function tstitlecache:backfill-summary-reports-one-title() {
	let $summary := expand:backfillTitleCache($tstitlecache:backfill-col)
	return if (catalog:backend("exptit") eq "catalog") then
		starts-with($summary, "skipped title-cache backfill")
	else
		matches($summary, "^backfilled 1 title\(s\)$")
};

(:~
 : A document with a blank full title gets no cache entry at all (legacy
 : write path). Under catalog there is no write either.
 :)
declare %test:assertEmpty function tstitlecache:backfill-skips-blank-title() {
	let $_ := expand:backfillTitleCache($tstitlecache:backfill-col)
	return doc($tstitlecache:cache-path)//t:item[@corresp eq $tstitlecache:backfill-blank-id]
};
