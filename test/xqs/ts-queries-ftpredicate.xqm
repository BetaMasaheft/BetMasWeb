xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for q:ftPredicate and q:needsDedup (modules/queries.xqm).
 :
 : Filter-only text searches (work-types=mss, no free text) need an ft:query
 : so ft:facets has hits to count, otherwise the facet column is empty
 : (BetMasWeb#172). That match-all predicate cannot return a TEI twice, so it
 : must not switch on q:text's group-by dedup, which cost ~900ms on 20k
 : results (BetMasWeb#3).
 :)
module namespace tsftpred = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-ftpredicate";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

declare %test:assertEquals("[ft:query(., (), $q:allopts)]") function tsftpred:filter-only-is-match-all() {
	q:ftPredicate("", (), "any")
};

declare %test:assertEquals("[ft:query(., $qs, $q:allopts)]") function tsftpred:free-text-uses-parsed-query() {
	q:ftPredicate("homily", "homily", "any")
};

declare
	%test:assertEquals("[ft:query(., '""homily of John""', <options><default-operator>and</default-operator></options>)]")
function tsftpred:phrase-quotes-raw-query() {
	q:ftPredicate('"homily of John"', "ignored", "phrase")
};

declare %test:assertFalse function tsftpred:filter-only-skips-dedup() {
	q:needsDedup((), '[@type = "mss"]')
};

declare %test:assertTrue function tsftpred:free-text-dedups() {
	q:needsDedup("homily", '[@type = "mss"]')
};

declare %test:assertTrue function tsftpred:filter-with-own-ft-query-dedups() {
	q:needsDedup((), "[descendant::t:origPlace[ft:query(., 'Gondar')]]")
};
