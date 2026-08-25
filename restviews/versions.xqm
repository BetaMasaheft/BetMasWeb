xquery version "3.1" encoding "UTF-8";

(:~
 : Parallel-versions proxy: call BetMasApi SPARQL versions, enrich
 : bm-tagged edition fields with EthioStudies HTML (cache-first), return JSON.
 : Web-only path (not Api's /api/SPARQL/versions/...) so enrichment cannot be
 : skipped by hitting BetMasApi's Roaster directly.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/82
 :)
module namespace versions = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/versions";

import module namespace crossapp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/crossapp" at "../modules/crossapp.xqm";
import module namespace zc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/zc" at "../modules/zoteroCache.xqm";

declare function versions:parallel($request as map(*)) {
	(:
	 : crossapp:resolve always returns a callable for registered ops (501 stub
	 : when BetMasApi is missing) - never the empty sequence
	 :)
	let $fn := crossapp:resolve("apisparql:sparqlQueryVersions")
	let $raw := $fn($request)
	let $payload := if ($raw instance of map(*)) then
		$raw
	else
		map {"info": "unexpected versions response"}
	return map:merge((zc:enrich-versions($payload), map {"enrichedBy": "BetMasWeb"}))
};
