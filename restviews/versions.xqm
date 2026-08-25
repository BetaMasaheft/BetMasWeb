xquery version "3.1" encoding "UTF-8";

(:~
 : Parallel-versions proxy: call BetMasApi SPARQL versions, enrich
 : bm-tagged edition fields with EthioStudies HTML (cache-first), return JSON.
 : Keeps citation ownership in BetMasWeb.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/82
 :)
module namespace versions = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/versions";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace errors = "http://e-editiones.org/roaster/errors";
import module namespace crossapp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/crossapp" at "../modules/crossapp.xqm";
import module namespace zc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/zc" at "../modules/zoteroCache.xqm";

declare function versions:parallel($request as map(*)) {
	let $fn := crossapp:resolve("apisparql:sparqlQueryVersions")
	return if (empty($fn)) then
		error(
			$errors:NOT_IMPLEMENTED,
			"BetMasApi SPARQL versions operation is not registered (apisparql:sparqlQueryVersions)"
		)
	else
		let $raw := $fn($request)
		let $payload := if ($raw instance of map(*)) then
			$raw
		else
			map {"info": "unexpected versions response"}
		return zc:enrich-versions($payload)
};
