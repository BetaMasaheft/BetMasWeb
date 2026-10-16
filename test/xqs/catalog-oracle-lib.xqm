xquery version "3.1" encoding "UTF-8";

(:~
 : Shared helpers for the catalog parity oracle. Kept under test/xqs so the
 : runner and XQSuite pin the same bibl presence rule (Phase 4 D1).
 :)
module namespace oraclelib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-oracle-lib";

declare namespace b = "betmas.biblio";

(:~
 : Presence token for bibliography parity. Full-entry serialize equality is
 : not used: EthioStudies vs lists markup/citation text may differ (Phase 4
 : D1). A hit requires a non-empty b:citation.
 :
 : @param $entry catalog:bibl result, or empty
 : @return "hit" or ""
 :)
declare function oraclelib:bibl-presence($entry as element(b:entry)?) as xs:string {
	if (empty($entry) or normalize-space(string($entry/b:citation)) eq "") then
		""
	else
		"hit"
};

(:~
 : Whether a reviewed-mismatch row has a triage the oracle accepts.
 :
 : @param $review one mismatch element from the reviewed file, or empty
 : @return true when @triage is better, worse, or neutral
 :)
declare function oraclelib:valid-review($review as element(mismatch)?) as xs:boolean {
	exists($review) and
		(string($review/@triage) = "better" or string($review/@triage) = "worse" or string($review/@triage) = "neutral")
};

(:~
 : Whether a reviewed row covers this live mismatch. Optional @backendA /
 : @backendB pin resolved values so an Accept cannot hide an inverted or
 : drifted diff (kind+key alone is not enough when pins are present).
 :
 : @param $review reviewed-mismatches/mismatch, or empty
 : @param $backend-a live backend A value
 : @param $backend-b live backend B value
 : @return true when triage is valid and any present A/B pins match
 :)
declare function oraclelib:review-covers(
	$review as element(mismatch)?,
	$backend-a as xs:string,
	$backend-b as xs:string
) as xs:boolean {
	oraclelib:valid-review($review) and
		(empty($review/@backendA) or string($review/@backendA) eq $backend-a) and
		(empty($review/@backendB) or string($review/@backendB) eq $backend-b)
};
