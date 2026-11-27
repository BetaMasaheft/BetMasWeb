xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for all:lucene-wildcard-too-broad (modules/all.xqm).
 :
 : Short Lucene prefixes (PRS*, LIT*) explode into TooManyClauses once
 : person/place/title fields index dense @ref tokens.
 :)
module namespace tsallwc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-all-lucene-wildcard";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "../../modules/all.xqm";

declare %test:assertFalse function tsallwc:plain-name-ok() {
	all:lucene-wildcard-too-broad("Yohannes")
};

declare %test:assertFalse function tsallwc:long-prefix-ok() {
	all:lucene-wildcard-too-broad("Yoha*")
};

declare %test:assertTrue function tsallwc:short-prefix-rejected() {
	all:lucene-wildcard-too-broad("PRS*")
};

declare %test:assertTrue function tsallwc:lit-prefix-rejected() {
	all:lucene-wildcard-too-broad("LIT*")
};

declare %test:assertTrue function tsallwc:field-scoped-short-prefix() {
	all:lucene-wildcard-too-broad("person:(PRS*)")
};

declare %test:assertTrue function tsallwc:leading-wildcard() {
	all:lucene-wildcard-too-broad("*annes")
};

declare %test:assertFalse function tsallwc:concrete-id-ok() {
	all:lucene-wildcard-too-broad("PRS1854Amdase")
};

declare %test:assertFalse function tsallwc:empty-ok() {
	all:lucene-wildcard-too-broad("")
};

declare %test:assertTrue function tsallwc:titles-form-short-prefix() {
	all:lucene-wildcard-too-broad("LIT*")
};
