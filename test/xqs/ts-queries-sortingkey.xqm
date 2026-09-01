xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for q:sortingkey (modules/queries.xqm). q:selectors' "rels" branch
 : feeds it exptit:printTitleID()'s return value directly - normally a node,
 : but a tombstoned/deleted record makes printTitleID fall back to a plain
 : xs:string ("PRSxxxxx was permanently deleted"). q:sortingkey's own
 : `$input//text()` step requires a node and throws XPTY0004 on that string,
 : which crashed q:MssPersRoles live the first time it ever ran (#117) - it
 : was always broken, just never executed before newSearch.html's advanced
 : filters panel bypassed eXist's templating engine entirely.
 :)
module namespace tssortingkey = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-sortingkey";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

declare %test:assertEquals("helloworld") function tssortingkey:accepts-a-node() {
	q:sortingkey(<a>Hello World</a>)
};

declare %test:assertEquals("prs13425fantawaspermanentlydeleted") function tssortingkey:accepts-a-plain-string() {
	q:sortingkey("PRS13425Fanta was permanently deleted")
};

declare %test:assertEquals("pas") function tssortingkey:transliterates-known-special-characters() {
	q:sortingkey("Ṗāṣ")
};
