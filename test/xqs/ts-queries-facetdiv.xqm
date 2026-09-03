xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for q:facetDiv/q:facetGroup's per-request title resolution
 : (modules/queries.xqm) - see BetMasWeb#3. Pins cache-hit, cache-miss,
 : batched id() resolution, TUList/persNamesList override precedence,
 : and multi-value preservation.
 :
 : The TUList/persNamesList/batch-id() tests use real, stable corpus
 : ids (not freshly-stored fixtures): $exptit:col is a collection()
 : snapshot bound once when this whole suite starts, before any test
 : or setUp body runs, so a document stored mid-suite is invisible to
 : it - only $exptit:TUList/$exptit:persNamesList (doc() references,
 : mutated in place via `update insert`) pick up same-run changes.
 :)
module namespace tsfacetdiv = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-facetdiv";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";
import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "../../modules/resources.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "../../modules/exptit.xqm";

declare variable $tsfacetdiv:cache-id := "INSTESTfacetDivCache77";

declare variable $tsfacetdiv:cache-title := "a distinctive cached facet title no live lookup could produce";

declare variable $tsfacetdiv:miss-id := "INSTESTfacetDivMiss77";

(: real, stable ids with no pre-existing cache/TUList/persNames entry,
verified live before picking them - see exptit.xqm's own printTitleID
tests for the same "real known id" precedent. :)
declare variable $tsfacetdiv:plain-id := "BNFet32";

declare variable $tsfacetdiv:plain-node-title := "Paris, Bibliothèque nationale de France, BnF Éthiopien 32";

declare variable $tsfacetdiv:tulist-id := "BNFet32";

declare variable $tsfacetdiv:tulist-override-title := "a distinctive TUList override title only the override list has";

declare variable $tsfacetdiv:persnames-id := "LOC1001Aallee";

declare variable $tsfacetdiv:persnames-override-title :=
	"a distinctive persNamesList override title only that list has";

declare %private function tsfacetdiv:remove-title-cache-entry($id as xs:string) {
	if (doc-available("/db/apps/lists/titleCache.xml")) then
		let $existing := doc("/db/apps/lists/titleCache.xml")//t:item[@corresp eq $id]
		return if ($existing) then
			update delete $existing
		else (
		)
	else (
	)
};

declare %private function tsfacetdiv:remove-tulist-entry($id as xs:string) {
	let $existing := $exptit:TUList//t:item[@corresp eq $id]
	return if ($existing) then
		update delete $existing
	else (
	)
};

declare %private function tsfacetdiv:remove-persnames-entry($id as xs:string) {
	let $existing := $exptit:persNamesList//t:item[@corresp eq $id]
	return if ($existing) then
		update delete $existing
	else (
	)
};

declare %private function tsfacetdiv:remove-nocatdesc-category() {
	let $existing := doc("/db/apps/lists/canonicaltaxonomy.xml")//t:category[t:category/@xml:id eq
		$tsfacetdiv:tax-nocatdesc-id]
	return if ($existing) then
		update delete $existing
	else (
	)
};

declare %private function tsfacetdiv:cleanup() {
	tsfacetdiv:remove-title-cache-entry($tsfacetdiv:cache-id),
	tsfacetdiv:remove-tulist-entry($tsfacetdiv:tulist-id),
	tsfacetdiv:remove-persnames-entry($tsfacetdiv:persnames-id),
	tsfacetdiv:remove-nocatdesc-category()
};

declare %test:setUp function tsfacetdiv:setUp() {
	tsfacetdiv:cleanup()
};

declare %test:tearDown function tsfacetdiv:tearDown() {
	tsfacetdiv:cleanup()
};

(:~
 : A BMurl-prefixed facet label with a cache entry renders the cached
 : title, proven with a title no live lookup against a nonexistent id
 : could otherwise produce.
 :)
declare
	%test:assertEquals("a distinctive cached facet title no live lookup could produce")
function tsfacetdiv:cache-hit-renders-cached-title() {
	let $_ := titles:updateTitleCache($tsfacetdiv:cache-id, $tsfacetdiv:cache-title)
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$config:BMurl || $tsfacetdiv:cache-id: 3}
	let $div := q:facetDiv("repository", $facets, "Repository", $titleMap)
	return string($div//*:div[contains(@id, "facet-list")]/text()[normalize-space(.) != ""][1])
};

(:~
 : A BMurl-prefixed facet label with no cache entry and no backing
 : record still resolves via the existing per-item fallback.
 :)
declare %test:assertEquals("INSTESTfacetDivMiss77") function tsfacetdiv:cache-miss-falls-back() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$config:BMurl || $tsfacetdiv:miss-id: 1}
	let $div := q:facetDiv("repository", $facets, "Repository", $titleMap)
	return string($div//*:div[contains(@id, "facet-list")]/text()[normalize-space(.) != ""][1])
};

(:~
 : The rewritten flat FLWOR (replacing map:for-each) preserves every
 : distinct facet value and its own count - not just the first.
 :)
declare %test:assertEquals(2) function tsfacetdiv:preserves-all-facet-values() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {"plainLabelOne": 4, "plainLabelTwo": 7}
	let $div := q:facetDiv("keywords-plain", $facets, "Test facet", $titleMap)
	return count($div//*:input[@type = "checkbox"])
};

declare %test:assertEquals(7) function tsfacetdiv:preserves-each-facet-value-count() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {"plainLabelOne": 4, "plainLabelTwo": 7}
	let $div := q:facetDiv("keywords-plain", $facets, "Test facet", $titleMap)
	return xs:integer($div//*:input[@value = "plainLabelTwo"][1]/following-sibling::*:span[1])
};

(:~
 : q:facetGroup threads its own titleMap parameter down to
 : q:facetDiv for each facet it builds, not just the ones tested
 : directly above.
 :)
declare
	%test:assertEquals("a distinctive cached facet title no live lookup could produce")
function tsfacetdiv:facetgroup-threads-titlemap-to-facetdiv() {
	let $_ := titles:updateTitleCache($tsfacetdiv:cache-id, $tsfacetdiv:cache-title)
	let $titleMap := lists:title-lookup-map()
	let $subsequence := <fixture>
		<t:witness xmlns:t="http://www.tei-c.org/ns/1.0" corresp="{ $config:BMurl || $tsfacetdiv:cache-id }" />
	</fixture>
	let $group := q:facetGroup(("witness"), "Test group", $subsequence, $titleMap)
	return string($group//*:div[contains(@id, "facet-list")]/text()[normalize-space(.) != ""][1])
};

(:~
 : No titleMap entry, but a real record id() resolves - the batched
 : id() lookup, the primary new code path this fix exists for.
 :)
declare
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32")
function tsfacetdiv:batch-resolves-uncached-real-id() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$config:BMurl || $tsfacetdiv:plain-id: 1}
	let $div := q:facetDiv("repository", $facets, "Repository", $titleMap)
	return string($div//*:div[contains(@id, "facet-list")]/text()[normalize-space(.) != ""][1])
};

(:~
 : exptit:printTitleID() checks $exptit:TUList before ever falling
 : back to a live id() lookup - the batched fast path must respect the
 : same precedence, not just show the id()-resolved node's own title.
 :)
declare
	%test:assertEquals("a distinctive TUList override title only the override list has")
function tsfacetdiv:tulist-entry-takes-precedence-over-live-node-title() {
	let $_tu := update insert <item xmlns="http://www.tei-c.org/ns/1.0" corresp="{ $tsfacetdiv:tulist-id }">
		{ $tsfacetdiv:tulist-override-title }
	</item> into $exptit:TUList//t:list
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$config:BMurl || $tsfacetdiv:tulist-id: 1}
	let $div := q:facetDiv("repository", $facets, "Repository", $titleMap)
	return string($div//*:div[contains(@id, "facet-list")]/text()[normalize-space(.) != ""][1])
};

(:~
 : Same precedence contract for $exptit:persNamesList.
 :)
declare
	%test:assertEquals("a distinctive persNamesList override title only that list has")
function tsfacetdiv:persnameslist-entry-takes-precedence-over-live-node-title() {
	let $_pn := update insert <item xmlns="http://www.tei-c.org/ns/1.0" corresp="{ $tsfacetdiv:persnames-id }">
		{ $tsfacetdiv:persnames-override-title }
	</item> into $exptit:persNamesList//t:list
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$config:BMurl || $tsfacetdiv:persnames-id: 1}
	let $div := q:facetDiv("repository", $facets, "Repository", $titleMap)
	return string($div//*:div[contains(@id, "facet-list")]/text()[normalize-space(.) != ""][1])
};

(: Real, stable canonicaltaxonomy.xml entries - verified live before picking
them. "Royal" is sourced app-wide as a bare t:term/@key value; "AT1034Tempietto"
is sourced as a BMurl-prefixed t:ref[@type='authFile']/@corresp value
(collection.xconf's "keywords" facet dimension combines both shapes) - see
queries.xqm's q:facetDiv keywords branch. :)
declare variable $tsfacetdiv:tax-barekey-id := "Royal";

declare variable $tsfacetdiv:tax-barekey-label := "Royal inscription";

declare variable $tsfacetdiv:tax-barekey-group := "Types of Inscriptions";

declare variable $tsfacetdiv:tax-corresp-id := "AT1034Tempietto";

declare variable $tsfacetdiv:tax-corresp-label := "Tempietto";

declare variable $tsfacetdiv:tax-corresp-group := "Art Themes";

(: A synthetic category, inserted/removed per-test - real canonicaltaxonomy.xml
has no @xml:id category lacking t:catDesc today, so this shape has to be
manufactured to test it at all. Regression coverage for q:tax-lookup-map()
indexing by @xml:id regardless of whether a category has a catDesc. :)
declare variable $tsfacetdiv:tax-nocatdesc-id := "TESTNoCatDesc77";

declare variable $tsfacetdiv:tax-nocatdesc-group := "TestGroupNoCatDesc77";

(:~
 : A bare, un-prefixed keyword value (the t:term/@key shape) resolves its
 : display label from the taxonomy's own catDesc text.
 :
 : @return the rendered facet label text
 :)
declare %test:assertEquals("Royal inscription") function tsfacetdiv:keywords-barekey-resolves-catdesc-label() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$tsfacetdiv:tax-barekey-id: 1}
	let $div := q:facetDiv("keywords", $facets, "Keywords", $titleMap)
	return string(
		$div//*:input[@value = $tsfacetdiv:tax-barekey-id]/following-sibling::text()[normalize-space(.) != ""][1]
	)
};

(:~
 : A bare keyword value groups under its real taxonomy section heading.
 :
 : @return true() if the value's checkbox renders inside its real
 : taxonomy-section sublist
 :)
declare %test:assertTrue function tsfacetdiv:keywords-barekey-groups-under-real-heading() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$tsfacetdiv:tax-barekey-id: 1}
	let $div := q:facetDiv("keywords", $facets, "Keywords", $titleMap)
	let $groupId := "keywords-" || replace($tsfacetdiv:tax-barekey-group, " ", "") || "-facet-sublist"
	return exists($div//*:div[@id = $groupId]//*:input[@value = $tsfacetdiv:tax-barekey-id])
};

(:~
 : A BMurl-prefixed keyword value (the t:ref/@corresp shape) resolves its
 : display label from the same taxonomy lookup, stripped of the prefix
 : first.
 :
 : @return the rendered facet label text
 :)
declare %test:assertEquals("Tempietto") function tsfacetdiv:keywords-bmurl-corresp-resolves-catdesc-label() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$config:BMurl || $tsfacetdiv:tax-corresp-id: 1}
	let $div := q:facetDiv("keywords", $facets, "Keywords", $titleMap)
	return string(
		$div//*:input[@value = $config:BMurl || $tsfacetdiv:tax-corresp-id]/following-sibling::text()[normalize-space(.) !=
			""][1]
	)
};

(:~
 : A BMurl-prefixed keyword value groups under its real taxonomy section
 : heading, not the empty "" heading a raw (unstripped) value match falls
 : back to.
 :
 : @return true() if the value's checkbox renders inside its real
 : taxonomy-section sublist
 :)
declare %test:assertTrue function tsfacetdiv:keywords-bmurl-corresp-groups-under-real-heading() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$config:BMurl || $tsfacetdiv:tax-corresp-id: 1}
	let $div := q:facetDiv("keywords", $facets, "Keywords", $titleMap)
	let $groupId := "keywords-" || replace($tsfacetdiv:tax-corresp-group, " ", "") || "-facet-sublist"
	return exists($div//*:div[@id = $groupId]//*:input[@value = $config:BMurl || $tsfacetdiv:tax-corresp-id])
};

(:~
 : Two distinct keyword values, one of each shape, resolve and group
 : independently in the same call - the shared per-call taxonomy lookup
 : must not collapse or cross-contaminate them.
 :
 : @return the count of correctly-grouped checkboxes found (2 if both
 : resolved independently)
 :)
declare %test:assertEquals(2) function tsfacetdiv:keywords-mixed-shapes-both-resolve-independently() {
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$tsfacetdiv:tax-barekey-id: 1, $config:BMurl || $tsfacetdiv:tax-corresp-id: 1}
	let $div := q:facetDiv("keywords", $facets, "Keywords", $titleMap)
	let $bareGroupId := "keywords-" || replace($tsfacetdiv:tax-barekey-group, " ", "") || "-facet-sublist"
	let $correspGroupId := "keywords-" || replace($tsfacetdiv:tax-corresp-group, " ", "") || "-facet-sublist"
	return count(
		(
			$div//*:div[@id = $bareGroupId]//*:input[@value = $tsfacetdiv:tax-barekey-id],
			$div//*:div[@id = $correspGroupId]//*:input[@value = $config:BMurl || $tsfacetdiv:tax-corresp-id]
		)
	)
};

(:~
 : A keyword value resolving by @xml:id to a category with no t:catDesc
 : (a shape not present in the real corpus today, but not ruled out by
 : the schema either) still groups under its real taxonomy section
 : heading - q:tax-lookup-map() must index by @xml:id regardless of
 : whether the category has a catDesc, matching id($x, $q:tax)'s own
 : guarantee on the code path this replaced.
 :
 : @return true() if the value's checkbox renders inside its real
 : taxonomy-section sublist
 :)
declare %test:assertTrue function tsfacetdiv:keywords-id-only-category-still-groups() {
	let $_insert := update insert <category xmlns="http://www.tei-c.org/ns/1.0">
		<desc>{ $tsfacetdiv:tax-nocatdesc-group }</desc>
		<category xml:id="{ $tsfacetdiv:tax-nocatdesc-id }" />
	</category> into doc("/db/apps/lists/canonicaltaxonomy.xml")//t:taxonomy
	let $titleMap := lists:title-lookup-map()
	let $facets := map {$tsfacetdiv:tax-nocatdesc-id: 1}
	let $div := q:facetDiv("keywords", $facets, "Keywords", $titleMap)
	let $groupId := "keywords-" || replace($tsfacetdiv:tax-nocatdesc-group, " ", "") || "-facet-sublist"
	return exists($div//*:div[@id = $groupId]//*:input[@value = $tsfacetdiv:tax-nocatdesc-id])
};
