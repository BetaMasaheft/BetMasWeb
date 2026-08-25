xquery version "3.1" encoding "UTF-8";

(:~
 : One-time seeding of betmas-id-manager's counters/registry from the live
 : corpus - a prerequisite for safely wiring edit/save-new-entity.xql to the
 : service: id-manager starts with counters at 0 and an empty registry, but
 : the corpus already has thousands of entities, so an unseeded auto-counter
 : would immediately reissue already-taken ids. Not exposed via
 : controller.xql - run once via the eXist admin client
 : (`xst eval 'seed:run(100)'` or the java client's -x flag) against a
 : target instance, not as a public HTTP endpoint.
 :
 : Safe to re-run: seed-manual is idempotent (skips already-registered
 : ids), and reset-counter just overwrites the counter value, so re-running
 : simply recomputes against current corpus state.
 :)
module namespace seed = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/idmanager-seed";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace idmanager = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/idmanager" at "xmldb:exist:///db/apps/BetMasWeb/modules/idmanager.xqm";

(: id-manager's own bulk endpoint has no documented size limit - chosen
   empirically as a conservative round-trip size, not mandated by the
   service. See README.md for the corpus scale this was tuned against
   (manuscripts ~20k, authority-files ~600 ids). :)
declare variable $seed:chunk-size := 2000;

(:~
 : Same regex/max-parsing idiom edit/save-new-entity.xql used inline before
 : this rewrite - kept here (the one place that still needs it) rather than
 : in the request-path module.
 :)
declare %private function local:max-sequence($type as xs:string) as xs:integer {
	let $ids := switch2:collectionVar($type)//t:TEI/@xml:id
	let $parsed :=
		for $id in $ids
		return analyze-string($id, "([A-Z]+)(\d+)(\w+)")
	let $numericValues :=
		for $g in $parsed//*:group[@nr = "2"]
		return xs:integer($g)
	return (max($numericValues), 0)[1]
};

declare %private function local:all-ids($type as xs:string) as xs:string* {
	switch2:collectionVar($type)//t:TEI/@xml:id/string()
};

(:~
 : Sequences can't nest in XQuery, so each chunk is boxed into an array -
 : a plain `for ... return subsequence(...)` would flatten straight back
 : into one sequence and silently lose the chunk boundaries.
 :)
declare %private function local:chunk($seq as item()*, $size as xs:integer) as array(*)* {
	for $i in 1 to xs:integer(ceiling(count($seq) div $size))
	return array { subsequence($seq, ($i - 1) * $size + 1, $size) }
};

declare %private function local:seed-auto-type($type as xs:string, $buffer as xs:integer) as map(*) {
	let $max := local:max-sequence($type)
	let $target := $max + $buffer
	let $result := idmanager:reset-counter($type, $target)
	return map {"type": $type, "mode": "auto", "corpusMax": $max, "seededTo": $target, "status": $result?status}
};

declare %private function local:seed-manual-type($type as xs:string) as map(*) {
	let $ids := local:all-ids($type)
	let $chunks := local:chunk($ids, $seed:chunk-size)
	let $results :=
		for $chunk in $chunks
		return idmanager:seed-manual($type, $chunk?*)
	return map {
		"type": $type,
		"mode": "manual",
		"corpusCount": count($ids),
		"registered":
			sum(
				for $r in $results
				return ($r?body?registered, 0)[1]
			),
		"skipped":
			sum(
				for $r in $results
				return ($r?body?skipped, 0)[1]
			),
		"skippedUnsafe":
			sum(
				for $r in $results
				return ($r?body?skippedUnsafe, 0)[1]
			),
		"chunkStatuses":
			array
				{
					for $r in $results
					return $r?status
				}
	}
};

(:~
 : Seeds every known type from the live corpus. $buffer is added on top of
 : the corpus's current max sequence for auto types only - headroom against
 : entities created between this seeding run and cutover to the new
 : id-manager-backed save-new-entity.xql. Has no meaning for manual types,
 : which register verbatim.
 :)
declare function seed:run($buffer as xs:integer) as map(*)* {
	let $typesResponse := idmanager:list-types()
	let $_ := if ($typesResponse?status ne 200) then
		error(xs:QName("seed:UNREACHABLE"), "could not list types from id-manager: " || $typesResponse?status)
	else (
	)
	for $t in $typesResponse?body?*
	let $type := $t?type
	let $mode := $t?mode
	order by $type
	return if ($mode eq "auto") then
		local:seed-auto-type($type, $buffer)
	else
		local:seed-manual-type($type)
};
