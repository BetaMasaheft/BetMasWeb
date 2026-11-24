xquery version "3.1" encoding "UTF-8";

(:~
 : titles:tei-by-main-id — structural id() lookup (speed-plan 1.3d).
 : Directional @:8082 warm (8 known ids): //@xml:id ~20 ms vs id() ~2 ms
 : (warm-only; reconfirm on fresh eXist before treating as proven).
 :)
module namespace tstitlesid = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-titlesdata-tei-by-id";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";

declare
	%test:name("tei-by-main-id hits known person TEI") %test:assertEquals("PRS11021Entones")
function tstitlesid:known-person() {
	string(titles:tei-by-main-id("PRS11021Entones")/@xml:id)
};

declare
	%test:name("tei-by-main-id hits known manuscript TEI") %test:assertEquals("AG00001")
function tstitlesid:known-mss() {
	string(titles:tei-by-main-id("AG00001")/@xml:id)
};

declare %test:name("tei-by-main-id miss is empty") %test:assertEmpty function tstitlesid:miss() {
	titles:tei-by-main-id("LITTESTtitlesDataIdLookupDoesNotExist77")
};

declare
	%test:name("tei-by-main-id equals //@xml:id for sample set") %test:assertEquals(0)
function tstitlesid:parity-with-xpath-scan() {
	let $bm := collection("/db/apps/BetMasData")
	let $ids := ("PRS11021Entones", "AG00001", "LIT1923Mashaf", "BNFabb91", "LIT2317Senodo", "LOC1001Aallee")
	return count(
		for $id in $ids
		let $via-id := titles:tei-by-main-id($id, $bm)
		let $via-xpath := $bm//t:TEI[@xml:id = $id]
		where not(deep-equal($via-id/@xml:id/string(), $via-xpath/@xml:id/string()))
		return $id
	)
};

declare
	%test:name("printTitleMainID still resolves after id() lookup") %test:assertEquals("ʾƎnṭonǝs (Antoine)")
function tstitlesid:printTitleMainID-still-works() {
	string(titles:printTitleMainID("PRS11021Entones"))
};
