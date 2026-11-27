xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for all:lucene-wildcard-too-broad (modules/all.xqm).
 :
 : Free-text floor is MIN_PREFIX (3). BM-id prefixes (PRS*, LIT1*) are
 : judged by catalogs/labels.xml fan-out vs maxClauseCount (1024).
 :)
module namespace tsallwc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-all-lucene-wildcard";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "../../modules/all.xqm";

declare %test:assertFalse function tsallwc:plain-name-ok() {
	all:lucene-wildcard-too-broad("Yohannes")
};

declare %test:assertFalse function tsallwc:name-prefix-ok() {
	all:lucene-wildcard-too-broad("Yoh*")
};

declare %test:assertTrue function tsallwc:name-prefix-too-short() {
	all:lucene-wildcard-too-broad("Yo*")
};

declare %test:assertTrue function tsallwc:short-id-prefix-rejected() {
	all:lucene-wildcard-too-broad("PRS*")
};

declare %test:assertTrue function tsallwc:dense-id-prefix-rejected() {
	(: PRS1* ≈ 7k labels — over maxClauseCount even at length 4 :)
	all:lucene-wildcard-too-broad("PRS1*")
};

declare %test:assertFalse function tsallwc:narrow-id-prefix-ok() {
	(: PRS18* ≈ 191 labels — under maxClauseCount :)
	all:lucene-wildcard-too-broad("PRS18*")
};

declare %test:assertTrue function tsallwc:lit-prefix-rejected() {
	all:lucene-wildcard-too-broad("LIT*")
};

declare %test:assertTrue function tsallwc:lit1-prefix-rejected() {
	all:lucene-wildcard-too-broad("LIT1*")
};

declare %test:assertFalse function tsallwc:lit19-prefix-ok() {
	all:lucene-wildcard-too-broad("LIT19*")
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
