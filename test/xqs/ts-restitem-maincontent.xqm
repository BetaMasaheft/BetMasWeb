xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for restviews/items.xqm's split of restItem:ITEM's inline
 : switch($type) - the content that goes inside the page's <div id="main">
 : - into named functions (restItem:mainContentCorpus, ...Analytic,
 : ...Text, ...Graph, ...Default) behind a thin restItem:mainContent(...)
 : dispatcher. The "graph" and default ("THE MAIN VIEW") cases each had
 : their own nested switch($collection), split the same way
 : (restItem:mainContentGraph* / restItem:mainContentExtras*).
 : Same shape and motivation as the item2:mainRels and
 : item2:seeAlsoOptions splits before it: maintainability and
 : testability for a large inline switch, not an html-templating
 : conversion.
 :
 : Skips the "graph" case for manuscripts - item2:mainContentGraphManuscripts
 : calls charts:mssSankey, which needs a reachable Fuseki SPARQL endpoint;
 : not assumed available in every test environment. The other four graph
 : sub-cases (places/persons/authority-files/default) don't have that
 : dependency.
 :
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 : @see item2:mainContentGeobrowser for the leaf functions shared with
 : ts-permrestitem-maincontent.xqm
 : @see restItem:mainContentTemplate for the templates:apply adapter
 : restItem:ITEM now calls instead of restItem:mainContent directly
 :)
module namespace tsmaincontent = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-restitem-maincontent";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace restItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/restItem" at "../../restviews/items.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "../../modules/item.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "../../modules/switch2.xqm";

declare %private function tsmaincontent:doc($id as xs:string, $collection as xs:string) as element()? {
	switch2:collectionVar($collection)/id($id)[name() = "TEI"]
};

declare %test:assertTrue function tsmaincontent:dispatch-matches-direct-call-corpus() {
	deep-equal(
		restItem:mainContent("corpus", tsmaincontent:doc("MNC010", "manuscripts"), "MNC010", "manuscripts", (), (), (), ()),
		restItem:mainContentCorpus("MNC010")
	)
};

declare %test:assertTrue function tsmaincontent:dispatch-matches-direct-call-geobrowser() {
	deep-equal(
		restItem:mainContent(
			"geobrowser",
			tsmaincontent:doc("LOC3080Ferheb", "places"),
			"LOC3080Ferheb",
			"places",
			(),
			(),
			(),
			()
		),
		item2:mainContentGeobrowser("LOC3080Ferheb")
	)
};

declare %test:assertTrue function tsmaincontent:dispatch-matches-direct-call-analytic() {
	let $this := tsmaincontent:doc("PRS8278SablaWa", "persons")
	return deep-equal(
		restItem:mainContent("analytic", $this, "PRS8278SablaWa", "persons", (), (), (), ()),
		restItem:mainContentAnalytic($this, "persons")
	)
};

declare %test:assertTrue function tsmaincontent:dispatch-matches-direct-call-text() {
	let $this := tsmaincontent:doc("LIT3508Epistle", "works")
	return deep-equal(
		restItem:mainContent("text", $this, "LIT3508Epistle", "works", "", "", "", ""),
		restItem:mainContentText($this, "LIT3508Epistle", "", "", "", "", "works")
	)
};

declare %test:assertTrue function tsmaincontent:dispatch-matches-direct-call-graph() {
	let $this := tsmaincontent:doc("LOC3080Ferheb", "places")
	return deep-equal(
		restItem:mainContent("graph", $this, "LOC3080Ferheb", "places", (), (), (), ()),
		restItem:mainContentGraph($this, "LOC3080Ferheb", "places")
	)
};

declare %test:assertTrue function tsmaincontent:dispatch-matches-direct-call-default() {
	let $this := tsmaincontent:doc("MNC010", "manuscripts")
	return deep-equal(
		restItem:mainContent("main", $this, "MNC010", "manuscripts", (), (), (), ()),
		restItem:mainContentDefault($this, "MNC010", "manuscripts")
	)
};

(:
 : mainContentGraph requires $this as element() even though only the
 : "manuscripts" sub-case actually reads it - any real element works as
 : a stand-in for the other sub-cases.
 :)
declare %test:assertTrue function tsmaincontent:graph-dispatch-matches-direct-call-places() {
	let $this := tsmaincontent:doc("LOC3080Ferheb", "places")
	return deep-equal(
		restItem:mainContentGraph($this, "LOC3080Ferheb", "places"),
		item2:mainContentGraphPlaces("LOC3080Ferheb")
	)
};

declare %test:assertTrue function tsmaincontent:graph-dispatch-matches-direct-call-persons() {
	let $this := tsmaincontent:doc("PRS8278SablaWa", "persons")
	return deep-equal(
		restItem:mainContentGraph($this, "PRS8278SablaWa", "persons"),
		item2:mainContentGraphPersons("PRS8278SablaWa")
	)
};

declare %test:assertTrue function tsmaincontent:graph-dispatch-matches-direct-call-authority-files() {
	let $this := tsmaincontent:doc("AT1129MMFrank", "authority-files")
	return deep-equal(
		restItem:mainContentGraph($this, "AT1129MMFrank", "authority-files"),
		item2:mainContentGraphAuthorityFiles("AT1129MMFrank")
	)
};

declare %test:assertTrue function tsmaincontent:graph-dispatch-matches-direct-call-default() {
	let $this := tsmaincontent:doc("corpus2", "corpora")
	return deep-equal(
		restItem:mainContentGraph($this, "corpus2", "corpora"),
		item2:mainContentGraphDefault("corpus2", "corpora")
	)
};

declare %test:assertTrue function tsmaincontent:extras-dispatch-matches-direct-call-works() {
	let $this := tsmaincontent:doc("LIT3508Epistle", "works")
	return deep-equal(
		restItem:mainContentExtras($this, "LIT3508Epistle", "works"),
		item2:mainContentExtrasWorks("LIT3508Epistle")
	)
};

declare %test:assertTrue function tsmaincontent:extras-dispatch-matches-direct-call-persons() {
	let $this := tsmaincontent:doc("PRS8278SablaWa", "persons")
	return deep-equal(
		restItem:mainContentExtras($this, "PRS8278SablaWa", "persons"),
		restItem:mainContentExtrasPersons($this, "PRS8278SablaWa", "persons")
	)
};

declare %test:assertTrue function tsmaincontent:extras-dispatch-matches-direct-call-authority-files() {
	let $this := tsmaincontent:doc("AT1129MMFrank", "authority-files")
	return deep-equal(
		restItem:mainContentExtras($this, "AT1129MMFrank", "authority-files"),
		restItem:mainContentExtrasAuthorityFiles("AT1129MMFrank")
	)
};

declare %test:assertTrue function tsmaincontent:extras-dispatch-matches-direct-call-default() {
	let $this := tsmaincontent:doc("MNC010", "manuscripts")
	return deep-equal(restItem:mainContentExtras($this, "MNC010", "manuscripts"), ())
};

declare %test:assertTrue function tsmaincontent:template-adapter-matches-direct-call() {
	let $this := tsmaincontent:doc("LOC3080Ferheb", "places")
	return deep-equal(
		restItem:mainContentTemplate(
			<div />,
			map {
				"type": "graph",
				"this": $this,
				"id": "LOC3080Ferheb",
				"collection": "places",
				"edition": (),
				"ref": (),
				"start": (),
				"end": ()
			}
		),
		restItem:mainContent("graph", $this, "LOC3080Ferheb", "places", (), (), (), ())
	)
};
