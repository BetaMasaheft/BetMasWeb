xquery version "3.1" encoding "UTF-8";

(:~
 : Which BetMasData collections a re-expand run should schedule.
 :
 : Reads the collections in this instance (xmldb:get-child-collections).
 : Does not walk TEI and does not expand. The HTTP entry is
 : expandShards:list, mounted by modules/routes.json at
 : GET /api/expand/shards.
 :
 : This module is the scheduler. expanded scripts/ci/discover-shards.sh
 : walks a git checkout and CI does not run it.
 : manuscripts/EMML is L2, `{corpus}/new` is not an ordinary L1 shard,
 : authority-files/new is never scheduled.
 :
 : GET /api/expand/deletions compares the expanded collection frozen in
 : this same image with BetMasData. Both were pinned in one betmas-data
 : build. The live corpus repos can move forward after that pin, so
 : BetMasData here is older than those repos and is not ahead of them.
 : A directory in this expanded tree and absent from this BetMasData was
 : already gone from source when the image was built. */new is not a
 : deletion. A child of a corpus that still exists is left to assemble.
 :
 : @see https://github.com/BetaMasaheft/expanded/issues/40
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
module namespace expandShards = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/expandShards";

import module namespace roaster = "http://e-editiones.org/roaster";

declare variable $expandShards:data-root := "/db/apps/BetMasData";

(: Same collection expand.xqm calls $expand:fullTEIcol-path. :)
declare variable $expandShards:expanded-root := "/db/apps/expanded";

(:~
 : l1 = one shard per child (EMML split, `new` skipped here).
 : root = the corpus collection itself.
 : reserve = `{corpus}/new` appended after the walk.
 :)
declare variable $expandShards:modes := map {
	"hybrid":
		map {
			"l1": ("works", "persons", "manuscripts", "places", "institutions"),
			"root": ("narratives", "studies", "authority-files", "corpora"),
			"reserve": ("works", "persons", "manuscripts", "places", "institutions")
		},
	"l1":
		map {
			"l1": ("works", "persons", "places", "institutions", "narratives", "studies", "authority-files", "manuscripts"),
			"root": ("corpora"),
			"reserve": ("works", "persons", "manuscripts", "places", "institutions", "narratives", "studies")
		},
	"matrix":
		map {
			"l1": (),
			"root":
				(
					"works",
					"persons",
					"places",
					"institutions",
					"narratives",
					"studies",
					"authority-files",
					"manuscripts",
					"corpora"
				),
			"reserve": ()
		}
};

declare variable $expandShards:ignored-child := ("build", ".git", ".github");

declare variable $expandShards:emml := "manuscripts/EMML";

(:~
 : GET /api/expand/shards?mode=hybrid&amp;collection=
 : DBA or Editors. JSON body: { "mode": "...", "shards": ["works/1-1000", ...] }.
 :)
declare function expandShards:list($request as map(*)) as map(*) {
	expandShards:respond($request, expandShards:caller-allowed())
};

(:~
 : GET /api/expand/deletions?mode=hybrid
 : Shard paths present in this image's expanded collection and absent from
 : this image's BetMasData. */new is never returned.
 :)
declare function expandShards:deletions($request as map(*)) as map(*) {
	expandShards:deletions($request, expandShards:caller-allowed(), $expandShards:data-root, $expandShards:expanded-root)
};

declare function expandShards:deletions(
	$request as map(*),
	$allowed as xs:boolean,
	$data-root as xs:string,
	$expanded-root as xs:string
) as map(*) {
	if (not($allowed)) then
		expandShards:problem(403, "expand deletions requires an authenticated DBA or Editors user")
	else
		let $mode := expandShards:mode-of($request)
		return try {
			let $removed := expandShards:removed($mode, $data-root, $expanded-root)
			return roaster:response(200, "application/json", map {"mode": $mode, "removed": array { $removed }})
		} catch expandShards:BAD_MODE { expandShards:problem(400, $err:description) }catch expandShards:MISSING {
			expandShards:problem(404, $err:description)
		}
};

(:~
 : Same as list, with the auth decision passed in so tests can cover 403
 : without switching the eXist user.
 :)
declare function expandShards:respond($request as map(*), $allowed as xs:boolean) as map(*) {
	expandShards:respond($request, $allowed, $expandShards:data-root)
};

(:~
 : $data-root is /db/apps/BetMasData in production. Tests pass a fixture.
 :)
declare function expandShards:respond($request as map(*), $allowed as xs:boolean, $data-root as xs:string) as map(*) {
	if (not($allowed)) then
		expandShards:problem(403, "expand shards requires an authenticated DBA or Editors user")
	else
		let $mode := expandShards:mode-of($request)
		let $only := expandShards:query-param($request, "collection")
		return try {
			let $shards := expandShards:paths($mode, $only, $data-root)
			return roaster:response(200, "application/json", map {"mode": $mode, "shards": array { $shards }})
		} catch expandShards:BAD_MODE { expandShards:problem(400, $err:description) }catch expandShards:BAD_SHARD {
			expandShards:problem(400, $err:description)
		}catch expandShards:MISSING { expandShards:problem(404, $err:description) }
};

(:~
 : Relative shard paths. $collection empty means the whole mode.
 : The 3-arg form takes a fixture root.
 :
 : @param $mode hybrid, l1, or matrix
 : @param $collection relative path, absolute BetMasData URI, or empty
 : @param $data-root absolute collection
 :)
declare function expandShards:paths($mode as xs:string, $collection as xs:string?) as xs:string* {
	expandShards:paths($mode, $collection, $expandShards:data-root)
};

declare function expandShards:paths(
	$mode as xs:string,
	$collection as xs:string?,
	$data-root as xs:string
) as xs:string* {
	let $root := replace(normalize-space($data-root), "/+$", "")
	let $only := expandShards:relative($collection)
	return if (not(map:contains($expandShards:modes, $mode))) then
		error(xs:QName("expandShards:BAD_MODE"), "Unknown mode: " || $mode || " (expected hybrid, l1, or matrix)")
	else if ($only = "authority-files/new") then
		error(xs:QName("expandShards:BAD_SHARD"), "Refusing sourceless orphan shard filter: authority-files/new")
	else if (not(xmldb:collection-available($root))) then
		error(xs:QName("expandShards:MISSING"), "collection not found: " || $root)
	else if ($only ne "") then
		expandShards:one($root, $only)
	else
		expandShards:by-mode($root, $expandShards:modes($mode))
};

declare %private function expandShards:caller-allowed() as xs:boolean {
	let $user := sm:id()//sm:real/sm:username/string()
	let $groups := sm:get-user-groups($user)
	return sm:is-authenticated() and $user ne "guest" and (sm:is-dba($user) or $groups = "Editors")
};

declare %private function expandShards:problem($status as xs:integer, $message as xs:string) as map(*) {
	roaster:response($status, "application/json", map {"error": $message})
};

declare %private function expandShards:query-param($request as map(*), $name as xs:string) as xs:string {
	let $params := if (map:contains($request, "parameters")) then
		$request?parameters
	else
		map {}
	let $raw := if ($params instance of map(*) and map:contains($params, $name)) then
		$params($name)
	else
		""
	let $one := if ($raw instance of array(*)) then
		$raw?1
	else
		$raw[1]
	return normalize-space(string($one))
};

declare %private function expandShards:mode-of($request as map(*)) as xs:string {
	let $mode := expandShards:query-param($request, "mode")
	return if ($mode = "") then
		"hybrid"
	else
		$mode
};

(:~
 : Path relative to BetMasData. Accepts a relative path, a leading ./,
 : a trailing slash, or an absolute /db/apps/BetMasData/... URI.
 :)
declare %private function expandShards:relative($collection as xs:string?) as xs:string {
	let $raw := replace(replace(normalize-space(string($collection)), "^(\./|/)+", ""), "/+$", "")
	let $prefix := substring-after($expandShards:data-root, "/") || "/"
	return if (starts-with($raw, $prefix)) then
		substring-after($raw, $prefix)
	else
		$raw
};

declare %private function expandShards:child-names($col as xs:string) as xs:string* {
	if (not(xmldb:collection-available($col))) then (
	) else
		for $name in xmldb:get-child-collections($col)
		where not($name = $expandShards:ignored-child)
		order by $name
		return $name
};

declare %private function expandShards:emml-buckets($root as xs:string) as xs:string* {
	let $kids := expandShards:child-names($root || "/" || $expandShards:emml)
	return if (empty($kids)) then
		$expandShards:emml
	else
		for $name in $kids
		return $expandShards:emml || "/" || $name
};

declare %private function expandShards:l1-corpus($root as xs:string, $corpus as xs:string) as xs:string* {
	if (not(xmldb:collection-available($root || "/" || $corpus))) then (
	) else
		for $name in expandShards:child-names($root || "/" || $corpus)
		return if ($name = "new") then (
		) else if ($corpus = "manuscripts" and $name = "EMML") then
			expandShards:emml-buckets($root)
		else
			$corpus || "/" || $name
};

declare %private function expandShards:if-present($root as xs:string, $name as xs:string) as xs:string? {
	if (xmldb:collection-available($root || "/" || $name)) then
		$name
	else (
	)
};

declare %private function expandShards:reservations($root as xs:string, $corpora as xs:string*) as xs:string* {
	for $corpus in $corpora
	where xmldb:collection-available($root || "/" || $corpus || "/new")
	return $corpus || "/new"
};

declare %private function expandShards:by-mode($root as xs:string, $spec as map(*)) as xs:string* {
	(
		for $corpus in $spec?l1
		return expandShards:l1-corpus($root, $corpus),
		for $corpus in $spec?root
		return expandShards:if-present($root, $corpus),
		expandShards:reservations($root, $spec?reserve)
	)
};

declare %private function expandShards:one($root as xs:string, $only as xs:string) as xs:string* {
	if ($only = $expandShards:emml) then
		if (not(xmldb:collection-available($root || "/" || $expandShards:emml))) then
			error(xs:QName("expandShards:MISSING"), "collection not found: " || $root || "/" || $expandShards:emml)
		else
			expandShards:emml-buckets($root)
	else if (not(xmldb:collection-available($root || "/" || $only))) then
		error(xs:QName("expandShards:MISSING"), "collection not found: " || $root || "/" || $only)
	else
		$only
};

(:~
 : Shard paths in $expanded-root whose BetMasData collection is gone.
 : A corpus that still exists contributes nothing: its missing children
 : are removed by assemble from the export. A corpus that is gone
 : contributes its children except `new`, so a reservation folder survives.
 :)
declare function expandShards:removed(
	$mode as xs:string,
	$data-root as xs:string,
	$expanded-root as xs:string
) as xs:string* {
	let $data := replace(normalize-space($data-root), "/+$", "")
	let $expanded := replace(normalize-space($expanded-root), "/+$", "")
	return if (not(map:contains($expandShards:modes, $mode))) then
		error(xs:QName("expandShards:BAD_MODE"), "Unknown mode: " || $mode || " (expected hybrid, l1, or matrix)")
	else if (not(xmldb:collection-available($data))) then
		error(xs:QName("expandShards:MISSING"), "collection not found: " || $data)
	else if (not(xmldb:collection-available($expanded))) then (
	) else
		expandShards:removed-by-mode($data, $expanded, $expandShards:modes($mode))
};

declare %private function expandShards:removed-by-mode(
	$data as xs:string,
	$expanded as xs:string,
	$spec as map(*)
) as xs:string* {
	(
		for $corpus in $spec?l1
		return expandShards:removed-l1($data, $expanded, $corpus),
		for $corpus in $spec?root
		return expandShards:removed-root($data, $expanded, $corpus)
	)
};

declare %private function expandShards:removed-l1(
	$data as xs:string,
	$expanded as xs:string,
	$corpus as xs:string
) as xs:string* {
	for $path in expandShards:l1-corpus($expanded, $corpus)
	where not(xmldb:collection-available($data || "/" || $path))
	return $path
};

declare %private function expandShards:removed-root(
	$data as xs:string,
	$expanded as xs:string,
	$corpus as xs:string
) as xs:string* {
	if (xmldb:collection-available($data || "/" || $corpus)) then (
	) else if (not(xmldb:collection-available($expanded || "/" || $corpus))) then (
	) else
		let $kids := expandShards:child-names($expanded || "/" || $corpus)[not(. = "new")]
		return if (exists($kids)) then
			for $name in $kids
			return $corpus || "/" || $name
		else if (xmldb:collection-available($expanded || "/" || $corpus || "/new")) then (
		) else
			$corpus
};
