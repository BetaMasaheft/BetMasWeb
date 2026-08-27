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
