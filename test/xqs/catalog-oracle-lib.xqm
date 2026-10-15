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
