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

declare %test:assertXPath("contains($result, 'w3-container')") function tsvidocs:renders-container-wrapper() {
	tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1"))
};

declare %test:assertTrue function tsvidocs:resume-note-fixture-has-resume-note() {
	exists(tsvidocs:fragment("BNFabb152", "a1")/t:note[@type = "résumé"])
};

declare %test:assertXPath("contains($result, 'w3-margin-bottom w3-red')") function tsvidocs:renders-resume-note() {
	tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1"))
};

declare %test:assertTrue function tsvidocs:gez-q-fixture-has-gez-q() {
	exists(tsvidocs:fragment("BNFabb152", "a1")/t:q[@xml:lang = "gez"])
};

declare %test:assertXPath("contains($result, 'lang=&quot;gez&quot;')") function tsvidocs:renders-gez-q() {
	tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1"))
};

declare %test:assertTrue function tsvidocs:footnotes-fixture-has-footnote() {
	exists(tsvidocs:fragment("BNFabb152", "a1")/t:note[@n][@xml:id])
};

declare %test:assertXPath("contains($result, 'class=&quot;footnotes&quot;')") function tsvidocs:renders-footnotes() {
	tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1"))
};

declare %test:assertTrue function tsvidocs:other-notes-fixture-has-plain-note() {
	exists(tsvidocs:fragment("BNFabb152", "a1")/t:note[not(@n)][not(@xml:id)][not(@type = "résumé")])
};

declare %test:assertXPath("contains($result, 'w3-third w3-padding w3-card-4 w3-gray')") function tsvidocs:renders-other-notes() {
	tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1"))
};

declare %test:assertTrue function tsvidocs:date-fixture-has-date() {
	exists(tsvidocs:fragment("BNFabb152", "a21")/t:date)
};

declare %test:assertXPath("contains($result, 'w3-tag w3-gray')") function tsvidocs:renders-date() {
	tsvidocs:render(tsvidocs:fragment("BNFabb152", "a21"))
};

declare %test:assertTrue function tsvidocs:other-language-q-fixture-has-non-gez-q() {
	exists(tsvidocs:fragment("MNC019", "a1")/t:q[not(@xml:lang = "gez")])
};

declare %test:assertXPath("contains($result, 'ጊዮርጊስ')") function tsvidocs:renders-other-language-q() {
	tsvidocs:render(tsvidocs:fragment("MNC019", "a1"))
};

declare %test:assertTrue function tsvidocs:bibliography-fixture-has-listbibl() {
	exists(tsvidocs:fragment("RNBdorn612", "a1")/t:listBibl)
};

declare %test:assertXPath("contains($result, 'Turaev')") function tsvidocs:renders-bibliography() {
	tsvidocs:render(tsvidocs:fragment("RNBdorn612", "a1"))
};

declare %test:assertXPath("contains($result, '<hr')") function tsvidocs:renders-trailing-hr() {
	tsvidocs:render(tsvidocs:fragment("BNFabb152", "a1"))
};

(:
 : viewItem:corpus is a one-line delegate to viewItem:documents, not
 : itself converted - this confirms the delegation still holds.
 :)
declare %test:assertTrue function tsvidocs:corpus-matches-documents() {
	let $doc := tsvidocs:fragment("BNFabb152", "a1")
	return deep-equal(viewItem:corpus($doc), viewItem:documents($doc))
};
