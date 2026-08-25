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

declare %test:assertTrue function tsviauth:renders-maindata-wrapper() {
	contains(tsviauth:render(tsviauth:doc("AT1129MMFrank")), 'id="MainData"')
};

declare %test:assertTrue function tsviauth:renders-bibliography-header() {
	contains(tsviauth:render(tsviauth:doc("AT1129MMFrank")), "w3-text-white")
};

declare %test:assertTrue function tsviauth:renders-keyword-link() {
	contains(tsviauth:render(tsviauth:doc("AT1129MMFrank")), "authority-files/list?keyword=AT1129MMFrank")
};

declare %test:assertTrue function tsviauth:renders-attestations-button() {
	contains(tsviauth:render(tsviauth:doc("AT1129MMFrank")), 'data-value="term"')
};

declare %test:assertTrue function tsviauth:renders-relsinfo-block() {
	contains(tsviauth:render(tsviauth:doc("AT1129MMFrank")), "w3-tiny")
};

declare %test:assertTrue function tsviauth:renders-standards-section() {
	contains(tsviauth:render(tsviauth:doc("AT1129MMFrank")), "Publication Statement")
};
