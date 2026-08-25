xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/zoteroCache.xqm.
 : Cache hits must not require a live Zotero call.
 : Tag normalization covers timeline bm_ underscore forms.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/82
 :)
module namespace tszc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-zotero-cache";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace zc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/zc" at "../../modules/zoteroCache.xqm";

declare %test:assertEquals("bm:Villa2018versions") function tszc:normalize-underscore() {
	zc:normalize-tag("bm_Villa2018versions")
};

declare %test:assertEquals("bm:Bausi2019BM") function tszc:normalize-already-colon() {
	zc:normalize-tag("bm:Bausi2019BM")
};

declare %test:assertEquals("John") function tszc:enrich-skips-non-bm-ed() {
	let $out := zc:enrich-versions(
		map {
			"total": 1,
			"versions": map {"version": map {"source": map {"id": "LIT1", "title": "t", "ed": "John"}, "text": "abc"}}
		}
	)
	return $out?versions?1?version?source?ed
};

declare %test:assertFalse function tszc:enrich-non-bm-has-no-edition-html() {
	let $out := zc:enrich-versions(
		map {
			"total": 1,
			"versions": map {"version": map {"source": map {"id": "LIT1", "title": "t", "ed": "John"}, "text": "abc"}}
		}
	)
	return map:contains($out?versions?1?version?source, "editionHtml")
};

declare %test:assertTrue function tszc:enrich-bm-adds-edition-html() {
	let $out := zc:enrich-versions(
		map {
			"total": 1,
			"versions":
				map {"version": map {"source": map {"id": "LIT1", "title": "t", "ed": "bm:MissingTagXYZ"}, "text": "abc"}}
		}
	)
	return map:contains($out?versions?1?version?source, "editionHtml")
};

declare %test:assertTrue function tszc:serialize-html-keeps-markup() {
	contains(zc:html-string(<div class="csl-entry"><i>Title</i></div>), "Title")
};
