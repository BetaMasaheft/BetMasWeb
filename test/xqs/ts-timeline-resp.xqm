xquery version "3.1" encoding "UTF-8";

(:~
 : tl:resp must not use collection()/id($token) for non-bm: responsibility
 : tokens. Duplicate @xml:id values (e.g. editor "DN" on many respStmt) make
 : id() multi-valued; feeding that into exptit:printTitle → printTitleID
 : raises XPTY0004 (Documentation#3401, manuscripts/BNFet116/main).
 :
 : Catalog-path fix: printTitleID(string($token)) — one string, catalog backend.
 :)
module namespace tstlresp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-timeline-resp";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "../../modules/exptit.xqm";
import module namespace tl = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/timeline" at "../../modules/timeline.xqm";

(: Live-data precondition: "DN" is massively non-unique under id(). :)
declare %test:assertTrue function tstlresp:id-DN-is-ambiguous() {
	count(collection($config:data-rootPr)/id("DN")) gt 1
};

(: Old pattern (what timeline.xqm did): multi-node id() into printTitle throws. :)
declare %test:assertTrue function tstlresp:printTitle-via-id-DN-throws() {
	try {
		let $_ := normalize-space(exptit:printTitle(collection($config:data-rootPr)/id("DN")))
		return false()
	} catch * { contains($err:description, "XPTY0004") or contains(string($err:code), "XPTY0004") }
};

(: Catalog path: single string into printTitleID must not throw. :)
declare %test:assertTrue function tstlresp:printTitleID-DN-string-ok() {
	try {
		let $_ := string(exptit:printTitleID("DN"))
		return true()
	} catch * { false() }
};

(: tl:resp must survive ambiguous editor tokens (regression for BNFet116). :)
declare %test:assertTrue function tstlresp:resp-DN-does-not-throw() {
	try {
		let $_ := string(tl:resp("DN"))
		return true()
	} catch * { false() }
};

(: Known entity id still resolves to a non-empty label via catalog. :)
declare %test:assertTrue function tstlresp:resp-person-has-text() {
	string-length(normalize-space(string(tl:resp("PRS11160HabtaS")))) gt 0
};
