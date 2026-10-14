xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for exptit:printTitle's BMurl-prefixed-identifier branch.
 : A live-corpus smoke test of additionsform/decorationsform found this
 : branch returning empty for unresolvable ids (up to ~14% of some
 : dropdowns), unlike its two sibling branches which correctly fall
 : back to the original identifier.
 :)
module namespace tsprinttitle = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-exptit-printtitle";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "../../modules/exptit.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

declare variable $tsprinttitle:cache-id := "INSTESTprintTitleBMurl77";

declare variable $tsprinttitle:cache-title := "a distinctive cached title no fallback path could produce";

declare variable $tsprinttitle:missing-id := "INSTESTprintTitleBMurlMissing77";

declare %private function tsprinttitle:remove-entry($id as xs:string) {
	if (doc-available("/db/apps/lists/titleCache.xml")) then
		let $existing := doc("/db/apps/lists/titleCache.xml")//t:item[@corresp eq $id]
		return if ($existing) then
			update delete $existing
		else (
		)
	else (
	)
};

declare %test:setUp function tsprinttitle:setUp() {
	tsprinttitle:remove-entry($tsprinttitle:cache-id)
};

declare %test:tearDown function tsprinttitle:tearDown() {
	tsprinttitle:remove-entry($tsprinttitle:cache-id)
};

(:~
 : A BMurl-prefixed id that resolves still returns the resolved title
 : (regression guard on the fix below).
 :)
declare
	%test:assertEquals("a distinctive cached title no fallback path could produce")
function tsprinttitle:bmurl-prefixed-resolvable-id-returns-title() {
	let $_ := titles:updateTitleCache($tsprinttitle:cache-id, $tsprinttitle:cache-title)
	return string(exptit:printTitle($config:BMurl || $tsprinttitle:cache-id))
};

(:~
 : A BMurl-prefixed id that does not resolve falls back to the
 : original identifier, same as the function's other two branches -
 : not empty.
 :)
declare
	%test:assertEquals("https://betamasaheft.eu/INSTESTprintTitleBMurlMissing77")
function tsprinttitle:bmurl-prefixed-unresolvable-id-falls-back-to-original() {
	string(exptit:printTitle($config:BMurl || $tsprinttitle:missing-id))
};

(:~
 : A "betmas:"-prefixed id that resolves still returns the resolved
 : title (regression guard on the fix below).
 :)
declare
	%test:assertEquals("a distinctive cached title no fallback path could produce")
function tsprinttitle:betmas-prefixed-resolvable-id-returns-title() {
	let $_ := titles:updateTitleCache($tsprinttitle:cache-id, $tsprinttitle:cache-title)
	return string(exptit:printTitle("betmas:" || $tsprinttitle:cache-id))
};

(:~
 : A "betmas:"-prefixed id that does not resolve falls back to the
 : original identifier - same bug the BMurl branch had, same fix.
 :)
declare
	%test:assertEquals("betmas:INSTESTprintTitleBMurlMissing77")
function tsprinttitle:betmas-prefixed-unresolvable-id-falls-back-to-original() {
	string(exptit:printTitle("betmas:" || $tsprinttitle:missing-id))
};

(:~
 : A live lists/deleted.xml id must not recurse (StackOverflow), mirroring
 : titles:printTitleID's guard. Prefer a formerlyAlsoListedAs self-loop
 : when one is still listed; else any tombstone.
 :)
declare %test:assertTrue function tsprinttitle:printTitleID-self-formerly-no-recurse() {
	let $deleted := doc("/db/apps/lists/deleted.xml")
	let $id := (
		(
			for $rel in collection("/db/apps/expanded")//t:relation[@name = "betmas:formerlyAlsoListedAs"]
			let $active := normalize-space($rel/@active)
			let $passive := normalize-space($rel/@passive)
			let $bare := replace($passive, "^https?://[^/]+/", "")
			where $active ne "" and $active = $passive and $bare ne "" and exists($deleted//t:item[. = $bare])
			return $bare
		)[1],
		($deleted//t:item/normalize-space(.))[. ne ""][1]
	)[1]
	let $t := exptit:printTitleID($id)
	return exists($id) and
		(
			contains($t, "deleted") or
				contains($t, "formerlyAlsoListedAs") or
				contains($t, "permanently deleted") or
				starts-with($t, "No item:")
		)
};

(:~
 : A "#subtitle" fragment must return the composed main+subtitle string
 : ($name), not an empty id() lookup of the full LIT…#fragment id.
 : Witness: LIT2000Mazmur#Psalm151 on /decorations miniature work facets
 : (BetMasWeb#157).
 :)
declare %test:assertTrue function tsprinttitle:printTitleID-hash-fragment-returns-composed-name() {
	let $t := normalize-space(string(exptit:printTitleID("LIT2000Mazmur#Psalm151")))
	return starts-with($t, "Psalms of David") and
		contains($t, "Psalm151") and
		not($t = "LIT2000Mazmur#Psalm151") and
		string-length($t) gt 0
};
