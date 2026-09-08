xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for viewItem:reflink's prefixDef resolution. Same unanchored
 : fn:replace shape as the ecrm bug fixed in expand:id (BetMasWeb#127):
 : global replace() with an alnum-only matchPattern re-prefixes each
 : underscore-separated run of a CIDOC-CRM local name.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/127
 :)
module namespace tsvireflink = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-reflink";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare
	%test:assertEquals("http://erlangen-crm.org/current/P129_is_about")
function tsvireflink:ecrm-underscored-name-resolves() {
	string(viewItem:reflink("ecrm:P129_is_about"))
};

declare %test:assertFalse function tsvireflink:ecrm-does-not-reprefix-segments() {
	contains(string(viewItem:reflink("ecrm:CLP46i_may_form_part_of")), "_http://")
};

(:~
 : Already-resolved absolute URIs pass through unchanged ("http" has no
 : matching prefixDef).
 :)
declare
	%test:assertEquals("http://erlangen-crm.org/current/P129_is_about")
function tsvireflink:resolved-uri-passes-through() {
	string(viewItem:reflink("http://erlangen-crm.org/current/P129_is_about"))
};

(:~
 : A CURIE local part its prefixDef's matchPattern doesn't match falls back
 : to the raw ref, same as an unknown prefix - never a garbled replace().
 :)
declare %test:assertEquals("dcterms:creator2") function tsvireflink:unmatched-local-part-falls-back-to-raw-ref() {
	string(viewItem:reflink("dcterms:creator2"))
};

declare %test:assertEquals("totallyUnknownPrefix:foo") function tsvireflink:unknown-prefix-falls-back-to-raw-ref() {
	string(viewItem:reflink("totallyUnknownPrefix:foo"))
};
