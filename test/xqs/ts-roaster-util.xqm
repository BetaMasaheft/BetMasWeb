xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/roaster-util.xqm (Roaster response helpers).
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/44
 :)
module namespace tsrutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-roaster-util";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace router = "http://e-editiones.org/roaster/router";
import module namespace rutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/rutil" at "../../modules/roaster-util.xqm";

declare %test:assertTrue function tsrutil:is-response-on-roaster-map() {
	rutil:is-response(
		map {$router:RESPONSE_CODE: 200, $router:RESPONSE_BODY: <TEI xmlns="http://www.tei-c.org/ns/1.0" />}
	)
};

declare %test:assertFalse function tsrutil:is-response-on-tei() {
	rutil:is-response(<TEI xmlns="http://www.tei-c.org/ns/1.0" />)
};

(:~
 : Regression for /works/*/text XPTY0004: XPath must run on unwrapped TEI,
 : not on the Roaster response map.
 :)
declare %test:assertEquals("edition") function tsrutil:body-allows-xpath-on-unwrapped-tei() {
	let $response := map {
		$router:RESPONSE_CODE: 200,
		$router:RESPONSE_HEADERS: map {"Link": "next"},
		$router:RESPONSE_BODY: <TEI xmlns="http://www.tei-c.org/ns/1.0"><div type="edition">edition</div></TEI>
	}
	return string(rutil:body($response)//t:div[@type = "edition"])
};

declare %test:assertEquals("next-link") function tsrutil:header-from-roaster-map() {
	rutil:header(
		map {
			$router:RESPONSE_CODE: 200,
			$router:RESPONSE_HEADERS: map {"Link": "next-link"},
			$router:RESPONSE_BODY: <TEI xmlns="http://www.tei-c.org/ns/1.0" />
		},
		"Link"
	)
};

declare %test:assertEquals("from-http") function tsrutil:header-from-expath-sequence() {
	rutil:header(
		(
			<http:response status="200"><http:header name="Link" value="from-http" /></http:response>,
			<TEI xmlns="http://www.tei-c.org/ns/1.0" />
		),
		"Link"
	)
};
