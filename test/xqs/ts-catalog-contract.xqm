xquery version "3.1" encoding "UTF-8";

(:~
 : Behavioral contract shared by the legacy and catalog backends.
 : The two-argument overloads are the test seam; production consumers
 : use the one-argument functions and their configured backend.
 :
 : Each case is asserted per backend rather than with a single `every`, so a
 : failure names the backend that broke and a backend cannot pass by being
 : vacuously equal to the other one.
 :)
module namespace tscatalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-catalog-contract";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";

import module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog" at "../../modules/catalog.xqm";
import module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-places" at "../../modules/catalog-places.xqm";

declare %private function tscatalog:text($label as item()*) as xs:string {
	normalize-space(string-join($label!string(.), " "))
};

declare
	%test:args("legacy")
	%test:assertEquals("Exodus")
	%test:args("catalog")
	%test:assertEquals("Exodus")
function tscatalog:label-resolves-a-record($backend as xs:string) as xs:string {
	tscatalog:text(catalog:label("LIT1367Exodus", $backend))
};

declare
	%test:args("legacy")
	%test:assertEquals("Exodus|Habta Śǝllāse")
	%test:args("catalog")
	%test:assertEquals("Exodus|Habta Śǝllāse")
function tscatalog:labels-preserve-input-order($backend as xs:string) as xs:string {
	string-join(catalog:labels(("LIT1367Exodus", "PRS11160HabtaS"), $backend)!normalize-space(string(.)), "|")
};

(:~
 : A trailing "#" is authored noise, not a fragment reference.
 :)
declare
	%test:args("legacy")
	%test:assertEquals("Senodos")
	%test:args("catalog")
	%test:assertEquals("Senodos")
function tscatalog:label-ignores-a-trailing-hash($backend as xs:string) as xs:string {
	tscatalog:text(catalog:label("LIT2317Senodo#", $backend))
};

(:~
 : "id#subid" composes the record label with the anchor label. Asserted
 : structurally because the anchor text is corpus data, not a fixture.
 :)
declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:label-composes-record-and-anchor($backend as xs:string) as xs:boolean {
	let $composed := tscatalog:text(catalog:label("LIT1367Exodus#Ex1", $backend))
	return starts-with($composed, "Exodus: ") and string-length($composed) gt string-length("Exodus: ")
};

(:~
 : An unresolvable main id must say so rather than return nothing.
 :)
declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:label-reports-an-unknown-main-id($backend as xs:string) as xs:boolean {
	contains(
		tscatalog:text(catalog:label("LIT0000NoSuchRecord#t1", $backend)),
		"No item: LIT0000NoSuchRecord"
	)
};

declare
	%test:args("legacy")
	%test:assertEquals("no id")
	%test:args("catalog")
	%test:assertEquals("no id")
function tscatalog:empty-id-is-marked($backend as xs:string) as xs:string {
	tscatalog:text(catalog:label("", $backend))
};

declare
	%test:args("legacy")
	%test:assertEquals("no item yet with id #")
	%test:args("catalog")
	%test:assertEquals("no item yet with id #")
function tscatalog:bare-hash-is-marked($backend as xs:string) as xs:string {
	tscatalog:text(catalog:label("#", $backend))
};

declare
	%test:args("legacy")
	%test:assertEquals("La Synthaxe du Codex UniCont1")
	%test:args("catalog")
	%test:assertEquals("La Synthaxe du Codex UniCont1")
function tscatalog:sdc-ids-are-expanded($backend as xs:string) as xs:string {
	tscatalog:text(catalog:label("sdc:UniCont1", $backend))
};

(:~
 : A deleted id resolves to a notice, never to silence: either the successor
 : form from betmas:formerlyAlsoListedAs, the self-referential-successor form,
 : or the permanent-deletion form.
 :)
declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:deleted-ids-explain-themselves($backend as xs:string) as xs:boolean {
	let $id := (doc("/db/apps/lists/deleted.xml")//t:item)[1]/string()
	let $label := tscatalog:text(catalog:label($id, $backend))
	return contains($label, "deleted")
};

(:~
 : A deleted id whose only formerlyAlsoListedAs successor is itself must
 : terminate instead of recursing (the LOC1464Ankoba stack overflow).
 :)
declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:self-referential-successor-terminates($backend as xs:string) as xs:boolean {
	let $label := tscatalog:text(catalog:label("LOC1464Ankoba", $backend))
	return contains($label, "deleted") or contains($label, "formerly also listed as")
};

(:~
 : Both backends route external place ids through catalog-places.xqm, so
 : Web and API cannot disagree about a wd:/gn:/pleiades: label. Uses an id
 : already present in the maintained list, so no HTTP call is made.
 :)
declare %test:assertTrue function tscatalog:external-place-labels-agree-across-backends() as xs:boolean {
	let $ref := (
		doc("/db/apps/lists/placeNamesLabels.xml")//t:item[matches(@corresp, "^(wd:Q\d+|gn:|pleiades:)")]
	)[1]/@corresp/string()
	return empty($ref) or (
		tscatalog:text(catalog:label($ref, "legacy")) eq tscatalog:text(catalog:label($ref, "catalog")) and
			tscatalog:text(catalog:label($ref, "legacy")) ne ""
	)
};

(:~
 : A remembered external label is served from the process-local cache, so the
 : interim HTTP fetch runs at most once per identifier and never writes to the
 : database.
 :)
declare %test:assertEquals("Cached Fixture Place") function tscatalog:remembered-place-labels-come-from-cache() as xs:string {
	let $ref := "wd:Q999999999"
	let $remembered := places:remember($ref, "Cached Fixture Place")
	return tscatalog:text(places:label($ref))
};

declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:institutions-return-labelled-items($backend as xs:string) as xs:boolean {
	exists(catalog:institutions($backend)[self::t:item][@xml:id][normalize-space(.)])
};

declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:textparts-resolve-known-work($backend as xs:string) as xs:boolean {
	exists(catalog:textparts("LIT1367Exodus", $backend)[self::t:item][starts-with(@corresp, "LIT1367Exodus")])
};

declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:bibl-resolves-known-entry($backend as xs:string) as xs:boolean {
	exists(catalog:bibl("bm:IHABook557", $backend)[self::b:entry])
};

declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:bibl-accepts-an-unprefixed-key($backend as xs:string) as xs:boolean {
	deep-equal(catalog:bibl("IHABook557", $backend), catalog:bibl("bm:IHABook557", $backend))
};

declare
	%test:args("legacy")
	%test:assertTrue
	%test:args("catalog")
	%test:assertTrue
function tscatalog:retired-identifies-known-deletion($backend as xs:string) as xs:boolean {
	catalog:retired("LOC1464Ankoba", $backend)
};

declare
	%test:args("legacy")
	%test:assertFalse
	%test:args("catalog")
	%test:assertFalse
function tscatalog:retired-is-false-for-a-live-record($backend as xs:string) as xs:boolean {
	catalog:retired("LIT1367Exodus", $backend)
};

declare %test:assertEquals("legacy") function tscatalog:default-backend-is-legacy() as xs:string {
	catalog:backend("contract-test")
};

declare %test:assertEquals("legacy") function tscatalog:invalid-backend-value-falls-back() as xs:string {
	catalog:backend("contract-test-nonsense-value")
};
