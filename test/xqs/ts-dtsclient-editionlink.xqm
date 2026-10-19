xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for dtsc:editionHref / dtsc:editionLink (modules/dtsclient.xqm).
 :
 : The "Editions and translations" bar on the text tab linked each DTS
 : member's canonical @id (https://betamasaheft.eu/…), which left the
 : deployment for production. BM members must resolve to this host's text
 : tab with the edition selected; external DTS members stay as they are.
 :
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/161
 :)
module namespace tsdtscedlink = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-dtsclient-editionlink";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace dtsc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtsc" at "../../modules/dtsclient.xqm";

declare %test:assertTrue function tsdtscedlink:edition-urn-maps-to-local-text-tab() {
	dtsc:editionHref($config:BMurl || "LIT1709Kebran_ED_traces", "works") eq
		$config:appUrl || "/works/LIT1709Kebran/text?edition=_ED_traces"
};

declare %test:assertTrue function tsdtscedlink:translation-urn-keeps-suffix() {
	dtsc:editionHref($config:BMurl || "LIT2170Peripl_TR_", "works") eq
		$config:appUrl || "/works/LIT2170Peripl/text?edition=_TR_"
};

declare %test:assertTrue function tsdtscedlink:work-urn-without-edition-has-no-query() {
	dtsc:editionHref($config:BMurl || "LIT1709Kebran", "works") eq $config:appUrl || "/works/LIT1709Kebran/text"
};

(:~
 : Without a collection the path segment comes from the id prefix, as the
 : controller's {id}_ED_x.ref redirect does.
 :)
declare %test:assertTrue function tsdtscedlink:collection-derived-from-prefix-when-absent() {
	dtsc:editionHref($config:BMurl || "BNFet32_ED_", ()) eq $config:appUrl || "/manuscripts/BNFet32/text?edition=_ED_"
};

declare
	%test:assertEquals("https://dts.example.org/api/dts/collections?id=urn:cts:x")
function tsdtscedlink:external-id-unchanged() {
	dtsc:editionHref("https://dts.example.org/api/dts/collections?id=urn:cts:x", "works")
};

declare %test:assertEmpty function tsdtscedlink:empty-id-is-empty() {
	dtsc:editionHref((), "works")
};

declare %test:assertEmpty function tsdtscedlink:local-link-opens-in-same-tab() {
	dtsc:editionLink(map {"@id": $config:BMurl || "LIT1709Kebran_ED_rhced", "title": "rhced"}, "works")/@target
};

declare %test:assertEquals("_blank") function tsdtscedlink:external-link-opens-new-tab() {
	string(dtsc:editionLink(map {"@id": "https://dts.example.org/x", "title": "x"}, ())/@target)
};

declare %test:assertEquals("Kebra Nagast") function tsdtscedlink:link-text-is-member-title() {
	string(dtsc:editionLink(map {"@id": $config:BMurl || "LIT1709Kebran_ED_rhced", "title": "Kebra Nagast"}, "works"))
};
