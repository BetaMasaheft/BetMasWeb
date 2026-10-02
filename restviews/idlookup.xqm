xquery version "3.1" encoding "UTF-8";

(:~
 : returns entities which share a same keyword
 :
 : @author Pietro Liuzzo
 :)
module namespace lookID = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lookID";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.json.org";

import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";

(:~
 : The most ids this endpoint will put in a response.
 :
 : The endpoint is a typeahead, and no typeahead renders thousands of
 : suggestions. The cap bounds both the response and the work spent
 : building it: without it a needle as short as "1" matched ~125,600
 : nodes and returned a 3.7 MB JSON array. ?total still reports the true
 : count and ?truncated says the list is partial, so nothing is silently
 : withheld.
 :)
declare variable $lookID:MAX-HITS := 100;

(:~
 : The id to match on, normalised, or () when the caller did not ask for
 : anything specific.
 :
 : ?id= reaches this endpoint either absent or blank, and both used to run
 : the search against every id-bearing node in the corpus: contains($x, ())
 : is true and contains($x, "") is true, so a single request matched all
 : ~192,000 nodes and serialised them as one multi-megabyte payload. An
 : absent parameter was worse still - eXist's optimiser rewrites
 : contains(@xml:id, $id) into an index lookup and emitted it with no keys,
 : so the request raised XPTY0004 rather than returning anything.
 :
 : @param $request the REST request map
 : @return the trimmed id, or () when it was absent or blank
 :)
declare function lookID:requested-id($request as map(*)) as xs:string? {
	let $given := normalize-space(string-join($request?parameters?id, ""))
	return if ($given eq "") then (
	) else
		$given
};

declare function lookID:no-results() as element(json:value) {
	<json:value><json:value json:array="true"><info>No results, sorry</info></json:value></json:value>
};

(:~
 : Looks up records whose xml:id contains the requested id and returns a
 : JSON object with an array of possible matches. The id may be a full id
 : or any part of one.
 :
 : The response is bounded by $lookID:MAX-HITS. ?total always reports the
 : real number of matches and ?truncated says whether the list is partial,
 : so a capped answer never reads as a complete one.
 :
 : @param $request the REST request map
 : @return a map of items/total/returned/truncated, or the "No results"
 : element when nothing matched
 :)
declare function lookID:IDSlookup($request as map(*)) {
	let $id := lookID:requested-id($request)
	return if (not(exists($id))) then
		lookID:no-results()
	else (
		log:add-log-message("/api/idlookup?id=" || $id, sm:id()//sm:real/sm:username/string(), "REST"),
		(:
		 : Re-bind as a definite xs:string: the caller checked $id exists, and
		 : a definite value keeps the optimiser's index rewrite well formed.
		 :)
		let $needle := string($id)
		let $matches := (
			$exptit:col/t:TEI[contains(@xml:id, $needle)],
			$exptit:col//t:msPart[contains(@xml:id, $needle)],
			$exptit:col//t:msItem[contains(@xml:id, $needle)],
			$exptit:col//t:title[contains(@xml:id, $needle)],
			$exptit:col//t:div[contains(@xml:id, $needle)]
		)
		(:
		 : count() streams, so the true total costs little even when it is
		 : six figures; building a map per match and serialising it does
		 : not, which is what the cap is for.
		 :)
		let $total := count($matches)
		return if ($total gt 0) then (
			let $items :=
				for $hit in $matches[position() le $lookID:MAX-HITS]
				return map {"id": string($hit/@xml:id)}
			return map {"items": $items, "total": $total, "returned": count($items), "truncated": $total gt count($items)}
		) else (
			lookID:no-results()
		)
	)
};
