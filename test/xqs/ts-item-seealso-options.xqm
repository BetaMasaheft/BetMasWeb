xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/item.xqm's split of item2:RestSeeAlso's inline
 : switch($collection) - building the <optgroup> options for the "see
 : also" keyword selector - into 8 named per-collection functions
 : (item2:seeAlsoOptionsManuscripts, ...Works, ...Studies, ...Narratives,
 : ...Places, ...Institutions, ...Persons, ...Default) behind a thin
 : item2:seeAlsoOptions($file, $collection) dispatcher. Same shape and
 : purpose as ts-item-mainrels.xqm's split of item2:mainRels's switch:
 : a maintainability/testability refactor, not an html-templating
 : conversion - there's no page structure here worth turning into a
 : template, just a flat option-list builder.
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :)
module namespace tsseealso = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-item-seealso-options";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "../../modules/item.xqm";

declare %private function tsseealso:doc($collection as xs:string, $id as xs:string) as element()? {
	collection("/db/apps/expanded/" || $collection)//t:TEI[@xml:id = $id]
};

(:
 : Confirms the switch in item2:seeAlsoOptions routes each collection to
 : its own matching function and not, say, an adjacent one - the exact
 : mistake a manual case-by-case transcription risks.
 :)
declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-manuscripts() {
	let $file := tsseealso:doc("manuscripts", "AG00001")
	return deep-equal(item2:seeAlsoOptions($file, "manuscripts"), item2:seeAlsoOptionsManuscripts($file))
};

declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-works() {
	let $file := tsseealso:doc("works", "LIT3309Qerellos")
	return deep-equal(item2:seeAlsoOptions($file, "works"), item2:seeAlsoOptionsWorks($file))
};

declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-studies() {
	let $file := tsseealso:doc("studies", "STU0002Historia")
	return deep-equal(item2:seeAlsoOptions($file, "studies"), item2:seeAlsoOptionsStudies($file))
};

declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-narratives() {
	let $file := tsseealso:doc("narratives", "NAR0002feasts")
	return deep-equal(item2:seeAlsoOptions($file, "narratives"), item2:seeAlsoOptionsNarratives($file))
};

declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-places() {
	let $file := tsseealso:doc("places", "LOC3080Ferheb")
	return deep-equal(item2:seeAlsoOptions($file, "places"), item2:seeAlsoOptionsPlaces($file))
};

declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-institutions() {
	let $file := tsseealso:doc("institutions", "INS0013IHA")
	return deep-equal(item2:seeAlsoOptions($file, "institutions"), item2:seeAlsoOptionsInstitutions($file))
};

declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-persons() {
	let $file := tsseealso:doc("persons", "PRS8692segeDen")
	return deep-equal(item2:seeAlsoOptions($file, "persons"), item2:seeAlsoOptionsPersons($file))
};

declare %test:assertTrue function tsseealso:dispatch-matches-direct-call-default() {
	let $file := tsseealso:doc("authority-files", "AT1129MMFrank")
	return deep-equal(item2:seeAlsoOptions($file, "authority-files"), item2:seeAlsoOptionsDefault($file))
};

declare %test:assertTrue function tsseealso:manuscripts-keywords-fixture-has-term-key() {
	exists(tsseealso:doc("manuscripts", "AG00001")//t:term/@key)
};

declare %test:assertXPath("exists($result)") function tsseealso:manuscripts-keywords-optgroup-present() {
	item2:seeAlsoOptionsManuscripts(tsseealso:doc("manuscripts", "AG00001"))[@label = "keywords"]
};

declare %test:assertTrue function tsseealso:works-author-fixture-has-creator-relation() {
	exists(tsseealso:doc("works", "LIT3309Qerellos")//t:relation[@name eq "dcterms:creator"])
};

declare %test:assertXPath("exists($result)") function tsseealso:works-author-optgroup-present() {
	item2:seeAlsoOptionsWorks(tsseealso:doc("works", "LIT3309Qerellos"))[@label = "author"]
};

declare %test:assertTrue function tsseealso:persons-role-fixture-has-rolename() {
	exists(tsseealso:doc("persons", "PRS8692segeDen")//t:roleName)
};

declare %test:assertXPath("exists($result)") function tsseealso:persons-role-optgroup-present() {
	item2:seeAlsoOptionsPersons(tsseealso:doc("persons", "PRS8692segeDen"))[@label = "role"]
};

(:
 : item2:RestSeeAlsoTemplate is the templates:apply adapter item2:RestItem
 : now calls instead of item2:RestSeeAlso directly - confirms the adapter
 : produces the exact same output as the plain call it replaces.
 :)
declare %test:assertTrue function tsseealso:template-adapter-matches-direct-call() {
	let $file := tsseealso:doc("places", "LOC3080Ferheb")
	return deep-equal(
		item2:RestSeeAlsoTemplate(<div />, map {"this": $file, "collection": "places"}),
		item2:RestSeeAlso($file, "places")
	)
};
