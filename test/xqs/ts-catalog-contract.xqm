xquery version "3.1" encoding "UTF-8";

(:~
 : Behavioral contract shared by the legacy and catalog backends.
 : The two-argument overloads are the test seam; production consumers
 : use the one-argument functions and their configured backend.
 :)
module namespace tscatalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-catalog-contract";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";

import module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog" at "../../modules/catalog.xqm";

declare variable $tscatalog:backends := ("legacy", "catalog");

declare %test:assertTrue function tscatalog:label-resolves-on-both-backends() {
	every
		$backend in
		$tscatalog:backends satisfies
		normalize-space(string(catalog:label("LIT1367Exodus", $backend))) = "Exodus"
};

declare %test:assertTrue function tscatalog:labels-preserve-input-order() {
	every
		$backend in
		$tscatalog:backends satisfies
		deep-equal(
			catalog:labels(("LIT1367Exodus", "PRS11160HabtaS"), $backend)!normalize-space(string(.)),
			("Exodus", "Habta Śǝllāse")
		)
};

declare %test:assertTrue function tscatalog:institutions-return-labelled-items() {
	every
		$backend in
		$tscatalog:backends satisfies
		exists(catalog:institutions($backend)[self::t:item][@xml:id][normalize-space(.)])
};

declare %test:assertTrue function tscatalog:textparts-resolve-known-work() {
	every
		$backend in
		$tscatalog:backends satisfies
		exists(catalog:textparts("LIT1367Exodus", $backend)[self::t:item][starts-with(@corresp, "LIT1367Exodus")])
};

declare %test:assertTrue function tscatalog:bibl-resolves-known-entry() {
	every $backend in $tscatalog:backends satisfies exists(catalog:bibl("bm:IHABook557", $backend)[self::b:entry])
};

declare %test:assertTrue function tscatalog:retired-identifies-known-deletion() {
	every $backend in $tscatalog:backends satisfies catalog:retired("LOC1464Ankoba", $backend)
};

declare %test:assertTrue function tscatalog:default-backend-is-legacy() {
	catalog:backend("contract-test") = "legacy"
};
