xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/viewItem.xqm's html-templating conversion of
 : the "auth" body render - viewItem:auth($item) calls
 : templates:apply(templates/itemAuth.html, ...) instead of building the
 : element tree inline.
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :
 : Written and confirmed passing against the pre-conversion viewItem:auth
 : first (same TDD-for-a-refactor discipline as ts-viewitem-place.xqm),
 : then re-confirmed after the conversion.
 :)
module namespace tsviauth = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-auth";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare %private function tsviauth:doc($id as xs:string) as element()? {
	collection("/db/apps/expanded/authority-files")//t:TEI[@xml:id = $id]
};

(:
 : Following ts-viewitem-place.xqm's documented finding: live XPath on
 : templates:apply's returned node sequence is unreliable in this eXist
 : version, so assertions go through serialize()-then-contains() rather
 : than querying the live result.
 :)
declare %private function tsviauth:render($item as element()) as xs:string {
	string-join(
		for $x in viewItem:auth($item)
		return serialize($x)
	)
};

declare %test:assertXPath("contains($result, 'id=&quot;MainData&quot;')") function tsviauth:renders-maindata-wrapper() {
	tsviauth:render(tsviauth:doc("AT1129MMFrank"))
};

declare %test:assertXPath("contains($result, 'w3-text-white')") function tsviauth:renders-bibliography-header() {
	tsviauth:render(tsviauth:doc("AT1129MMFrank"))
};

declare %test:assertXPath("contains($result, 'authority-files/list?keyword=AT1129MMFrank')") function tsviauth:renders-keyword-link() {
	tsviauth:render(tsviauth:doc("AT1129MMFrank"))
};

declare %test:assertXPath("contains($result, 'data-value=&quot;term&quot;')") function tsviauth:renders-attestations-button() {
	tsviauth:render(tsviauth:doc("AT1129MMFrank"))
};

declare %test:assertXPath("contains($result, 'w3-tiny')") function tsviauth:renders-relsinfo-block() {
	tsviauth:render(tsviauth:doc("AT1129MMFrank"))
};

declare %test:assertXPath("contains($result, 'Publication Statement')") function tsviauth:renders-standards-section() {
	tsviauth:render(tsviauth:doc("AT1129MMFrank"))
};
