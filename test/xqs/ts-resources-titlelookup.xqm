xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for lists:additionsform's per-request title lookup map: a
 : cache hit must return the cached value without recomputing, and a
 : cache miss must still resolve via the existing exptit:printTitle
 : fallback.
 :)
module namespace tsreslookup = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-resources-titlelookup";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "../../modules/resources.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";

declare variable $tsreslookup:cache-id := "INSTESTresourceLookupCache77";

declare variable $tsreslookup:cache-title := "a distinctive cached title no live lookup could produce";

declare variable $tsreslookup:miss-id := "INSTESTresourceLookupMiss77";

declare variable $tsreslookup:fixture := <TEI
	xmlns="http://www.tei-c.org/ns/1.0"
	xml:id="LITTESTresourceLookupFixture77"
>
	<text>
		<body>
			<ab>hit marker</ab>
			<repository ref="{ $tsreslookup:cache-id }" />
			<repository ref="{ $tsreslookup:miss-id }" />
		</body>
	</text>
</TEI>;

declare %private function tsreslookup:remove-cache-entry($id as xs:string) {
	if (doc-available("/db/apps/lists/titleCache.xml")) then
		let $existing := doc("/db/apps/lists/titleCache.xml")//t:item[@corresp eq $id]
		return if ($existing) then
			update delete $existing
		else (
		)
	else (
	)
};

declare %test:setUp function tsreslookup:setUp() {
	tsreslookup:remove-cache-entry($tsreslookup:cache-id)
};

declare %test:tearDown function tsreslookup:tearDown() {
	tsreslookup:remove-cache-entry($tsreslookup:cache-id)
};

(:~
 : A repository ref with a cache entry renders the cached title
 : directly - proven by seeding a title no live lookup against this
 : fixture (which has no matching institution record at all) could
 : otherwise produce.
 :)
declare
	%test:assertEquals("a distinctive cached title no live lookup could produce")
function tsreslookup:repo-dropdown-uses-cached-title() {
	let $_ := titles:updateTitleCache($tsreslookup:cache-id, $tsreslookup:cache-title)
	let $model := map {"hits": $tsreslookup:fixture//t:ab}
	let $form := lists:additionsform(<a />, $model)
	return string($form//*:select[@id = "repo"]/*:option[@value = $tsreslookup:cache-id][1])
};

(:~
 : A repository ref with no cache entry still resolves - unchanged
 : existing exptit:printTitle fallback behaviour.
 :)
declare %test:assertEquals("INSTESTresourceLookupMiss77") function tsreslookup:repo-dropdown-falls-back-on-cache-miss(

) {
	let $model := map {"hits": $tsreslookup:fixture//t:ab}
	let $form := lists:additionsform(<a />, $model)
	return string($form//*:select[@id = "repo"]/*:option[@value = $tsreslookup:miss-id][1])
};

(:~
 : The lookup map contains a freshly-seeded cache entry.
 :)
declare
	%test:assertEquals("a distinctive cached title no live lookup could produce")
function tsreslookup:lookup-map-contains-seeded-entry() {
	let $_ := titles:updateTitleCache($tsreslookup:cache-id, $tsreslookup:cache-title)
	let $map := lists:title-lookup-map()
	return map:get($map, $tsreslookup:cache-id)
};

(:~
 : resolve-title prefers a map hit over calling exptit:printTitle at
 : all - proven with a map entry no live lookup could produce.
 :)
declare
	%test:assertEquals("a distinctive cached title no live lookup could produce")
function tsreslookup:resolve-title-prefers-map-hit() {
	let $map := map {$tsreslookup:cache-id: $tsreslookup:cache-title}
	return lists:resolve-title($tsreslookup:cache-id, $map)
};

(:~
 : resolve-title falls back to exptit:printTitle on a map miss.
 :)
declare %test:assertEquals("INSTESTresourceLookupMiss77") function tsreslookup:resolve-title-falls-back-on-map-miss() {
	lists:resolve-title($tsreslookup:miss-id, map {})
};

(:~
 : batch-resolve-titles skips ids the titleMap already covers - proven
 : with a distinctive titleMap-only title no batch id() lookup against
 : this fixture (no backing record at all) could otherwise produce.
 :)
declare %test:assertTrue function tsreslookup:batch-resolve-titles-skips-already-cached-id() {
	let $titleMap := map {$tsreslookup:cache-id: $tsreslookup:cache-title}
	let $batch := lists:batch-resolve-titles(($tsreslookup:cache-id), $titleMap)
	return empty(map:get($batch, $tsreslookup:cache-id))
};

(:~
 : A real, uncached corpus id resolves via the batch id() lookup.
 :)
declare
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32")
function tsreslookup:batch-resolve-titles-resolves-uncached-real-id() {
	let $batch := lists:batch-resolve-titles(("BNFet32"), map {})
	return map:get($batch, "BNFet32")
};

(:~
 : An id the batch itself can't resolve is simply absent, not an
 : empty-string entry or an error.
 :)
declare %test:assertEmpty function tsreslookup:batch-resolve-titles-omits-unresolvable-id() {
	let $batch := lists:batch-resolve-titles(($tsreslookup:miss-id), map {})
	return map:get($batch, $tsreslookup:miss-id)
};

(:~
 : resolve-batched-title prefers a $titleMap hit over $batchTitles, even
 : when both cover the same id - $titleMap is the authoritative,
 : persistent cache; $batchTitles is only a same-request convenience.
 :)
declare %test:assertEquals("titleMap wins") function tsreslookup:resolve-batched-title-prefers-titlemap-over-batch() {
	let $titleMap := map {"sharedId77": "titleMap wins"}
	let $batchTitles := map {"sharedId77": "batchTitles should lose"}
	return lists:resolve-batched-title("sharedId77", $titleMap, $batchTitles)
};

(:~
 : Neither $titleMap nor $batchTitles covering an id falls back to the
 : existing per-item lookup, same as lists:resolve-title alone.
 :)
declare
	%test:assertEquals("INSTESTresourceLookupMiss77")
function tsreslookup:resolve-batched-title-falls-back-when-neither-covers() {
	lists:resolve-batched-title($tsreslookup:miss-id, map {}, map {})
};

(:~
 : Deleted ids are excluded from the batch so resolve-batched-title
 : falls through to printTitleID's deletion notice, not a stale live
 : record title the batch would otherwise return.
 :)
declare variable $tsreslookup:deleted-id := "LIT1894Martyr";

declare %test:assertEmpty function tsreslookup:batch-resolve-titles-omits-deleted-id() {
	let $batch := lists:batch-resolve-titles(($tsreslookup:deleted-id), map {})
	return map:get($batch, $tsreslookup:deleted-id)
};

declare
	%test:assertEquals("LIT1894Martyr was permanently deleted")
function tsreslookup:resolve-batched-title-renders-deleted-notice() {
	lists:resolve-batched-title($tsreslookup:deleted-id, map {}, map {})
};
