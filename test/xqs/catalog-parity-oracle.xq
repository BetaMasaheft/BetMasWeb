xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";

import module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog.xqm";

declare option output:method "json";
declare option output:media-type "application/json";
declare option exist:optimize "enable=no";

declare variable $backend-a external := "legacy";

declare variable $backend-b external := "catalog";

declare variable $effective-backend-a := try { request:get-parameter("backend-a", $backend-a) } catch * { $backend-a };

declare variable $effective-backend-b := try { request:get-parameter("backend-b", $backend-b) } catch * { $backend-b };

(: Optional cap for local/CI smoke. Empty or non-positive = full id space. :)
declare variable $limit external := ();

declare variable $effective-limit := try {
	let $p := request:get-parameter("limit", ())
	return if (exists($p) and $p castable as xs:integer) then
		xs:integer($p)
	else if (exists($limit) and $limit castable as xs:integer) then
		xs:integer($limit)
	else (
	)
} catch * { () };

declare variable $reviewed-path := "/db/apps/BetMasWeb/test/catalog-reviewed-mismatches.xml";

declare variable $reviewed := if (doc-available($reviewed-path)) then
	doc($reviewed-path)/reviewed-mismatches/mismatch
else (
);

(:~
 : Resolves one case through one backend. `legacy` reaches the frozen
 : pre-Phase-2 chain in catalog-legacy.xqm, `catalog` this phase's own
 : resolution — two distinct implementations, which is the only reason
 : comparing them is informative. A backend that raises is reported as an
 : ERROR value so one bad identifier cannot silence the whole run.
 :)
declare function local:resolve($backend as xs:string, $kind as xs:string, $key as xs:string) as xs:string {
	if (not($backend = ("legacy", "catalog"))) then
		error(xs:QName("oracle:UNKNOWN_BACKEND"), "Unknown oracle backend: " || $backend)
	else
		try {
			if ($kind = "title") then
				normalize-space(
					string-join(
						for $item in catalog:label($key, $backend)
						return string($item),
						" "
					)
				)
			else
				normalize-space(serialize(catalog:bibl($key, $backend)))
		} catch * { "ERROR " || $err:code || ": " || $err:description }
};

declare function local:valid-review($review as element(mismatch)?) as xs:boolean {
	exists($review[@triage = ("better", "worse", "neutral")])
};

let $title-ids := distinct-values(
	(
		collection("/db/apps/expanded")/t:TEI/@xml:id/string(),
		collection("/db/apps/expanded")//t:title[contains(@corresp, "#")]/@corresp/string(),
		doc("/db/apps/lists/deleted.xml")//t:item/string()
	)
)
let $bibliography-ids := distinct-values(
	collection("/db/apps/expanded")//t:ptr[starts-with(@target, "bm:")]/@target/string()
)
let $all-cases := (
	for $key in $title-ids
	return map {"kind": "title", "key": $key},
	for $key in $bibliography-ids
	return map {"kind": "bibliography", "key": $key}
)
let $cases := if (exists($effective-limit) and $effective-limit gt 0) then
	subsequence($all-cases, 1, $effective-limit)
else
	$all-cases
let $mismatches :=
	for $case in $cases
	let $kind := $case?kind
	let $key := $case?key
	let $a := local:resolve($effective-backend-a, $kind, $key)
	let $b := local:resolve($effective-backend-b, $kind, $key)
	where $a ne $b
	let $review := $reviewed[@kind = $kind][@key = $key][1]
	return map {
		"kind": $kind,
		"key": $key,
		"backendA": $a,
		"backendB": $b,
		"triage": string($review/@triage),
		"reviewed": local:valid-review($review),
		"note": string($review/@note)
	}
let $unreviewed := $mismatches[not(.?reviewed)]
let $invalid-reviewed-entries := $reviewed[not(local:valid-review(.))]
let $triage-validation-passed := every
	$review in
	(<mismatch triage="better" />, <mismatch triage="worse" />, <mismatch triage="neutral" />) satisfies
	local:valid-review($review) and
		not(local:valid-review(<mismatch />)) and
		not(local:valid-review(<mismatch triage="invalid" />))
return serialize(
	map {
		"backendA": $effective-backend-a,
		"backendB": $effective-backend-b,
		"comparisonMode": "resolved-values",
		"limit": if (exists($effective-limit)) then $effective-limit else (),
		"titleCases": count($title-ids),
		"bibliographyCases": count($bibliography-ids),
		"comparedCases": count($cases),
		"resolutionCallsA": count($cases),
		"resolutionCallsB": count($cases),
		"mismatchCount": count($mismatches),
		"unreviewedCount": count($unreviewed),
		"invalidReviewedEntries": count($invalid-reviewed-entries),
		"triageValidationPassed": $triage-validation-passed,
		"mismatches": array { $mismatches }
	},
	map {"method": "json"}
)
