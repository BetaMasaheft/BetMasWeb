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

declare %test:assertXPath("contains($result, 'id=&quot;MainData&quot;')") function tsvimss:renders-maindata-wrapper() {
	tsvimss:render(tsvimss:doc("MNC010"))
};

declare %test:assertXPath("contains($result, 'data-value=&quot;mss&quot;')") function tsvimss:renders-attestations-button() {
	tsvimss:render(tsvimss:doc("MNC010"))
};

declare %test:assertXPath("contains($result, 'w3-tiny')") function tsvimss:renders-relsinfo-block() {
	tsvimss:render(tsvimss:doc("MNC010"))
};

declare %test:assertXPath("contains($result, 'Publication Statement')") function tsvimss:renders-standards-section() {
	tsvimss:render(tsvimss:doc("MNC010"))
};

declare %test:assertTrue function tsvimss:tweed-fixture-is-in-tweed-collection() {
	exists(tsvimss:doc("EMIP02001")//t:collection[. = "Tweed Collection"])
};

declare %test:assertXPath("contains($result, 'tweed.html')") function tsvimss:tweed-link-present-when-item-in-tweed-collection() {
	tsvimss:render(tsvimss:doc("EMIP02001"))
};

declare %test:assertTrue function tsvimss:no-tweed-fixture-is-not-in-tweed-collection() {
	empty(tsvimss:doc("MNC010")//t:collection[. = "Tweed Collection"])
};

declare %test:assertXPath("not(contains($result, 'tweed.html'))") function tsvimss:tweed-link-absent-when-item-not-in-tweed-collection() {
	tsvimss:render(tsvimss:doc("MNC010"))
};

declare %test:assertXPath("contains($result, 'label-primary')") function tsvimss:dated-heading-present-when-item-has-internal-date() {
	tsvimss:render(tsvimss:doc("MNC014"))
};

declare %test:assertTrue function tsvimss:codicological-units-fixture-has-multiple-parts() {
	count(tsvimss:doc("AG00001")//(t:msPart | t:msFrag)) ge 2
};

declare %test:assertXPath("contains($result, 'label-default')") function tsvimss:codicological-units-renders-badge-class() {
	tsvimss:render(tsvimss:doc("AG00001"))
};

(:~
 : The rendered count is computed at render time, so it can only be
 : checked against another dynamically-computed value - no static
 : literal to hand assertEquals/assertXPath, unlike the tests above.
 :)
declare %test:assertTrue function tsvimss:codicological-units-count-matches-in-rendered-output() {
	let $multiPart := tsvimss:doc("AG00001")
	return contains(tsvimss:render($multiPart), xs:string(count($multiPart//(t:msPart | t:msFrag))))
};
