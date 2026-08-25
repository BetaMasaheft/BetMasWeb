xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/viewItem.xqm's html-templating conversion of
 : the "work"/"studies" body render - viewItem:work($item) calls
 : templates:apply(templates/itemWork.html, ...) instead of building the
 : element tree inline. Both viewItem:main's "work" and "studies" cases
 : delegate to the same viewItem:work, so one conversion covers both.
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :
 : Written and confirmed passing against the pre-conversion viewItem:work
 : first (same TDD-for-a-refactor discipline as the other ts-viewitem-*
 : test modules), then re-confirmed after the conversion.
 :)
module namespace tsviwork = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-work";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

(:
 : "studies"-type docs (also rendered by viewItem:work) live outside the
 : works/ subcollection, so this searches the whole expanded tree rather
 : than assuming a single subcollection like the other ts-viewitem-*
 : helpers do.
 :)
declare %private function tsviwork:doc($id as xs:string) as element()? {
	collection("/db/apps/expanded")//t:TEI[@xml:id = $id]
};

(:
 : Following ts-viewitem-place.xqm's documented finding: live XPath on
 : templates:apply's returned node sequence is unreliable in this eXist
 : version, so assertions go through serialize()-then-contains() rather
 : than querying the live result.
 :
 : One more wrinkle specific to this test file: several viewItem:work*
 : section functions return bare <h2>/<p> elements built with no
 : namespace declared on them, which - only when serialized standalone
 : like this, under no xhtml-namespaced ancestor - picks up a literal
 : xmlns="" attribute (invisible in the real page, where these nodes are
 : serialized as part of the whole xhtml-namespaced document instead).
 : Assertions on heading text use `>Text<` rather than `<h2>Text</h2>`
 : so they don't depend on which attributes happen to be on the tag.
 :)
declare %private function tsviwork:render($item as element()) as xs:string {
	string-join(
		for $x in viewItem:work($item)
		return serialize($x)
	)
};

declare %test:assertTrue function tsviwork:renders-maindata-wrapper() {
	contains(tsviwork:render(tsviwork:doc("LIT3508Epistle")), 'id="MainData"')
};

declare %test:assertTrue function tsviwork:renders-titles-heading() {
	let $item := tsviwork:doc("LIT3508Epistle")
	return exists($item//t:titleStmt/t:title[@xml:id]) and contains(tsviwork:render($item), ">Titles<")
};

declare %test:assertTrue function tsviwork:renders-source-desc-paragraph() {
	let $item := tsviwork:doc("LIT3508Epistle")
	return exists($item//t:sourceDesc/t:p) and
		contains(tsviwork:render($item), "Work of the literatures of Ethiopia and Eritrea")
};

declare %test:assertTrue function tsviwork:renders-voyant-link() {
	let $item := tsviwork:doc("LIT3508Epistle")
	return exists($item//t:div[@type = "edition"]//t:ab//text()) and contains(tsviwork:render($item), "voyant-tools.org")
};

declare %test:assertTrue function tsviwork:renders-witnesses-heading() {
	let $item := tsviwork:doc("LIT3192Tergwam")
	return exists($item//t:listWit) and contains(tsviwork:render($item), ">Witnesses<")
};

declare %test:assertTrue function tsviwork:renders-clavis-bibliography() {
	let $item := tsviwork:doc("LIT3881Miracle")
	return exists($item//t:listBibl[@type = "clavis"]) and contains(tsviwork:render($item), 'id="clavisbibliography"')
};

declare %test:assertTrue function tsviwork:renders-creation-date() {
	let $item := tsviwork:doc("LIT3944ArdeetChL")
	return exists($item//t:creation[@when or @notBefore or @notAfter]) and
		contains(tsviwork:render($item), "Creation date")
};

declare %test:assertTrue function tsviwork:renders-extent-paragraph() {
	let $item := tsviwork:doc("LIT4275ChronAmdS")
	return exists($item//t:extent) and contains(tsviwork:render($item), "<p>")
};

declare %test:assertTrue function tsviwork:renders-authorship-for-studies-type-item() {
	let $item := tsviwork:doc("STU0002Historia")
	return $item/@type = "studies" and contains(tsviwork:render($item), ">Authorship<")
};

declare %test:assertTrue function tsviwork:renders-attestations-button() {
	contains(tsviwork:render(tsviwork:doc("LIT3508Epistle")), 'data-value="work"')
};

declare %test:assertTrue function tsviwork:renders-resp-section() {
	contains(tsviwork:render(tsviwork:doc("LIT3508Epistle")), 'class="w3-hide"')
};
