xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for q:facetDiv/q:facetGroup's per-request title-lookup map
 : (modules/queries.xqm). q:facetDiv used to resolve each distinct
 : facet value's display title via a fresh exptit:printTitle() call
 : inside a map:for-each closure - an N+1 that dominates broad
 : newSearch.html result pages (BetMasWeb#3). These tests pin the
 : cache-hit/cache-miss/multi-value-preservation contract of the
 : rewritten, closure-free version against the same persistent title
 : cache lists:title-lookup-map()/lists:resolve-title() already use
 : elsewhere (see ts-resources-titlelookup.xqm).
 :)
module namespace tsfacetdiv = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-facetdiv";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";
import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "../../modules/resources.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

declare variable $tsfacetdiv:cache-id := "INSTESTfacetDivCache77";

declare variable $tsfacetdiv:cache-title := "a distinctive cached facet title no live lookup could produce";

declare variable $tsfacetdiv:miss-id := "INSTESTfacetDivMiss77";

declare %private function tsfacetdiv:remove-cache-entry($id as xs:string) {
	if (doc-available("/db/apps/lists/titleCache.xml")) then
		let $existing := doc("/db/apps/lists/titleCache.xml")//t:item[@corresp eq $id]
		return if ($existing) then
			update delete $existing
		else (
		)
	else (
	)
};

declare %test:setUp function tsfacetdiv:setUp() {
	tsfacetdiv:remove-cache-entry($tsfacetdiv:cache-id)
};

declare %test:tearDown function tsfacetdiv:tearDown() {
	tsfacetdiv:remove-cache-entry($tsfacetdiv:cache-id)
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
 : A BMurl-prefixed facet label with no cache entry still resolves via
 : the existing exptit:printTitle fallback - unchanged behaviour.
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
