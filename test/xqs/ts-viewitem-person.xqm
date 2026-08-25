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

declare %test:assertTrue function tsviperson:renders-maindata-wrapper() {
	contains(tsviperson:render(tsviperson:doc("PRS8278SablaWa")), 'id="MainData"')
};

declare %test:assertTrue function tsviperson:renders-names-heading() {
	let $item := tsviperson:doc("PRS8278SablaWa")
	return exists($item//(t:personGrp | t:person)/t:persName) and contains(tsviperson:render($item), ">Names<")
};

declare %test:assertTrue function tsviperson:renders-history-section() {
	let $item := tsviperson:doc("PRS8278SablaWa")
	return contains(tsviperson:render($item), 'id="history"')
};

declare %test:assertTrue function tsviperson:renders-notes-section() {
	let $item := tsviperson:doc("PRS8663Sebastia")
	return exists($item//t:person/t:note) and contains(tsviperson:render($item), "w3-container")
};

declare %test:assertTrue function tsviperson:renders-sameas-link-in-sidebar-heading() {
	let $item := tsviperson:doc("PRS8083Raphael")
	return exists($item//t:person/@sameAs) and contains(tsviperson:render($item), "icon-vcard")
};

declare %test:assertTrue function tsviperson:renders-dates-section() {
	let $item := tsviperson:doc("PRS8787Severian")
	return exists($item//(t:birth | t:death)[@when or @notBefore or @notAfter]) and
		contains(tsviperson:render($item), ">Dates")
};

declare %test:assertTrue function tsviperson:renders-residence-section() {
	let $item := tsviperson:doc("PRS8692segeDen")
	return exists($item//t:residence) and contains(tsviperson:render($item), 'id="residence"')
};

declare %test:assertTrue function tsviperson:renders-authorship-relation-section() {
	let $item := tsviperson:doc("PRS6378Ludolf")
	return contains(tsviperson:render($item), ">Author of<")
};

declare %test:assertTrue function tsviperson:renders-bibliography-section() {
	contains(tsviperson:render(tsviperson:doc("PRS8278SablaWa")), 'id="bibliography"')
};

declare %test:assertTrue function tsviperson:renders-standards-section() {
	contains(tsviperson:render(tsviperson:doc("PRS8278SablaWa")), "Publication Statement")
};

declare %test:assertTrue function tsviperson:renders-attestations-button() {
	contains(tsviperson:render(tsviperson:doc("PRS8278SablaWa")), 'data-value="person"')
};

declare %test:assertTrue function tsviperson:renders-resp-section() {
	contains(tsviperson:render(tsviperson:doc("PRS8278SablaWa")), 'class="w3-hide"')
};
