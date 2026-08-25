xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/viewItem.xqm's html-templating conversion of
 : the "mss" body render - viewItem:manuscript($item) calls
 : templates:apply(templates/itemManuscript.html, ...) instead of building
 : the element tree inline.
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :
 : Written and confirmed passing against the pre-conversion
 : viewItem:manuscript first (same TDD-for-a-refactor discipline as
 : ts-viewitem-place.xqm and ts-viewitem-auth.xqm), then re-confirmed
 : after the conversion.
 :)
module namespace tsvimss = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-manuscript";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare %private function tsvimss:doc($id as xs:string) as element()? {
	collection("/db/apps/expanded/manuscripts")//t:TEI[@xml:id = $id]
};

(:
 : Following ts-viewitem-place.xqm's documented finding: live XPath on
 : templates:apply's returned node sequence is unreliable in this eXist
 : version, so assertions go through serialize()-then-contains() rather
 : than querying the live result.
 :)
declare %private function tsvimss:render($item as element()) as xs:string {
	string-join(
		for $x in viewItem:manuscript($item)
		return serialize($x)
	)
};

declare %test:assertTrue function tsvimss:renders-maindata-wrapper() {
	contains(tsvimss:render(tsvimss:doc("MNC010")), 'id="MainData"')
};

declare %test:assertTrue function tsvimss:renders-attestations-button() {
	contains(tsvimss:render(tsvimss:doc("MNC010")), 'data-value="mss"')
};

declare %test:assertTrue function tsvimss:renders-relsinfo-block() {
	contains(tsvimss:render(tsvimss:doc("MNC010")), "w3-tiny")
};

declare %test:assertTrue function tsvimss:renders-standards-section() {
	contains(tsvimss:render(tsvimss:doc("MNC010")), "Publication Statement")
};

declare %test:assertTrue function tsvimss:tweed-link-present-when-item-in-tweed-collection() {
	let $tweed := tsvimss:doc("EMIP02001")
	return exists($tweed//t:collection[. = "Tweed Collection"]) and contains(tsvimss:render($tweed), "tweed.html")
};

declare %test:assertTrue function tsvimss:tweed-link-absent-when-item-not-in-tweed-collection() {
	let $noTweed := tsvimss:doc("MNC010")
	return empty($noTweed//t:collection[. = "Tweed Collection"]) and not(contains(tsvimss:render($noTweed), "tweed.html"))
};

declare %test:assertTrue function tsvimss:dated-heading-present-when-item-has-internal-date() {
	let $dated := tsvimss:doc("MNC014")
	return contains(tsvimss:render($dated), "label-primary")
};

declare %test:assertTrue function tsvimss:codicological-units-counted-for-multipart-manuscript() {
	let $multiPart := tsvimss:doc("AG00001")
	let $expected := xs:string(count($multiPart//(t:msPart | t:msFrag)))
	let $rendered := tsvimss:render($multiPart)
	return $expected castable as xs:integer and
		xs:integer($expected) ge 2 and
		contains($rendered, "label-default") and
		contains($rendered, $expected)
};
