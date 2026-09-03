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
 : One <div> per institution, each listing its manuscripts' @xml:id
 : grouped by collection - the expensive part of /listIds: an unindexed
 : scan of every t:repository in the manuscripts collection (~22,000
 : elements), a per-distinct-institution exptit:printTitleID lookup, and
 : a nested collection/id extraction across every manuscript (~20,000
 : ids). Measured 14-22s under load, against a collection() call that
 : can't use a range index for a "contains" test.
 :
 : @return the institution divs, unsorted by caller expectations beyond @order by $tit
 :)
declare %private function listIds:body() as element(div)* {
	let $allrepos := collection($config:data-rootMS)//t:repository[contains(@ref, "INS")]
	let $repos := $allrepos[not(ends-with(@ref, "IHA"))][not(@ref eq "INS0004HMML")]
	for $repo in $repos
	let $ref := $repo/@ref
	group by $ref
	let $rID := string($ref)
	let $tit := try { exptit:printTitleID($rID) } catch * { "no title" }
	order by $tit
	return <div class="w3-container">
		<h1>{ $tit } ({ $rID })</h1>
		{
			for $rep in $repo
			let $collection := if ($rep/following-sibling::t:collection) then
				$rep/following-sibling::t:collection[1]/text()
			else
				"no specific collection"
			group by $collection
			order by $collection
			return <div class="w3-row">
				<h2>{ $collection }</h2>
				<div class="w3-container">
					{
						let $ids :=
							for $reC in $rep
							let $root := root($reC)
							let $id := string($root/t:TEI/@xml:id)
							return $id
						for $i in $ids
						order by $i
						return <div class="w3-row"><b>{ $i }</b></div>
					}
				</div>
			</div>
		}
	</div>
};

(:~
 : Cached wrapper around listIds:body() - deterministic given current
 : corpus state, so recomputing it on every request pays that ~14-22s
 : cost every time. Same TTL-cache idiom as q:max-folia/q:max-written-lines
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
