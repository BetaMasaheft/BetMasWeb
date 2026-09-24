xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";

import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

declare variable $backend-a external := "legacy";

declare variable $backend-b external := "legacy";

declare variable $reviewed-path := "/db/apps/BetMasWeb/test/catalog-reviewed-mismatches.xml";

declare variable $reviewed := if (doc-available($reviewed-path)) then
	doc($reviewed-path)/reviewed-mismatches/mismatch
else (
);

declare function local:legacy($kind as xs:string, $key as xs:string) as xs:string {
	if ($kind = "title") then
		normalize-space(string-join(exptit:printTitleID($key)!string(.), " "))
	else
		let $entry := doc("/db/apps/lists/bibliography.xml")//b:entry[@id = ($key, replace($key, ":", "_"))][1]
		return normalize-space(serialize($entry))
};

declare function local:resolve($backend as xs:string, $kind as xs:string, $key as xs:string) as xs:string {
	switch ($backend)
		case "legacy" return
			local:legacy($kind, $key)
		default return
			error(xs:QName("oracle:UNKNOWN_BACKEND"), "Unknown oracle backend: " || $backend)
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
let $mismatches := if ($backend-a = $backend-b) then (
) else
	for $case in $cases
	let $kind := $case?kind
	let $key := $case?key
	let $a := local:resolve($backend-a, $kind, $key)
	let $b := local:resolve($backend-b, $kind, $key)
	where $a ne $b
	let $review := $reviewed[@kind = $kind][@key = $key][1]
	return map {
		"kind": $kind,
		"key": $key,
		"backendA": $a,
		"backendB": $b,
		"triage": string($review/@triage),
		"reviewed": exists($review),
		"note": string($review/@note)
	}
let $unreviewed := $mismatches[not(.?reviewed)]
return serialize(
	map {
		"backendA": $backend-a,
		"backendB": $backend-b,
		"titleCases": count($title-ids),
		"bibliographyCases": count($bibliography-ids),
		"mismatchCount": count($mismatches),
		"unreviewedCount": count($unreviewed),
		"mismatches": array { $mismatches }
	},
	map {"method": "json"}
)
