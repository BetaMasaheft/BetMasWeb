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

declare %test:assertXPath("contains($result, 'id=&quot;MainData&quot;')") function tsviwork:renders-maindata-wrapper() {
	tsviwork:render(tsviwork:doc("LIT3508Epistle"))
};

declare %test:assertTrue function tsviwork:titles-fixture-has-titled-title() {
	exists(tsviwork:doc("LIT3508Epistle")//t:titleStmt/t:title[@xml:id])
};

declare %test:assertXPath("contains($result, '>Titles<')") function tsviwork:renders-titles-heading() {
	tsviwork:render(tsviwork:doc("LIT3508Epistle"))
};

declare %test:assertTrue function tsviwork:source-desc-fixture-has-paragraph() {
	exists(tsviwork:doc("LIT3508Epistle")//t:sourceDesc/t:p)
};

declare
	%test:assertXPath("contains($result, 'Work of the literatures of Ethiopia and Eritrea')")
function tsviwork:renders-source-desc-paragraph() {
	tsviwork:render(tsviwork:doc("LIT3508Epistle"))
};

declare %test:assertTrue function tsviwork:voyant-fixture-has-edition-text() {
	exists(tsviwork:doc("LIT3508Epistle")//t:div[@type = "edition"]//t:ab//text())
};

declare %test:assertXPath("contains($result, 'voyant-tools.org')") function tsviwork:renders-voyant-link() {
	tsviwork:render(tsviwork:doc("LIT3508Epistle"))
};

declare %test:assertTrue function tsviwork:witnesses-fixture-has-listwit() {
	exists(tsviwork:doc("LIT3192Tergwam")//t:listWit)
};

declare %test:assertXPath("contains($result, '>Witnesses<')") function tsviwork:renders-witnesses-heading() {
	tsviwork:render(tsviwork:doc("LIT3192Tergwam"))
};

declare %test:assertTrue function tsviwork:clavis-fixture-has-clavis-listbibl() {
	exists(tsviwork:doc("LIT3881Miracle")//t:listBibl[@type = "clavis"])
};

declare
	%test:assertXPath("contains($result, 'id=&quot;clavisbibliography&quot;')")
function tsviwork:renders-clavis-bibliography() {
	tsviwork:render(tsviwork:doc("LIT3881Miracle"))
};

declare %test:assertTrue function tsviwork:creation-date-fixture-has-dated-creation() {
	exists(tsviwork:doc("LIT3944ArdeetChL")//t:creation[@when or @notBefore or @notAfter])
};

declare %test:assertXPath("contains($result, 'Creation date')") function tsviwork:renders-creation-date() {
	tsviwork:render(tsviwork:doc("LIT3944ArdeetChL"))
};

declare %test:assertTrue function tsviwork:extent-fixture-has-extent() {
	exists(tsviwork:doc("LIT4275ChronAmdS")//t:extent)
};

declare %test:assertXPath("contains($result, '10170 words')") function tsviwork:renders-extent-paragraph() {
	tsviwork:render(tsviwork:doc("LIT4275ChronAmdS"))
};

declare %test:assertTrue function tsviwork:authorship-fixture-is-studies-type() {
	tsviwork:doc("STU0002Historia")/@type = "studies"
};

declare
	%test:assertXPath("contains($result, '>Authorship<')")
function tsviwork:renders-authorship-for-studies-type-item() {
	tsviwork:render(tsviwork:doc("STU0002Historia"))
};

declare
	%test:assertXPath("contains($result, 'data-value=&quot;work&quot;')")
function tsviwork:renders-attestations-button() {
	tsviwork:render(tsviwork:doc("LIT3508Epistle"))
};

declare %test:assertXPath("contains($result, 'class=&quot;w3-hide&quot;')") function tsviwork:renders-resp-section() {
	tsviwork:render(tsviwork:doc("LIT3508Epistle"))
};
