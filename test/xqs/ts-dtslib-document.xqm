xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for the dtslib document-content / docs boundary.
 : In-process callers must receive TEI (or error XML), never a Roaster map.
 :)
module namespace tsdtsdoc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-dtslib-document";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace router = "http://e-editiones.org/roaster/router";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace rutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/rutil" at "../../modules/roaster-util.xqm";
import module namespace dtslib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib" at "../../modules/dtslib.xqm";

declare variable $tsdtsdoc:sample-id := $config:BMurl || "LIT1709Kebran";

(:~
 : Validation errors stay as XML for in-process callers (no Roaster map).
 :)
declare %test:assertEquals("error") function tsdtsdoc:content-bad-request-is-xml-error() {
	local-name(dtslib:document-content($tsdtsdoc:sample-id, "1", "2", ""))
};

declare %test:assertFalse function tsdtsdoc:content-bad-request-is-not-roaster-map() {
	rutil:is-response(dtslib:document-content($tsdtsdoc:sample-id, "1", "2", ""))
};

(:~
 : Empty id is invalid for in-process content (HTTP still redirects via docs).
 :)
declare %test:assertEquals("error") function tsdtsdoc:content-empty-id-is-xml-error() {
	local-name(dtslib:document-content("", "", "", ""))
};

declare %test:assertFalse function tsdtsdoc:content-empty-id-is-not-roaster-map() {
	rutil:is-response(dtslib:document-content("", "", "", ""))
};

(:~
 : Happy path: in-process returns TEI; HTTP docs still wraps as Roaster 200.
 :)
declare %test:assertEquals("TEI") function tsdtsdoc:content-happy-path-is-tei() {
	local-name(dtslib:document-content($tsdtsdoc:sample-id, "", "", ""))
};

declare %test:assertXPath("exists($result)") function tsdtsdoc:content-happy-path-has-edition() {
	dtslib:document-content($tsdtsdoc:sample-id, "", "", "")//t:div[@type = "edition"]
};

declare %test:assertTrue function tsdtsdoc:docs-happy-path-response-is-roaster-map() {
	rutil:is-response(dtslib:docs($tsdtsdoc:sample-id, "", "", "", "application/tei+xml"))
};

declare %test:assertEquals(200) function tsdtsdoc:docs-happy-path-status-is-200() {
	dtslib:docs($tsdtsdoc:sample-id, "", "", "", "application/tei+xml")($router:RESPONSE_CODE)
};

declare %test:assertEquals("TEI") function tsdtsdoc:docs-happy-path-body-is-tei() {
	local-name(rutil:body(dtslib:docs($tsdtsdoc:sample-id, "", "", "", "application/tei+xml")))
};

(:~
 : HTTP producer still returns a Roaster response map for bad request.
 :)
declare %test:assertTrue function tsdtsdoc:docs-bad-request-is-roaster-map() {
	rutil:is-response(dtslib:docs($tsdtsdoc:sample-id, "1", "2", "", "application/tei+xml"))
};

declare %test:assertEquals(400) function tsdtsdoc:docs-bad-request-status() {
	dtslib:docs($tsdtsdoc:sample-id, "1", "2", "", "application/tei+xml")($router:RESPONSE_CODE)
};
