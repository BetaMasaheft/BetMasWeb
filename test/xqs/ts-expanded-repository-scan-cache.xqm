xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for /listIds' cached body (restviews/ids.xqm): listIds:body's
 : full-corpus scan measured 14-22s under load (an unindexed
 : t:repository scan across ~22,000 elements plus a nested id
 : extraction across ~20,000 manuscripts) - deterministic given current
 : corpus state, so listIds:cached-body wraps it in the same TTL-cache
 : idiom as q:max-folia (modules/queries.xqm's $q:CORPUS-STATS-CACHE).
 : These tests hit the real corpus (no fixture - the function has no
 : request-independent seam to fake), matching ts-queries-formbounds.xqm's
 : own q:max-folia tests.
 :)
module namespace tsexpandedscan = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expanded-repository-scan-cache";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace listIds = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/listIds" at "../../restviews/ids.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

declare %test:assertTrue function tsexpandedscan:cached-body-returns-institution-divs() {
	let $body := listIds:cached-body()
	return exists($body) and (every $div in $body satisfies $div/@class = "w3-container")
};

declare %test:assertTrue function tsexpandedscan:cached-body-second-call-matches-first() {
	(:
	 : the actual fix being tested: a cache hit must return the same
	 : content as the call that populated it, not stale/partial data
	 :)
	let $first := listIds:cached-body()
	let $second := listIds:cached-body()
	return deep-equal($first, $second)
};

(:~
 : Shape of the institution/collection/id tree. These pin the structure
 : the grouping has to produce, so a rewrite cannot quietly drop a
 : manuscript, an institution or a collection heading.
 :)
declare %test:assertTrue function tsexpandedscan:every-institution-lists-non-empty-ids() {
	let $divs := listIds:cached-body()
	return every
		$div in
		$divs satisfies
		let $ids := $div/div[@class = "w3-row"]/div[@class = "w3-container"]/div[@class = "w3-row"]
		return (count($div/h1) eq 1) and exists($ids) and (every $id in $ids satisfies normalize-space(string($id)) ne "")
};

declare %test:assertTrue function tsexpandedscan:collections-are-sorted-within-an-institution() {
	let $divs := listIds:cached-body()
	return every
		$div in
		$divs satisfies
		let $collections := $div/div[@class = "w3-row"]/h2/string()
		return $collections = (sort($collections))
};

declare %test:assertTrue function tsexpandedscan:ids-are-sorted-within-a-collection() {
	let $divs := listIds:cached-body()
	return every
		$div in
		$divs satisfies
		every
			$row in
			$div/div[@class = "w3-row"] satisfies
			let $ids := $row/div[@class = "w3-container"]/div[@class = "w3-row"]/string()
			return $ids = (sort($ids))
};

declare %test:assertTrue function tsexpandedscan:institutions-are-sorted() {
	let $divs := listIds:cached-body()
	let $headings := $divs/h1/string()
	return $headings = (sort($headings))
};

declare %test:assertTrue function tsexpandedscan:covers-the-whole-corpus() {
	(:
	 : one id row per t:repository outside the excluded sigla, so a
	 : rewrite cannot silently narrow the list
	 :)
	let $divs := listIds:cached-body()
	let $listed := count($divs/div[@class = "w3-row"]/div[@class = "w3-container"]/div[@class = "w3-row"])
	let $expected := count(
		collection($config:data-rootMS)//t:repository[contains(@ref, "INS")][not(ends-with(@ref, "IHA"))][not(
			@ref eq "INS0004HMML"
		)]
	)
	return $listed = $expected
};
