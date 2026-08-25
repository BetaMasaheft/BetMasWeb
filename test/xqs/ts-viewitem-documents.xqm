xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/viewItem.xqm's html-templating conversion of
 : viewItem:documents($doc) - called both from the "corpus" fallback case
 : of viewItem:main (via viewItem:corpus, a thin one-line delegate not
 : itself converted) and directly from restviews/items.xqm and
 : permanentItems.xqm for the "documents" analytic view of manuscript
 : content fragments ($doc here is not a whole t:TEI document, but an
 : arbitrary fragment - typically a t:item - found by id() lookup inside
 : one).
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :
 : Written and confirmed passing against the pre-conversion
 : viewItem:documents first (same TDD-for-a-refactor discipline as the
 : other ts-viewitem-* test modules), then re-confirmed after the
 : conversion.
 :)
module namespace tsvidocs = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-documents";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare %private function tsvidocs:fragment($rootId as xs:string, $itemId as xs:string) as element()? {
	collection("/db/apps/expanded")//t:TEI[@xml:id = $rootId]//t:item[@xml:id = $itemId]
};

(:
 : Following ts-viewitem-place.xqm's documented finding: live XPath on
 : templates:apply's returned node sequence is unreliable in this eXist
 : version, so assertions go through serialize()-then-contains() rather
 : than querying the live result.
 :)
declare %private function tsvidocs:render($doc as element()) as xs:string {
	string-join(
		for $x in viewItem:documents($doc)
		return serialize($x)
	)
};

declare %test:assertTrue function tsvidocs:renders-container-wrapper() {
	contains(tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1")), "w3-container")
};

declare %test:assertTrue function tsvidocs:renders-resume-note() {
	let $doc := tsvidocs:fragment("BNFabb152", "a1")
	return exists($doc/t:note[@type = "résumé"]) and contains(tsvidocs:render($doc), "w3-margin-bottom w3-red")
};

declare %test:assertTrue function tsvidocs:renders-gez-q() {
	let $doc := tsvidocs:fragment("BNFabb152", "a1")
	return exists($doc/t:q[@xml:lang = "gez"]) and contains(tsvidocs:render($doc), 'lang="gez"')
};

declare %test:assertTrue function tsvidocs:renders-footnotes() {
	let $doc := tsvidocs:fragment("BNFabb152", "a1")
	return exists($doc/t:note[@n][@xml:id]) and contains(tsvidocs:render($doc), 'class="footnotes"')
};

declare %test:assertTrue function tsvidocs:renders-other-notes() {
	let $doc := tsvidocs:fragment("BNFabb152", "a1")
	return exists($doc/t:note[not(@n)][not(@xml:id)][not(@type = "résumé")]) and
		contains(tsvidocs:render($doc), "w3-third w3-padding w3-card-4 w3-gray")
};

declare %test:assertTrue function tsvidocs:renders-date() {
	let $doc := tsvidocs:fragment("BNFabb152", "a21")
	return exists($doc/t:date) and contains(tsvidocs:render($doc), "w3-tag w3-gray")
};

declare %test:assertTrue function tsvidocs:renders-other-language-q() {
	let $doc := tsvidocs:fragment("MNC019", "a1")
	return exists($doc/t:q[not(@xml:lang = "gez")]) and contains(tsvidocs:render($doc), "ጊዮርጊስ")
};

declare %test:assertTrue function tsvidocs:renders-bibliography() {
	let $doc := tsvidocs:fragment("RNBdorn612", "a1")
	return exists($doc/t:listBibl) and contains(tsvidocs:render($doc), "Turaev")
};

declare %test:assertTrue function tsvidocs:renders-trailing-hr() {
	contains(tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1")), "<hr")
};

(:
 : viewItem:corpus is a one-line delegate to viewItem:documents, not
 : itself converted - this confirms the delegation still holds.
 :)
declare %test:assertTrue function tsvidocs:corpus-matches-documents() {
	let $doc := tsvidocs:fragment("BNFabb152", "a1")
	return deep-equal(viewItem:corpus($doc), viewItem:documents($doc))
};
