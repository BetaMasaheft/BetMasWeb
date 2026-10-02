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
 : searches the content of the ids and returns a JSON object containing an array of objects with possible matches. id here can be a full id or any part of it.
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
		let $query := (
			$exptit:col/t:TEI[contains(@xml:id, $needle)],
			$exptit:col//t:msPart[contains(@xml:id, $needle)],
			$exptit:col//t:msItem[contains(@xml:id, $needle)],
			$exptit:col//t:title[contains(@xml:id, $needle)],
			$exptit:col//t:div[contains(@xml:id, $needle)]
		)
		let $results :=
			for $hit in $query
			let $i := string($hit/@xml:id)
			(: let $rootID := string(root($hit)/t:TEI/@xml:id) :)(: let $title := if ($i = $rootID) then exptit:printTitleID($i) else api:printSubtitle(root($hit),$i) :)
			return map {"id": $i}
		return if (exists($query)) then (
			map {"items": $results, "total": count($query)}
		) else (
			lookID:no-results()
		)
	)
};
