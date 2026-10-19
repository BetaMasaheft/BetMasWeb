xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for config:isLocalHref (modules/config.xqm).
 :
 : $config:appUrl is empty in dev/CI containers, where links mapped by
 : viewItem:entityHref or dtsc:editionHref are root-relative. A plain
 : starts-with($href, $config:appUrl) is then true for every link, so
 : external links lost target="_blank" and were labelled as local records.
 :)
module namespace tslocalhref = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-config-islocalhref";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

declare %test:assertTrue function tslocalhref:root-relative-is-local-without-appurl() {
	config:isLocalHref("/works/LIT1709Kebran/text", "")
};

declare %test:assertFalse function tslocalhref:absolute-is-external-without-appurl() {
	config:isLocalHref("https://dts.example.org/x", "")
};

declare %test:assertFalse function tslocalhref:protocol-relative-is-external() {
	config:isLocalHref("//dts.example.org/x", "")
};

declare %test:assertTrue function tslocalhref:appurl-prefixed-is-local() {
	config:isLocalHref("http://localhost:8080/LIT1709Kebran", "http://localhost:8080")
};

declare %test:assertFalse function tslocalhref:other-host-is-external() {
	config:isLocalHref("https://www.wikidata.org/entity/Q220", "http://localhost:8080")
};

declare %test:assertFalse function tslocalhref:appurl-as-prefix-of-other-host-is-external() {
	config:isLocalHref("http://localhost:80801/x", "http://localhost:8080")
};

declare %test:assertFalse function tslocalhref:empty-is-not-local() {
	config:isLocalHref((), "")
};
