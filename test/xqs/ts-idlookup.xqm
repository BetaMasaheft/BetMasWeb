xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for /api/idlookup (restviews/idlookup.xqm).
 :
 : The endpoint matches with contains(@xml:id, $id) across the whole
 : expanded collection. When ?id= is absent the parameter is the empty
 : sequence, and contains("some-id", ()) is true for every node, so a
 : single request matched all ~192,000 id-bearing nodes in the corpus and
 : serialised them as one multi-megabyte JSON payload. A blank ?id= has
 : the same effect.
 :
 : These tests hit the real corpus, as the other query-level suites do:
 : the matching corpus is what the bug is about, and there is no fixture
 : that would exercise the empty-parameter path.
 :)
module namespace tsidlookup = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-idlookup";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace lookID = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lookID" at "../../restviews/idlookup.xqm";

(:
 : An xml:id that exists in the corpus and is specific enough to match
 : only itself, so the exact-lookup tests cannot pass by accident.
 :)
declare variable $tsidlookup:KNOWN-TEI-ID := "LOC5836Tabito";

(:
 : The endpoint answers either with a hits map or, when nothing matched,
 : with a "No results" element - so narrow the map case explicitly rather
 : than letting the lookup operator type-error on the element.
 :)
declare function tsidlookup:hits($parameters as map(*)) as map(*)* {
	let $response := lookID:IDSlookup(map {"parameters": $parameters})
	return typeswitch ($response)
		case map(*) return
			$response?items

		default return
			()
};

declare %test:assertFalse function tsidlookup:missing-id-matches-nothing() {
	exists(tsidlookup:hits(map {}))
};

declare %test:assertFalse function tsidlookup:empty-id-matches-nothing() {
	exists(tsidlookup:hits(map {"id": ""}))
};

declare %test:assertFalse function tsidlookup:blank-id-matches-nothing() {
	exists(tsidlookup:hits(map {"id": "   "}))
};

declare %test:assertTrue function tsidlookup:known-id-matches-itself() {
	let $ids := tsidlookup:hits(map {"id": $tsidlookup:KNOWN-TEI-ID})?id
	return $ids = $tsidlookup:KNOWN-TEI-ID
};
