xquery version "3.1" encoding "UTF-8";

(:~
 : External place-label resolution for the catalog contract: cache lookup,
 : the maintained placeNamesLabels list, and — only on a miss — an interim
 : HTTP fetch from GeoNames, Pleiades or Wikidata whose result is written to
 : a process-local cache instead of the database. Both catalog backends and
 : every consumer (Web and API) go through here, so wd:/gn:/pleiades: labels
 : cannot diverge between them. The HTTP fallback disappears with the Phase 3
 : place-label artifact.
 :)
module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-places";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace feed = "http://www.w3.org/2005/Atom";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace cache = "http://exist-db.org/xquery/cache";

declare variable $places:CACHE := "catalog-place-labels";

declare variable $places:list := doc("/db/apps/lists/placeNamesLabels.xml");

declare %private function places:cache-name() as xs:string {
	let $ensure := cache:create($places:CACHE, map {"maximumSize": 10000, "expireAfterWrite": 86400})
	return $places:CACHE
};

(:~
 : True for the identifier shapes that have no BetMasaheft record and must be
 : resolved against an external authority.
 :)
declare function places:external($ref as xs:string) as xs:boolean {
	matches($ref, "wd:Q\d+") or starts-with($ref, "gn:") or starts-with($ref, "pleiades:")
};

declare function places:remember($ref as xs:string, $name as item()*) {
	cache:put(places:cache-name(), $ref, $name)
};

declare function places:label($ref as xs:string) {
	let $cached := cache:get(places:cache-name(), $ref)
	return if (exists($cached)) then
		$cached
	else
		let $listed := ($places:list//t:item[@corresp = $ref])[1]/text()
		return if (exists($listed)) then
			$listed
		else if (places:external($ref)) then
			let $name := places:fetch($ref)
			let $remembered := places:remember($ref, $name)
			return $name
		else
			collection($config:data-root)/id($ref)//t:title[@type = "full"]/text()
};

declare function places:fetch($ref as xs:string) {
	if (starts-with($ref, "gn:")) then
		places:geonames($ref)
	else if (starts-with($ref, "pleiades:")) then
		places:pleiades($ref)
	else if (matches($ref, "wd:Q\d+")) then
		places:wikidata($ref)
	else (
	)
};

declare function places:geonames($string as xs:string) {
	let $gnid := substring-after($string, "gn:")
	let $xml-url := concat("http://api.geonames.org/get?geonameId=", $gnid, "&amp;username=betamasaheft")
	let $data := try {
		let $request := <http:request href="{ xs:anyURI($xml-url) }" method="GET" />
		return http:send-request($request)[2]
	} catch * { $err:description }
	return if ($data//toponymName) then
		$data//toponymName/text()
	else
		"no data from geonames"
};

declare function places:pleiades($string as xs:string) {
	let $plid := substring-after($string, "pleiades:")
	let $url := concat("https://pleiades.stoa.org/places/", $plid, "/atom")
	let $request := <http:request href="{ $url }" method="GET">
		<http:header name="Connection" value="close" />
	</http:request>
	let $title :=
		let $response := http:send-request($request)
		let $response-body := $response[2]
		return $response-body//feed:title
	return string($title[1])
};

declare function places:wikidata($ref as xs:string) {
	let $qid := substring-after($ref, "wd:")
	let $sparql := "SELECT * WHERE {
  wd:" || $qid || ' rdfs:label ?label .
  FILTER (langMatches( lang(?label), "EN" ) )
}'
	let $query := "https://query.wikidata.org/sparql?query=" || xmldb:encode-uri($sparql)
	let $req := try {
		let $request := <http:request href="{ xs:anyURI($query) }" method="GET" />
		return http:send-request($request)[2]
	} catch * { $err:description }
	return $req//sparql:result/sparql:binding[@name eq "label"]/sparql:literal[@xml:lang = "en"]/text()
};
