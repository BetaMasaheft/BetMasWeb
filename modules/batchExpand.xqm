xquery version "3.1" encoding "UTF-8";

(:~
 : Parametrized batch expand driver for CI / makeExpand.
 : Imports canonical BetMasWeb expand.xqm (not frozen BetMas / Service copies).
 :
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
module namespace batchExpand = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/batchExpand";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "xmldb:exist:///db/apps/BetMasWeb/modules/expand.xqm";

declare variable $batchExpand:data-root := "/db/apps/BetMasData";

(:~
 : True if $col is the BetMasData root or a path strictly under it, with no
 : `..` / `.` segments (rejects prefix tricks and traversal).
 :)
declare %private function batchExpand:is-allowed-collection($col as xs:string) as xs:boolean {
	let $root := $batchExpand:data-root
	let $under := $col = $root or starts-with($col, $root || "/")
	let $segments := tokenize($col, "/")
	return $under and empty($segments[. = ("..", ".")])
};

(:~
 : Expand every TEI under $collectionUri into /db/apps/expanded/...
 : Refuses empty / missing / out-of-tree collection (no silent full-corpus run).
 :
 : @param $collectionUri e.g. /db/apps/BetMasData/works/1-1000
 : @return summary "expanded N file(s) in T seconds"
 :)
declare function batchExpand:expandCollection($collectionUri as xs:string?) as xs:string {
	let $col := normalize-space($collectionUri)
	return if ($col = "" or empty($collectionUri)) then
		error(xs:QName("batchExpand:EMPTY"), "collection parameter is required")
	else if (not(batchExpand:is-allowed-collection($col))) then
		error(
			xs:QName("batchExpand:BAD_ROOT"),
			"collection must be under " || $batchExpand:data-root || " without .. segments, got: " || $col
		)
	else if (not(xmldb:collection-available($col))) then
		error(xs:QName("batchExpand:MISSING"), "collection not found: " || $col)
	else
		let $context := collection($col)//t:TEI
		let $t0 := util:system-time()
		let $_ :=
			for $file in $context
			return batchExpand:expandOne($file)
		let $secs := (util:system-time() - $t0) div xs:dayTimeDuration("PT1S")
		return "expanded " || count($context) || " file(s) in " || $secs || " seconds"
};

declare %private function batchExpand:expandOne($file as element(t:TEI)) {
	let $xmlid := $file/@xml:id
	let $start-time := util:system-time()
	let $filepath := base-uri($file)
	let $expanded := expand:file($filepath)
	let $file-name := tokenize($filepath, "/")[last()]
	let $collection := replace(
		replace(
			substring($filepath, 1, string-length($filepath) - string-length($file-name)),
			"/BetMasData/",
			"/expanded/"
		),
		"/+$",
		""
	)
	let $_mk := if (xmldb:collection-available($collection)) then (
	) else
		expand:create-collections($collection || "/")
	let $_remove := batchExpand:removeDuplicates($collection, $xmlid)
	let $_store := batchExpand:storeDoc($collection, $file-name, $expanded)
	let $_perm := batchExpand:setPermissions($collection || "/" || $file-name)
	let $runtime-ms := ((util:system-time() - $start-time) div xs:dayTimeDuration("PT1S")) * 1000
	return util:log(
		"INFO",
		"stored " || $file-name || " into " || $collection || " in " || $runtime-ms || " milliseconds"
	)
};

declare %private function batchExpand:removeDuplicates($collection-uri as xs:string, $xmlid) {
	let $existings := collection($collection-uri)//id($xmlid)[self::t:TEI or ancestor-or-self::t:TEI]
	let $teis := $existings/ancestor-or-self::t:TEI
	return if (empty($teis)) then
		util:log("info", " no other file with id " || $xmlid)
	else
		for $existing in $teis
		let $filebase := base-uri($existing)
		let $filename := tokenize($filebase, "/")[last()]
		let $filecoll := replace(substring($filebase, 1, string-length($filebase) - string-length($filename)), "/$", "")
		let $_ := try { xmldb:remove($filecoll, $filename) } catch * { util:log("info", $err:description) }
		return util:log("info", "removed " || $filebase)
};

declare %private function batchExpand:storeDoc(
	$collection-uri as xs:string,
	$file-name as xs:string,
	$file as item()
) as xs:string {
	try {
		let $stored := xmldb:store($collection-uri, $file-name, $file)
		return if (empty($stored) or string($stored) = "") then
			error(xs:QName("batchExpand:STORE"), "xmldb:store returned empty for " || $collection-uri || "/" || $file-name)
		else
			string($stored)
	} catch batchExpand:STORE { error($err:code, $err:description) }catch * {
		error(
			xs:QName("batchExpand:STORE"),
			"xmldb:store failed for " || $collection-uri || "/" || $file-name || ": " || $err:description
		)
	}
};

declare %private function batchExpand:setPermissions($stored as xs:string) {
	let $uri := xs:anyURI($stored)
	(: Cataloguers may be absent in bare CI images; chmod must still apply. :)
	let $_grp := try { sm:chgrp($uri, "Cataloguers") } catch * { util:log("info", $err:description) }
	return sm:chmod($uri, "rwxrwxr-x")
};
