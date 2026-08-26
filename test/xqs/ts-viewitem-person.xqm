xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/viewItem.xqm's html-templating conversion of
 : the "pers" body render - viewItem:person($item) calls
 : templates:apply(templates/itemPerson.html, ...) instead of building the
 : element tree inline.
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :
 : Written and confirmed passing against the pre-conversion viewItem:person
 : first (same TDD-for-a-refactor discipline as the other ts-viewitem-*
 : test modules), then re-confirmed after the conversion.
 :)
module namespace tsviperson = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-person";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare %private function tsviperson:doc($id as xs:string) as element()? {
	collection("/db/apps/expanded/persons")//t:TEI[@xml:id = $id]
};

(:
 : Following ts-viewitem-place.xqm's documented finding: live XPath on
 : templates:apply's returned node sequence is unreliable in this eXist
 : version, so assertions go through serialize()-then-contains() rather
 : than querying the live result.
 :
 : Following ts-viewitem-work.xqm's documented finding: bare <h2>/<h3>/<h4>
 : elements returned by non-wrap section functions pick up a stray
 : xmlns="" attribute when serialized standalone like this (invisible in
 : the real page, where they're part of the whole xhtml-namespaced
 : document instead), so heading assertions use `>Text<` rather than
 : `<h3>Text</h3>`.
 :)
declare %private function tsviperson:render($item as element()) as xs:string {
	string-join(
		for $x in viewItem:person($item)
		return serialize($x)
	)
};

declare %test:assertXPath("contains($result, 'id=&quot;MainData&quot;')") function tsviperson:renders-maindata-wrapper() {
	tsviperson:render(tsviperson:doc("PRS8278SablaWa"))
};

declare %test:assertTrue function tsviperson:names-heading-fixture-has-persname() {
	exists(tsviperson:doc("PRS8278SablaWa")//(t:personGrp | t:person)/t:persName)
};

declare %test:assertXPath("contains($result, '>Names<')") function tsviperson:renders-names-heading() {
	tsviperson:render(tsviperson:doc("PRS8278SablaWa"))
};

declare %test:assertXPath("contains($result, 'id=&quot;history&quot;')") function tsviperson:renders-history-section() {
	tsviperson:render(tsviperson:doc("PRS8278SablaWa"))
};

declare %test:assertTrue function tsviperson:notes-section-fixture-has-note() {
	exists(tsviperson:doc("PRS8663Sebastia")//t:person/t:note)
};

declare %test:assertXPath("contains($result, 'w3-container')") function tsviperson:renders-notes-section() {
	tsviperson:render(tsviperson:doc("PRS8663Sebastia"))
};

declare %test:assertTrue function tsviperson:sameas-fixture-has-sameas-attribute() {
	exists(tsviperson:doc("PRS8083Raphael")//t:person/@sameAs)
};

declare %test:assertXPath("contains($result, 'icon-vcard')") function tsviperson:renders-sameas-link-in-sidebar-heading() {
	tsviperson:render(tsviperson:doc("PRS8083Raphael"))
};

declare %test:assertTrue function tsviperson:dates-fixture-has-dated-birth-or-death() {
	exists(tsviperson:doc("PRS8787Severian")//(t:birth | t:death)[@when or @notBefore or @notAfter])
};

declare %test:assertXPath("contains($result, '>Dates')") function tsviperson:renders-dates-section() {
	tsviperson:render(tsviperson:doc("PRS8787Severian"))
};

declare %test:assertTrue function tsviperson:residence-fixture-has-residence() {
	exists(tsviperson:doc("PRS8692segeDen")//t:residence)
};

declare %test:assertXPath("contains($result, 'id=&quot;residence&quot;')") function tsviperson:renders-residence-section() {
	tsviperson:render(tsviperson:doc("PRS8692segeDen"))
};

declare %test:assertXPath("contains($result, '>Author of<')") function tsviperson:renders-authorship-relation-section() {
	tsviperson:render(tsviperson:doc("PRS6378Ludolf"))
};

declare %test:assertXPath("contains($result, 'id=&quot;bibliography&quot;')") function tsviperson:renders-bibliography-section() {
	tsviperson:render(tsviperson:doc("PRS8278SablaWa"))
};

declare %test:assertXPath("contains($result, 'Publication Statement')") function tsviperson:renders-standards-section() {
	tsviperson:render(tsviperson:doc("PRS8278SablaWa"))
};

declare %test:assertXPath("contains($result, 'data-value=&quot;person&quot;')") function tsviperson:renders-attestations-button() {
	tsviperson:render(tsviperson:doc("PRS8278SablaWa"))
};

declare %test:assertXPath("contains($result, 'class=&quot;w3-hide&quot;')") function tsviperson:renders-resp-section() {
	tsviperson:render(tsviperson:doc("PRS8278SablaWa"))
};
