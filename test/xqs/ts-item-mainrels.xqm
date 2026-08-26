xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/item.xqm's item2:mainRels dispatcher and its
 : per-collection functions (item2:mainRelsPersons/Places/Works/Studies/
 : Narratives/AuthorityFiles/Institutions). Naming follows tei-publisher-lib:
 : test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :)
module namespace tsmainrels = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-item-mainrels";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "../../modules/item.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "../../modules/switch2.xqm";

declare %private function tsmainrels:doc($id as xs:string, $collection as xs:string) as element()? {
	switch2:collectionVar($collection)/id($id)[name() = "TEI"]
};

(:~
 : item2:mainRels always wraps its per-collection content in the same
 : outer div, regardless of collection - this is the contract the
 : dispatcher must preserve.
 :)
declare %test:assertEquals("allMainRel") function tsmainrels:wrapper-class-persons() {
	string(item2:mainRels(tsmainrels:doc("PRS11422WaldaGiyorgis", "persons"), "persons")/@class)
};

declare %test:assertEquals("allMainRel") function tsmainrels:wrapper-class-works() {
	string(item2:mainRels(tsmainrels:doc("LIT1349EpistlEusebius", "works"), "works")/@class)
};

declare %test:assertEquals("allMainRel") function tsmainrels:wrapper-class-places() {
	string(item2:mainRels(tsmainrels:doc("LOC1008Abarga", "places"), "places")/@class)
};

(:~
 : A collection with no mainRels branch (e.g. manuscripts) must fall
 : through the dispatcher's default case to an empty result, not error.
 :)
declare %test:assertTrue function tsmainrels:unhandled-collection-is-empty() {
	empty(item2:mainRels(tsmainrels:doc("BNFet32", "manuscripts"), "manuscripts")/*)
};

(:~
 : The dispatcher must be behaviorally transparent: routing "persons"
 : through item2:mainRels has to produce exactly what calling
 : item2:mainRelsPersons directly produces, for the same document. This is
 : the actual regression the mainRels split cares about - the switch was
 : split out of one function into eight without changing what any branch
 : returns.
 :)
declare %test:assertTrue function tsmainrels:dispatch-matches-direct-call-persons() {
	let $this := tsmainrels:doc("PRS11422WaldaGiyorgis", "persons")
	return deep-equal(
		item2:mainRels($this, "persons"),
		<div class="allMainRel">{ item2:mainRelsPersons($this, "persons") }</div>
	)
};

declare %test:assertTrue function tsmainrels:dispatch-matches-direct-call-works() {
	let $this := tsmainrels:doc("LIT1349EpistlEusebius", "works")
	return deep-equal(
		item2:mainRels($this, "works"),
		<div class="allMainRel">{ item2:mainRelsWorks($this, "works") }</div>
	)
};

declare %test:assertTrue function tsmainrels:dispatch-matches-direct-call-places() {
	let $this := tsmainrels:doc("LOC1008Abarga", "places")
	return deep-equal(
		item2:mainRels($this, "places"),
		<div class="allMainRel">{ item2:mainRelsPlaces($this, "places") }</div>
	)
};

(:
 : item2:mainRelsTemplate is the templates:apply adapter item2:RestSeeAlso
 : now calls instead of item2:mainRels directly - confirms the adapter
 : produces the exact same output as the plain call it replaces.
 :)
declare %test:assertTrue function tsmainrels:template-adapter-matches-direct-call() {
	let $this := tsmainrels:doc("PRS11422WaldaGiyorgis", "persons")
	return deep-equal(
		item2:mainRelsTemplate(<div />, map {"this": $this, "collection": "persons"}),
		item2:mainRels($this, "persons")
	)
};
