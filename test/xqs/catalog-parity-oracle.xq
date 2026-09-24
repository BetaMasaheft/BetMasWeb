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

declare variable $backend-b external := "legacy";

declare variable $effective-backend-a := try { request:get-parameter("backend-a", $backend-a) } catch * { $backend-a };

declare variable $effective-backend-b := try { request:get-parameter("backend-b", $backend-b) } catch * { $backend-b };

declare variable $reviewed-path := "/db/apps/BetMasWeb/test/catalog-reviewed-mismatches.xml";

declare variable $reviewed := if (doc-available($reviewed-path)) then
	doc($reviewed-path)/reviewed-mismatches/mismatch
else (
);

declare function local:resolve-backend($backend as xs:string, $kind as xs:string, $key as xs:string) as xs:string {
	if ($kind = "title") then
		normalize-space(
			string-join(
				for $item in catalog:label($key, $backend)
				return string($item),
				" "
			)
		)
	else
		let $entry := catalog:bibl($key, $backend)
		return normalize-space(serialize($entry))
};

declare function local:resolve($backend as xs:string, $kind as xs:string, $key as xs:string) as xs:string {
	switch ($backend)
		case "legacy" return
			local:resolve-backend($backend, $kind, $key)
		case "catalog" return
			local:resolve-backend($backend, $kind, $key)
		default return
			error(xs:QName("oracle:UNKNOWN_BACKEND"), "Unknown oracle backend: " || $backend)
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
let $cases := (
	for $key in $title-ids
	return map {"kind": "title", "key": $key},
	for $key in $bibliography-ids
	return map {"kind": "bibliography", "key": $key}
)
let $equivalent-fallback := ($effective-backend-a, $effective-backend-b) = "legacy" and
	($effective-backend-a, $effective-backend-b) = "catalog" and
	not(
		some
			$path in
			(
				"/db/apps/catalogs/labels.xml", "/db/apps/catalogs/bibliography.xml", "/db/apps/catalogs/retired-ids.xml"
			) satisfies
			doc-available($path)
	)
let $mismatches := if ($equivalent-fallback) then (
) else
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
		"comparisonMode":
			if ($equivalent-fallback) then
				"equivalent-query-fallback"
			else
				"resolved-values",
		"titleCases": count($title-ids),
		"bibliographyCases": count($bibliography-ids),
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
