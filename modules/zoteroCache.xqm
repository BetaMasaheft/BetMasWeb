xquery version "3.1" encoding "UTF-8";

(:~
 : EthioStudies citation lookups and live Zotero fallback.
 : Always use doc() on a named file: several citation XML files share @tag
 : and collection() would mix HLCEES with with-url-doi.
 :
 : High-level helpers (zc:full, zc:short, zc:full-url-doi) are the shared
 : entry points for templating, Roaster HTML, and the versions proxy.
 :)
module namespace zc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/zc";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace templates = "http://exist-db.org/xquery/templates";

declare variable $zc:root := "/db/apps/EthioStudies/";

declare variable $zc:zotero := "https://api.zotero.org/groups/358366/items";

declare variable $zc:style-main := "hiob-ludolf-centre-for-ethiopian-studies";

declare variable $zc:style-url-doi := "hiob-ludolf-centre-for-ethiopian-studies-with-url-doi";

(: try/catch so a missing/unreadable cache file falls back to live Zotero
instead of breaking the caller - the EthioStudies xar this reads from is an
optional dependency (see BetaMasaheft/bibliography#18, BetMas#149) :)
declare function zc:bib($file as xs:string, $tag as xs:string) {
	try { doc($zc:root || $file)//*[@tag = $tag]//*:div[@class = "csl-entry"] } catch * { () }
};

(: (...)[1]: @tag is meant to be unique within one file (verified against the
real citation files - no duplicates today), but is reused across files, so
guard against a future duplicate silently concatenating two citations'
content together with no separator :)
declare function zc:cit($file as xs:string, $tag as xs:string) {
	try { (doc($zc:root || $file)//*[@tag = $tag])[1]/node() } catch * { () }
};

(:~
 : Timeline historically used bm_…; EthioStudies keys use bm:.
 :)
declare function zc:normalize-tag($tag as xs:string) as xs:string {
	if (starts-with($tag, "bm_")) then
		"bm:" || substring-after($tag, "bm_")
	else
		$tag
};

declare function zc:html-string($nodes as node()*) as xs:string {
	serialize($nodes, map {"method": "html", "html-version": 5.0, "indent": false()})
};

declare %private function zc:live-bib($tag as xs:string, $style as xs:string) as node()* {
	try {
		let $url := concat(
			$zc:zotero,
			"?tag=",
			$tag,
			"&amp;format=bib&amp;locale=en-GB&amp;style=",
			$style,
			"&amp;linkwrap=1"
		)
		let $request := <http:request href="{ xs:anyURI($url) }" method="GET" />
		let $data := http:send-request($request)[2]
		return $data//*:div[@class = "csl-entry"]
	} catch * { util:log("INFO", ("zc:live-bib failed for ", $tag, $err:description)), () }
};

declare %private function zc:live-cit($tag as xs:string, $style as xs:string) as xs:string? {
	try {
		let $url := concat($zc:zotero, "?tag=", $tag, "&amp;include=citation&amp;locale=en-GB&amp;style=", $style)
		let $req := <http:request href="{ xs:anyURI($url) }" http-version="1.1" method="GET" />
		let $raw := http:send-request($req)[2]
		let $decoded := util:base64-decode($raw)
		let $parsed := parse-json($decoded)
		let $cit := ($parsed?1?citation, $parsed?*?citation)[1]
		return if (exists($cit)) then
			replace(replace(string($cit), "&lt;span&gt;", ""), "&lt;/span&gt;", "")
		else (
		)
	} catch * { util:log("INFO", ("zc:live-cit failed for ", $tag, $err:description)), () }
};

(:~
 : Full bibliography HTML (main HLCEES). Cache first, live Zotero on miss.
 :)
declare function zc:full($tag as xs:string) as node()* {
	let $t := zc:normalize-tag($tag)
	let $cached := zc:bib("citations.xml", $t)
	return if (exists($cached)) then
		$cached
	else
		zc:live-bib($t, $zc:style-main)
};

(:~
 : Full bibliography HTML (HLCEES with URL/DOI).
 :)
declare function zc:full-url-doi($tag as xs:string) as node()* {
	let $t := zc:normalize-tag($tag)
	let $cached := zc:bib("citations-url-doi.xml", $t)
	return if (exists($cached)) then
		$cached
	else
		zc:live-bib($t, $zc:style-url-doi)
};

(:~
 : Short in-text citation (main HLCEES). Returns a string.
 :)
declare function zc:short($tag as xs:string) as xs:string? {
	let $t := zc:normalize-tag($tag)
	let $cached := zc:cit("citations-short-main.xml", $t)
	return if (exists($cached)) then
		normalize-space(string-join($cached!string(.), ""))
	else
		zc:live-cit($t, $zc:style-main)
};

(:~
 : Short citation with-url-doi style (for gfb:shortCit).
 :)
declare function zc:short-url-doi($tag as xs:string) as xs:string? {
	let $t := zc:normalize-tag($tag)
	let $cached := zc:cit("citations-short.xml", $t)
	return if (exists($cached)) then
		normalize-space(string-join($cached!string(.), ""))
	else
		zc:live-cit($t, $zc:style-url-doi)
};

(:~
 : Templating entry for static HTML (help.html). Uses data-template-tag.
 :)
declare %templates:wrap %templates:default("tag", "") function zc:html(
	$node as node(),
	$model as map(*),
	$tag as xs:string
) as node()* {
	zc:full($tag)
};

(:~
 : Prefer EthioStudies, then lists/bibliography.xml, then live Zotero.
 : Used by lists:biblRes (one page of hits only).
 :)
declare function zc:bibl-page-entry($tag as xs:string) as node()* {
	let $t := zc:normalize-tag($tag)
	let $from-cache := zc:bib("citations.xml", $t)
	return if (exists($from-cache)) then
		$from-cache
	else
		let $from-lists := try {
			doc("/db/apps/lists/bibliography.xml")//*:entry[@xml:id = $t]/*:reference/node()
		} catch * { () }
		return if (exists($from-lists)) then
			$from-lists
		else
			zc:live-bib($t, $zc:style-main)
};

declare %private function zc:version-item($item as map(*), $resolved as map(*)) as map(*) {
	let $version := $item?version
	let $source := $version?source
	let $ed := $source?ed
	return if (empty($ed) or not(matches(string($ed), "^bm[:_]"))) then
		$item
	else
		let $t := zc:normalize-tag(string($ed))
		let $editionHtml := (map:get($resolved, $t), string($ed))[1]
		return map {
			"version": map {"source": map:merge(($source, map {"editionHtml": $editionHtml})), "text": $version?text}
		}
};

(:~
 : Enrich a SPARQL versions payload: for each bm: edition tag, add editionHtml
 : (cache-first). Resolves each distinct tag once. Accepts array or sequence of
 : version maps from BetMasApi; always returns versions as an array for JS.
 :)
declare function zc:enrich-versions($payload as map(*)) as map(*) {
	if (not(map:contains($payload, "versions"))) then
		$payload
	else
		let $raw := $payload?versions
		let $seq := if ($raw instance of array(*)) then
			$raw?*
		else if ($raw instance of map(*) and map:contains($raw, "version")) then (
			$raw
		) else
			$raw
		let $tags := distinct-values(
			for $item in $seq
			let $ed := $item?version?source?ed
			where exists($ed) and matches(string($ed), "^bm[:_]")
			return zc:normalize-tag(string($ed))
		)
		let $resolved := if (empty($tags)) then
			map {}
		else
			map:merge(
				for $t in $tags
				let $html := zc:full($t)
				return map:entry(
					$t,
					if (exists($html)) then
						zc:html-string($html)
					else
						$t
				)
			)
		let $enriched :=
			for $item in $seq
			return if ($item instance of map(*)) then
				zc:version-item($item, $resolved)
			else
				$item
		return map:merge(($payload, map {"versions": array { $enriched }, "total": ($payload?total, count($enriched))[1]}))
};
