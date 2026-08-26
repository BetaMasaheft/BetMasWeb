xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for restviews/permanentItems.xqm's split of
 : PermRestItem:ITEM's inline switch($type) - same shape and motivation
 : as ts-restitem-maincontent.xqm's tests for the sibling split in
 : restviews/items.xqm. This is a genuinely separate, already-diverged
 : copy of that switch (different corpus-doc lookup, an uncommented
 : BetMasRel block in "analytic", inlined contained-works logic in
 : "text", an "institutions" case the other file's extras switch
 : doesn't have), so most of its PermRestItem:mainContent* functions are
 : independent - not shared with restItem's, except the seven noted below.
 :
 : Skips the "graph" case for manuscripts - item2:mainContentGraphManuscripts
 : calls charts:mssSankey, which needs a reachable Fuseki SPARQL endpoint;
 : not assumed available in every test environment.
 :
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 : @see item2:mainContentGeobrowser for the leaf functions shared with
 : ts-restitem-maincontent.xqm
 : @see PermRestItem:mainContentTemplate for the templates:apply adapter
 : PermRestItem:ITEM now calls instead of PermRestItem:mainContent
 : directly
 :)
module namespace tspermmaincontent = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-permrestitem-maincontent";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace PermRestItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/PermRestItem" at "../../restviews/permanentItems.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "../../modules/item.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "../../modules/switch2.xqm";

declare %private function tspermmaincontent:doc($id as xs:string, $collection as xs:string) as element()? {
	switch2:collectionVar($collection)/id($id)[name() = "TEI"]
};

declare %test:assertTrue function tspermmaincontent:dispatch-matches-direct-call-corpus() {
	deep-equal(
		PermRestItem:mainContent("corpus", tspermmaincontent:doc("MNC010", "manuscripts"), "MNC010", "manuscripts"),
		PermRestItem:mainContentCorpus("MNC010")
	)
};

declare %test:assertTrue function tspermmaincontent:dispatch-matches-direct-call-geobrowser() {
	deep-equal(
		PermRestItem:mainContent("geobrowser", tspermmaincontent:doc("LOC3080Ferheb", "places"), "LOC3080Ferheb", "places"),
		item2:mainContentGeobrowser("LOC3080Ferheb")
	)
};

declare %test:assertTrue function tspermmaincontent:dispatch-matches-direct-call-analytic() {
	let $this := tspermmaincontent:doc("PRS8278SablaWa", "persons")
	return deep-equal(
		PermRestItem:mainContent("analytic", $this, "PRS8278SablaWa", "persons"),
		PermRestItem:mainContentAnalytic($this, "PRS8278SablaWa", "persons")
	)
};

declare %test:assertTrue function tspermmaincontent:dispatch-matches-direct-call-text() {
	let $this := tspermmaincontent:doc("LIT3508Epistle", "works")
	return deep-equal(
		PermRestItem:mainContent("text", $this, "LIT3508Epistle", "works"),
		PermRestItem:mainContentText($this, "LIT3508Epistle", "works")
	)
};

declare %test:assertTrue function tspermmaincontent:dispatch-matches-direct-call-graph() {
	let $this := tspermmaincontent:doc("LOC3080Ferheb", "places")
	return deep-equal(
		PermRestItem:mainContent("graph", $this, "LOC3080Ferheb", "places"),
		PermRestItem:mainContentGraph($this, "LOC3080Ferheb", "places")
	)
};

declare %test:assertTrue function tspermmaincontent:dispatch-matches-direct-call-default() {
	let $this := tspermmaincontent:doc("MNC010", "manuscripts")
	return deep-equal(
		PermRestItem:mainContent("main", $this, "MNC010", "manuscripts"),
		PermRestItem:mainContentDefault($this, "MNC010", "manuscripts")
	)
};

(:
 : PermRestItem:mainContent's own switch($type) now routes each branch
 : through templates:apply too (PermRestItem:mainContentCorpusTemplate/
 : item2:mainContentGeobrowserTemplate/mainContentAnalyticTemplate/
 : mainContentTextTemplate/mainContentGraphTemplate/
 : mainContentDefaultTemplate) instead of calling the branch function
 : directly - confirms each adapter produces the exact same output as
 : the plain call it replaces.
 :)
declare %test:assertTrue function tspermmaincontent:template-adapter-matches-direct-call-corpus() {
	deep-equal(
		PermRestItem:mainContentCorpusTemplate(<div />, map {"id": "MNC010"}),
		PermRestItem:mainContentCorpus("MNC010")
	)
};

declare %test:assertTrue function tspermmaincontent:template-adapter-matches-direct-call-geobrowser() {
	deep-equal(
		item2:mainContentGeobrowserTemplate(<div />, map {"id": "LOC3080Ferheb"}),
		item2:mainContentGeobrowser("LOC3080Ferheb")
	)
};

declare %test:assertTrue function tspermmaincontent:template-adapter-matches-direct-call-analytic() {
	let $this := tspermmaincontent:doc("PRS8278SablaWa", "persons")
	return deep-equal(
		PermRestItem:mainContentAnalyticTemplate(
			<div />,
			map {"this": $this, "id": "PRS8278SablaWa", "collection": "persons"}
		),
		PermRestItem:mainContentAnalytic($this, "PRS8278SablaWa", "persons")
	)
};

declare %test:assertTrue function tspermmaincontent:template-adapter-matches-direct-call-text() {
	let $this := tspermmaincontent:doc("LIT3508Epistle", "works")
	return deep-equal(
		PermRestItem:mainContentTextTemplate(<div />, map {"this": $this, "id": "LIT3508Epistle", "collection": "works"}),
		PermRestItem:mainContentText($this, "LIT3508Epistle", "works")
	)
};

declare %test:assertTrue function tspermmaincontent:template-adapter-matches-direct-call-graph() {
	let $this := tspermmaincontent:doc("LOC3080Ferheb", "places")
	return deep-equal(
		PermRestItem:mainContentGraphTemplate(<div />, map {"this": $this, "id": "LOC3080Ferheb", "collection": "places"}),
		PermRestItem:mainContentGraph($this, "LOC3080Ferheb", "places")
	)
};

declare %test:assertTrue function tspermmaincontent:template-adapter-matches-direct-call-default() {
	let $this := tspermmaincontent:doc("MNC010", "manuscripts")
	return deep-equal(
		PermRestItem:mainContentDefaultTemplate(<div />, map {"this": $this, "id": "MNC010", "collection": "manuscripts"}),
		PermRestItem:mainContentDefault($this, "MNC010", "manuscripts")
	)
};

(:
 : mainContentGraph requires $this as element() even though only the
 : "manuscripts" sub-case actually reads it - any real element works as
 : a stand-in for the other sub-cases.
 :)
declare %test:assertTrue function tspermmaincontent:graph-dispatch-matches-direct-call-places() {
	let $this := tspermmaincontent:doc("LOC3080Ferheb", "places")
	return deep-equal(
		PermRestItem:mainContentGraph($this, "LOC3080Ferheb", "places"),
		item2:mainContentGraphPlaces("LOC3080Ferheb")
	)
};

declare %test:assertTrue function tspermmaincontent:graph-dispatch-matches-direct-call-persons() {
	let $this := tspermmaincontent:doc("PRS8278SablaWa", "persons")
	return deep-equal(
		PermRestItem:mainContentGraph($this, "PRS8278SablaWa", "persons"),
		item2:mainContentGraphPersons("PRS8278SablaWa")
	)
};

declare %test:assertTrue function tspermmaincontent:graph-dispatch-matches-direct-call-authority-files() {
	let $this := tspermmaincontent:doc("AT1129MMFrank", "authority-files")
	return deep-equal(
		PermRestItem:mainContentGraph($this, "AT1129MMFrank", "authority-files"),
		item2:mainContentGraphAuthorityFiles("AT1129MMFrank")
	)
};

declare %test:assertTrue function tspermmaincontent:graph-dispatch-matches-direct-call-default() {
	let $this := tspermmaincontent:doc("corpus2", "corpora")
	return deep-equal(
		PermRestItem:mainContentGraph($this, "corpus2", "corpora"),
		item2:mainContentGraphDefault("corpus2", "corpora")
	)
};

declare %test:assertTrue function tspermmaincontent:extras-dispatch-matches-direct-call-works() {
	deep-equal(PermRestItem:mainContentExtras("LIT3508Epistle", "works"), item2:mainContentExtrasWorks("LIT3508Epistle"))
};

declare %test:assertTrue function tspermmaincontent:extras-dispatch-matches-direct-call-persons() {
	deep-equal(
		PermRestItem:mainContentExtras("PRS8278SablaWa", "persons"),
		PermRestItem:mainContentExtrasPersons("PRS8278SablaWa")
	)
};

declare %test:assertTrue function tspermmaincontent:extras-dispatch-matches-direct-call-authority-files() {
	deep-equal(
		PermRestItem:mainContentExtras("AT1129MMFrank", "authority-files"),
		PermRestItem:mainContentExtrasAuthorityFiles("AT1129MMFrank")
	)
};

(:
 : The one extras case restItem:mainContentExtras (the sibling split in
 : items.xqm) doesn't have - institutions get their own pelagios/geojson
 : block here.
 :)
declare %test:assertTrue function tspermmaincontent:extras-dispatch-matches-direct-call-institutions() {
	deep-equal(
		PermRestItem:mainContentExtras("INS0013IHA", "institutions"),
		PermRestItem:mainContentExtrasInstitutions("INS0013IHA")
	)
};

declare %test:assertTrue function tspermmaincontent:extras-dispatch-matches-direct-call-default() {
	deep-equal(PermRestItem:mainContentExtras("MNC010", "manuscripts"), ())
};

(:
 : PermRestItem:mainContentGraph's own switch($collection) now routes
 : each branch through templates:apply too (shares the same
 : item2:mainContentGraphManuscriptsTemplate/PlacesTemplate/PersonsTemplate/
 : AuthorityFilesTemplate/DefaultTemplate as restItem's sibling switch)
 : instead of calling the leaf function directly - confirms each
 : adapter produces the exact same output as the plain call it
 : replaces.
 :)
declare %test:assertTrue function tspermmaincontent:graph-template-adapter-matches-direct-call-manuscripts() {
	let $this := tspermmaincontent:doc("BAVet1", "manuscripts")
	return deep-equal(
		item2:mainContentGraphManuscriptsTemplate(<div />, map {"this": $this, "id": "BAVet1"}),
		item2:mainContentGraphManuscripts($this, "BAVet1")
	)
};

declare %test:assertTrue function tspermmaincontent:graph-template-adapter-matches-direct-call-places() {
	deep-equal(
		item2:mainContentGraphPlacesTemplate(<div />, map {"id": "LOC3080Ferheb"}),
		item2:mainContentGraphPlaces("LOC3080Ferheb")
	)
};

declare %test:assertTrue function tspermmaincontent:graph-template-adapter-matches-direct-call-persons() {
	deep-equal(
		item2:mainContentGraphPersonsTemplate(<div />, map {"id": "PRS8278SablaWa"}),
		item2:mainContentGraphPersons("PRS8278SablaWa")
	)
};

declare %test:assertTrue function tspermmaincontent:graph-template-adapter-matches-direct-call-authority-files() {
	deep-equal(
		item2:mainContentGraphAuthorityFilesTemplate(<div />, map {"id": "AT1129MMFrank"}),
		item2:mainContentGraphAuthorityFiles("AT1129MMFrank")
	)
};

declare %test:assertTrue function tspermmaincontent:graph-template-adapter-matches-direct-call-default() {
	deep-equal(
		item2:mainContentGraphDefaultTemplate(<div />, map {"id": "corpus2", "collection": "corpora"}),
		item2:mainContentGraphDefault("corpus2", "corpora")
	)
};

(:
 : PermRestItem:mainContentExtras's own switch($collection) now routes
 : each non-empty branch through templates:apply too
 : (item2:mainContentExtrasWorksTemplate/
 : PermRestItem:mainContentExtrasPersonsTemplate/
 : mainContentExtrasAuthorityFilesTemplate/mainContentExtrasInstitutionsTemplate)
 : instead of calling the leaf function directly - confirms each
 : adapter produces the exact same output as the plain call it
 : replaces.
 :)
declare %test:assertTrue function tspermmaincontent:extras-template-adapter-matches-direct-call-works() {
	deep-equal(
		item2:mainContentExtrasWorksTemplate(<div />, map {"id": "LIT3508Epistle"}),
		item2:mainContentExtrasWorks("LIT3508Epistle")
	)
};

declare %test:assertTrue function tspermmaincontent:extras-template-adapter-matches-direct-call-persons() {
	deep-equal(
		PermRestItem:mainContentExtrasPersonsTemplate(<div />, map {"id": "PRS8278SablaWa"}),
		PermRestItem:mainContentExtrasPersons("PRS8278SablaWa")
	)
};

declare %test:assertTrue function tspermmaincontent:extras-template-adapter-matches-direct-call-authority-files() {
	deep-equal(
		PermRestItem:mainContentExtrasAuthorityFilesTemplate(<div />, map {"id": "AT1129MMFrank"}),
		PermRestItem:mainContentExtrasAuthorityFiles("AT1129MMFrank")
	)
};

declare %test:assertTrue function tspermmaincontent:extras-template-adapter-matches-direct-call-institutions() {
	deep-equal(
		PermRestItem:mainContentExtrasInstitutionsTemplate(<div />, map {"id": "INS0013IHA"}),
		PermRestItem:mainContentExtrasInstitutions("INS0013IHA")
	)
};

declare %test:assertTrue function tspermmaincontent:template-adapter-matches-direct-call() {
	let $this := tspermmaincontent:doc("LOC3080Ferheb", "places")
	return deep-equal(
		PermRestItem:mainContentTemplate(
			<div />,
			map {"type": "graph", "this": $this, "id": "LOC3080Ferheb", "collection": "places"}
		),
		PermRestItem:mainContent("graph", $this, "LOC3080Ferheb", "places")
	)
};
