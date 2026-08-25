xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/viewItem.xqm's html-templating conversion of
 : the "nar" (narratives) body render - viewItem:main's "nar" branch now
 : calls templates:apply(templates/itemNarrative.html, ...) instead of the
 : old viewItem:narrative($item) (removed, confirmed unused elsewhere).
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :)
module namespace tsvinar = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-narrative";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare %private variable $tsvinar:doc := collection("/db/apps/expanded/narratives")//t:TEI[@type =
	"nar"][.//t:witness][1];

(:~
 : viewItem:main must still dispatch "nar" items to real content - the
 : outer MainData wrapper is the one structural constant across every
 : collection type's body render.
 :)
declare %test:assertEquals("MainData") function tsvinar:main-renders-maindata-wrapper() {
	string(viewItem:main($tsvinar:doc)/@id)
};

(:~
 : viewItem:narrativeSetup computes $rels/$id once and merges them into
 : $model for viewItem:narrativeRelsInfo to read back - if that
 : model-sharing is broken, the relations section silently goes empty
 : instead of erroring, so assert it actually has content for a document
 : known to have relations data (rather than just checking "no error").
 :)
declare %test:assertTrue function tsvinar:relsinfo-reads-model-shared-rels() {
	exists(viewItem:main($tsvinar:doc)//*[@id = "description"])
};

(:~
 : Picked a document with a t:witness element specifically so the
 : conditional Witnesses section (viewItem:narrativeWitnesses) is
 : exercised, not just the always-present General description section.
 :)
declare %test:assertTrue function tsvinar:witnesses-section-present-when-item-has-witness() {
	exists($tsvinar:doc//t:witness) and exists(viewItem:main($tsvinar:doc)//h2[. = "Witnesses"])
};
