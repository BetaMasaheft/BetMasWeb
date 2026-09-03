xquery version "3.1" encoding "UTF-8";

(:~
 : this function makes a call to wikidata API
 :)
module namespace wiki = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/wiki";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace cache = "http://exist-db.org/xquery/cache";

(: Live Wikidata lookups are the dominant cost of any page listing several
people with a wd: sameAs id (e.g. /BetMas/api/academics: 37 sequential
external calls, ~580ms each) - a VIAF id is effectively permanent once
assigned, so a long TTL is safe. Same idiom as iiifut:CANVAS-CACHE. :)
declare variable $wiki:VIAF-CACHE := "wikidata-viaf";

declare variable $wiki:VIAF-CACHE-TTL := 604800;

(:~
 : Live Wikidata lookup for a Q-item's VIAF id (P214 claim) - the expensive,
 : uncached part of wiki:wikitable. Kept separate from the caching wrapper
 : so the wrapper itself can be tested with a stub fetcher, no network
 : involved.
 :
 : @param $Qitem a Wikidata Q-item id (e.g. "Q123456")
 : @return the VIAF id if the entity has one, empty sequence otherwise
 :)
declare %private function wiki:fetch-viaf-id($Qitem as xs:string) as xs:string? {
	let $api-url := concat("https://www.wikidata.org/wiki/Special:EntityData/", $Qitem, ".json")
	let $response := try {
		let $request := <http:request href="{ $api-url }" method="GET">
			<http:header name="User-Agent" value="betamasaheft.eu (info@betamasaheft.eu)" />
		</http:request>
		return http:send-request($request)
	} catch * { () }

	let $json := if ($response[1]/@status = "200") then (
		util:base64-decode(string-join($response))
	) else (
	)

	let $json-doc := if ($json) then
		parse-json($json)
	else (
	)
	let $claims := $json-doc?entities?($Qitem)?claims?P214
	return if (exists($claims)) then
		let $firstClaim := $claims?1
		return $firstClaim?mainsnak?datavalue?value
	else (
	)
};

(:~
 : Cache-first VIAF lookup, cache miss/negative-cache/fetcher-injection
 : shape shared with iiifut:get-first-canvas. $fetch is injected so this
 : wrapper is testable without a live network call - production code
 : always passes wiki:fetch-viaf-id#1.
 :
 : @param $Qitem a Wikidata Q-item id
 : @param $fetch the live-lookup function to call on a cache miss
 : @return the cached or freshly-fetched VIAF id, empty sequence if none
 :)
declare function wiki:viaf-lookup-cached(
	$Qitem as xs:string,
	$fetch as function (xs:string) as xs:string?
) as xs:string? {
	let $ensureCache := cache:create($wiki:VIAF-CACHE, map {"type": "lru", "size": 2000, "ttl": $wiki:VIAF-CACHE-TTL})
	let $cached := cache:get($wiki:VIAF-CACHE, $Qitem)
	return if (exists($cached)) then
		if ($cached eq "") then (
		) else
			$cached
	else
		let $fresh := $fetch($Qitem)
		let $store := cache:put(
			$wiki:VIAF-CACHE,
			$Qitem,
			if (exists($fresh)) then
				$fresh
			else
				""
		)
		return $fresh
};

declare function wiki:wikitable($Qitem as xs:string) as element() {
	let $viaf-id := wiki:viaf-lookup-cached($Qitem, wiki:fetch-viaf-id#1)
	let $WDurl := concat("https://www.wikidata.org/wiki/", $Qitem)
	return if (exists($viaf-id) and string-length($viaf-id) > 0) then
		<div class="w3-responsive">
			<table class="w3-table w3-hoverable">
				<tbody>
					<tr><td>WikiData Item</td><td><a href="{ $WDurl }" target="_blank">{ $Qitem }</a></td></tr>
					<tr>
						<td>VIAF ID</td>
						<td><a href="https://viaf.org/viaf/{ $viaf-id }" target="_blank">{ $viaf-id }</a></td>
					</tr>
				</tbody>
			</table>
		</div>
	else
		<div class="w3-responsive">
			<table class="w3-table w3-hoverable">
				<tbody><tr><td>WikiData Item</td><td><a href="{ $WDurl }" target="_blank">{ $Qitem }</a></td></tr></tbody>
			</table>
		</div>
};
