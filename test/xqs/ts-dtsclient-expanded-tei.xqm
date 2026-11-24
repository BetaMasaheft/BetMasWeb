xquery version "3.1" encoding "UTF-8";

(:~
 : dtsc:expanded-tei — structural id() on /db/apps/expanded (same shape as
 : titles:tei-by-main-id). Directional @:8082 warm (25 ids): //@xml:id ~56–66 ms
 : vs /id() ~6 ms — reconfirm on fresh eXist before locking the ratio.
 :)
module namespace tsdtscexp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-dtsclient-expanded-tei";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace dtsc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtsc" at "../../modules/dtsclient.xqm";

declare %test:name("expanded-tei hits known manuscript") %test:assertEquals("AG00001") function tsdtscexp:known-mss() {
	string(dtsc:expanded-tei("AG00001")/@xml:id)
};

declare
	%test:name("expanded-tei hits known person") %test:assertEquals("PRS11021Entones")
function tsdtscexp:known-person() {
	string(dtsc:expanded-tei("PRS11021Entones")/@xml:id)
};

declare %test:name("expanded-tei miss is empty") %test:assertEmpty function tsdtscexp:miss() {
	dtsc:expanded-tei("LITTESTdtsclientExpandedTeiDoesNotExist77")
};

declare
	%test:name("expanded-tei equals //@xml:id for sample set") %test:assertEquals(0)
function tsdtscexp:parity-with-xpath-scan() {
	let $exp := collection("/db/apps/expanded")
	let $ids := ("AG00001", "PRS11021Entones", "LIT1923Mashaf", "BNFet32", "LOC1001Aallee")
	return count(
		for $id in $ids
		let $via-id := dtsc:expanded-tei($id)
		let $via-xpath := $exp//t:TEI[@xml:id = $id]
		where not(deep-equal($via-id/@xml:id/string(), $via-xpath/@xml:id/string()))
		return $id
	)
};
