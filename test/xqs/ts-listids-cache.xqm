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
module namespace tslistids = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-listids-cache";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace listIds = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/listIds" at "../../restviews/ids.xqm";

declare %test:assertTrue function tslistids:cached-body-returns-institution-divs() {
	let $body := listIds:cached-body()
	return exists($body) and (every $div in $body satisfies $div/@class = "w3-container")
};

declare %test:assertTrue function tslistids:cached-body-second-call-matches-first() {
	(:
	 : the actual fix being tested: a cache hit must return the same
	 : content as the call that populated it, not stale/partial data
	 :)
	let $first := listIds:cached-body()
	let $second := listIds:cached-body()
	return deep-equal($first, $second)
};
