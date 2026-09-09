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
 : Expand every TEI under $collectionUri into /db/apps/expanded/... and prune
 : the mirrored subtree so it contains no resources absent from BetMasData
 : (mirror sync). Refuses empty / missing / out-of-tree collection (no silent
 : full-corpus run). Prune runs only after a successful expand pass.
 :
 : @param $collectionUri e.g. /db/apps/BetMasData/works/1-1000
 : @return summary "expanded N file(s) in T seconds"
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
declare function batchExpand:expandCollection($collectionUri as xs:string?) as xs:string {
	(: Trailing slash(es) stripped: left in, they shift tokenize's last
	   segment to "" and corrupt every downstream relative-path comparison
	   in prune-mirror (a double slash matches no real resource path). :)
	let $col := replace(normalize-space($collectionUri), "/+$", "")
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
		let $expanded-col := batchExpand:expanded-mirror($col)
		let $t0 := util:system-time()
		let $_ :=
			for $file in $context
			return batchExpand:expandOne($file)
		(: Fresh, not a pre-loop snapshot - avoids pruning a file a
		   concurrent writer stored here while this batch was expanding. :)
		let $pruned := batchExpand:prune-mirror($expanded-col, batchExpand:expected-relative-paths($col))
		let $_log := if ($pruned gt 0) then
			util:log("INFO", "pruned " || $pruned || " stale resource(s) from " || $expanded-col)
		else (
		)
		let $secs := (util:system-time() - $t0) div xs:dayTimeDuration("PT1S")
		return "expanded " || count($context) || " file(s) in " || $secs || " seconds"
};

(:~
 : Mirrored expanded collection URI for a BetMasData collection. Prefix
 : substitution, not a delimiter-anchored replace: the bare root has no
 : trailing slash for "/BetMasData/" to match, which used to alias back
 : onto the live source. Reuses $expand:fullTEIcol-path so the two roots
 : can't drift apart.
 : @param $data-col $batchExpand:data-root or a collection under it
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
declare function batchExpand:expanded-mirror($data-col as xs:string) as xs:string {
	$expand:fullTEIcol-path || substring-after($data-col, $batchExpand:data-root)
};

(:~
 : TEI paths (relative to $col) currently present in $col. Not memoized -
 : callers should call this right before using the result.
 : @param $col a BetMasData collection
 : @return distinct paths, relative to $col, of every t:TEI currently in it
 :)
declare function batchExpand:expected-relative-paths($col as xs:string) as xs:string* {
	distinct-values(
		for $file in collection($col)//t:TEI
		return substring-after(base-uri($file), $col || "/")
	)
};

(:~
 : True when $rel (path relative to a mirrored expanded collection) has a
 : path segment exactly `new` - ID-reservation stubs live under
 : `{corpus}/new/` and must survive parent-collection mirror prune.
 : @param $rel path relative to an expanded mirror collection
 : @return true if any path segment is the literal string "new"
 : @see https://github.com/BetaMasaheft/expanded/issues/31
 :)
declare %private function batchExpand:is-new-reservation-path($rel as xs:string) as xs:boolean {
	some $seg in tokenize($rel, "/") satisfies $seg = "new"
};

(:~
 : Remove resources under $expanded-col whose path (relative to
 : $expanded-col) is not in $expected. Ignores eXist collection metadata.
 : Refuses to prune when $expected is empty: a source collection that
 : exists but currently has zero TEI files is indistinguishable from a
 : sync race, and pruning would otherwise wipe the entire mirrored
 : subtree - the same "no silent full-corpus" guarantee expandCollection
 : already gives the top-level empty/missing checks.
 : Also refuses to prune when $expanded-col itself ends in `/new` (the
 : reservation folder), and never deletes descendants whose relative path
 : contains a `new` segment - those stubs are WIP id reservations, not
 : orphan expand leftovers.
 :
 : @param $expanded-col e.g. /db/apps/expanded/works/1-1000
 : @param $expected source paths (relative to the BetMasData collection
 : that mirrors to $expanded-col) that must remain
 : @return number of resources removed
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 : @see https://github.com/BetaMasaheft/expanded/issues/31
 :)
declare %private function batchExpand:prune-mirror($expanded-col as xs:string, $expected as xs:string*) as xs:integer {
	if (empty($expected)) then (
		util:log(
			"warn",
			"batchExpand:prune-mirror: skipping " || $expanded-col || " - source collection currently has 0 TEI file(s)"
		),
		0
	) else if (not(xmldb:collection-available($expanded-col))) then
		0
	else if (tokenize($expanded-col, "/")[last()] = "new") then (
		util:log("INFO", "batchExpand:prune-mirror: skipping reservation collection " || $expanded-col), 0
	) else
		let $expected-map := map:merge(
			for $e in $expected
			return map:entry($e, true())
		)
		let $removed :=
			for $path in batchExpand:descendant-resources($expanded-col)
			let $name := tokenize($path, "/")[last()]
			let $rel := substring-after($path, $expanded-col || "/")
			where not($name = "__contents__.xml") and
				not(map:contains($expected-map, $rel)) and
				not(batchExpand:is-new-reservation-path($rel))
			return try {
				let $parent := replace(substring($path, 1, string-length($path) - string-length($name)), "/$", "")
				let $_ := xmldb:remove($parent, $name)
				return 1
			} catch * { util:log("warn", "prune failed for " || $path || ": " || $err:description), () }
		return count($removed)
};

(:~
 : Absolute URIs of all resources under $col (recursive).
 :)
declare %private function batchExpand:descendant-resources($col as xs:string) as xs:string* {
	(
		for $r in xmldb:get-child-resources($col)
		return $col || "/" || $r,
		for $c in xmldb:get-child-collections($col)
		return batchExpand:descendant-resources($col || "/" || $c)
	)
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
	(: Cataloguers may be absent in bare CI images; chmod must still apply when possible. :)
	let $_grp := try { sm:chgrp($uri, "Cataloguers") } catch * { util:log("info", $err:description) }
	return try { sm:chmod($uri, "rwxrwxr-x") } catch * { util:log("info", $err:description) }
};
