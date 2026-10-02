xquery version "3.1" encoding "UTF-8";

(:~
 : module for the different item views, decides what kind of item it is, in which way to display it
 :
 : @author Pietro Liuzzo
 :)
module namespace listIds = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/listIds";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace cache = "http://exist-db.org/xquery/cache";

declare variable $listIds:CACHE := "list-ids";

declare variable $listIds:CACHE-TTL := 3600;

(:~
 : Groups values by a derived key, preserving input order within each group.
 :
 : eXist's group-by is unusable for /listIds: inside this stored library
 : module it drove the heap past 4 GB and killed the JVM, while the very
 : same FLWOR run as an ad-hoc query stayed under 800 MB. The corpus walk
 : and the node construction are both cheap on their own - it is only the
 : group-by that costs - so the grouping is done by folding into a map and
 : the working set stays proportional to the input.
 :
 : @param $items the values to group
 : @param $key derives the grouping key from one value
 : @return a map from key to the values carrying that key
 :)
declare %private function listIds:bucket-by($items as item()*, $key as function (item()) as xs:string) as map(*) {
	fold-left(
		$items,
		map {},
		function ($buckets, $item) {
			let $bucket-key := $key($item)
			return map:put($buckets, $bucket-key, ($buckets($bucket-key), $item))
		}
	)
};

(:~
 : The collection a repository is filed under.
 :
 : @param $repo a t:repository element
 : @return the collection name, or a placeholder when it has none
 :)
declare %private function listIds:collection-of($repo as element(t:repository)) as xs:string {
	if ($repo/following-sibling::t:collection) then
		string($repo/following-sibling::t:collection[1]/text())
	else
		"no specific collection"
};

(:~
 : The row this repository contributes to the listing.
 :
 : @param $repo a t:repository element
 : @return a map with the collection and the owning document's xml:id
 :)
declare %private function listIds:entry($repo as element(t:repository)) as map(*) {
	map {"collection": listIds:collection-of($repo), "id": string(root($repo)/t:TEI/@xml:id)}
};

(:~
 : One <div> per institution, each listing its manuscripts' @xml:id
 : grouped by collection - the expensive part of /listIds: an unindexed
 : scan of every t:repository in the manuscripts collection (~22,000
 : elements), a per-distinct-institution exptit:printTitleID lookup, and
 : a nested collection/id extraction across every manuscript (~20,000
 : ids). Against a collection() call that can't use a range index for a
 : "contains" test, so the cost is paid per cache generation rather than
 : per request.
 :
 : @return the institution divs, ordered by title then institution ref
 :)
declare %private function listIds:body() as element(div)* {
	let $repos := collection($config:data-rootMS)//t:repository[contains(@ref, "INS")][not(ends-with(@ref, "IHA"))][not(
		@ref eq "INS0004HMML"
	)]
	let $by-ref := listIds:bucket-by($repos, function ($repo) { string($repo/@ref) })
	for $rID in map:keys($by-ref)
	let $tit := try { exptit:printTitleID($rID) } catch * { "no title" }
	order by ($tit, $rID)
	return <div class="w3-container">
		<h1>{ $tit } ({ $rID })</h1>
		{
			let $entries :=
				for $repo in $by-ref($rID)
				return listIds:entry($repo)
			let $by-collection := listIds:bucket-by($entries, function ($entry) { $entry?collection })
			for $collection in map:keys($by-collection)
			order by $collection
			return <div class="w3-row">
				<h2>{ $collection }</h2>
				<div class="w3-container">
					{
						for $entry in $by-collection($collection)
						let $id := $entry?id
						order by $id
						return <div class="w3-row"><b>{ $id }</b></div>
					}
				</div>
			</div>
		}
	</div>
};

(:~
 : Cached wrapper around listIds:body() - deterministic given current
 : corpus state, so recomputing it on every request pays that cost every
 : time. Same TTL-cache idiom as q:max-folia/q:max-written-lines
 : (modules/queries.xqm's $q:CORPUS-STATS-CACHE). Deliberately does NOT
 : wrap listIds:getlist's whole page: nav:barNew() renders per-session
 : login state (locallogin:loginNew()), which a shared cache would leak
 : across sessions.
 :
 : @return the cached (or freshly computed and cached) institution divs
 :)
declare function listIds:cached-body() as element(div)* {
	let $ensureCache := cache:create($listIds:CACHE, map {"maximumSize": 1, "expireAfterWrite": $listIds:CACHE-TTL})
	let $cached := cache:get($listIds:CACHE, "body")
	return if (exists($cached)) then
		$cached
	else
		let $body := listIds:body()
		let $store := cache:put($listIds:CACHE, "body", $body)
		return $body
};

declare function listIds:getlist($request as map(*)) {
	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
			<script src="resources/js/analytics.js" type="text/javascript" />
			<link href="resources/images/favicon.ico" rel="shortcut icon" />
			<meta content="width=device-width, initial-scale=1.0" name="viewport" />
			<title>list of ids</title>
			{ scriptlinks:scriptStyle() }
		</head>
		<body id="body">
			{ nav:barNew() }
			{ nav:modalsNew() }
			<p
				class="w3-large"
			>Please note that this list excludes the IslHornAfr manuscripts and EMML manuscripts. The ids of the first group are all made of the IHA sigla followed by a progressive number. The ids of the EMML manuscripts are made of the sigla EMML follwed by a progressive number.</p>
			{ listIds:cached-body() }
		</body>
	</html>
};
