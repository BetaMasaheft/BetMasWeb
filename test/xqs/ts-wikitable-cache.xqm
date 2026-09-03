xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for wiki:viaf-lookup-cached (modules/wikitable.xqm) - the
 : cache-first wrapper around Wikidata's live VIAF lookup. Uses an
 : injected stub fetcher throughout, so these tests never touch the
 : network: a cache hit must not call the fetcher at all, and a fetcher
 : that returns empty must still short-circuit later calls via the
 : negative-cache entry.
 :)
module namespace tswikicache = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-wikitable-cache";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace wiki = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/wiki" at "../../modules/wikitable.xqm";

declare %private function tswikicache:failing-fetcher($Qitem as xs:string) as xs:string? {
	fn:error(xs:QName("tswikicache:unexpected-fetch"), "fetcher should not have been called for " || $Qitem)
};

(:~
 : A cache miss calls the fetcher and returns its result.
 :)
declare %test:assertEquals("77771111") function tswikicache:miss-calls-fetcher-and-returns-its-result() {
	wiki:viaf-lookup-cached("QTEST-miss-77771111", function ($q) { "77771111" })
};

(:~
 : A cache hit returns the cached value without ever calling the
 : fetcher - proven with a fetcher that errors if invoked at all.
 :)
declare %test:assertEquals("cached-value-only-a-hit-could-produce") function tswikicache:hit-never-calls-fetcher() {
	let $id := "QTEST-hit-" || util:uuid()
	let $prime := wiki:viaf-lookup-cached($id, function ($q) { "cached-value-only-a-hit-could-produce" })
	return wiki:viaf-lookup-cached($id, tswikicache:failing-fetcher#1)
};

(:~
 : A fetcher returning empty (no VIAF claim on this entity) caches that
 : as a negative result - a later lookup for the same id must not call
 : the fetcher again either.
 :)
declare %test:assertEquals(0) function tswikicache:negative-result-is-cached-too() {
	let $id := "QTEST-negative-" || util:uuid()
	let $prime := wiki:viaf-lookup-cached($id, function ($q) { () })
	return count(wiki:viaf-lookup-cached($id, tswikicache:failing-fetcher#1))
};

(:~
 : A fetcher raising wiki:fetch-failed (the real live fetcher's own
 : failure signal - network error or non-200) must not be cached the
 : same way a confirmed "no claim" result is - a transient failure
 : should not permanently hide a VIAF id that actually exists. Proven
 : by a second call, same id, with a fetcher that would succeed: it
 : must actually run, not be short-circuited by a stale negative-cache
 : entry from the first call's failure.
 :)
declare %test:assertEquals("recovered-after-transient-failure") function tswikicache:fetch-failure-is-not-cached() {
	let $id := "QTEST-transient-" || util:uuid()
	let $firstAttempt := wiki:viaf-lookup-cached(
		$id,
		function ($q) { fn:error(xs:QName("wiki:fetch-failed"), "simulated transient failure") }
	)
	return wiki:viaf-lookup-cached($id, function ($q) { "recovered-after-transient-failure" })
};

(:~
 : wiki:wikitable's own markup, given a resolvable VIAF id - primed
 : straight into the cache (not via the injectable wrapper it calls
 : internally) so this exercises wiki:wikitable itself end to end
 : without ever reaching the live fetcher.
 :)
declare %test:assertEquals("QTEST-render-99999999") function tswikicache:wikitable-renders-item-link() {
	let $id := "QTEST-render-99999999"
	let $_prime := wiki:viaf-lookup-cached($id, function ($q) { "77771234" })
	let $div := wiki:wikitable($id)
	return string($div//*:a[1]/text())
};

declare %test:assertEquals(1) function tswikicache:wikitable-with-no-viaf-omits-viaf-row() {
	let $id := "QTEST-noviaf-88888888"
	let $_prime := wiki:viaf-lookup-cached($id, function ($q) { () })
	let $div := wiki:wikitable($id)
	return count($div//*:tr)
};
