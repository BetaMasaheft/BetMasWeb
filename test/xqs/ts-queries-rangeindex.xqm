xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for q:rangeindexlookup/q:MssPersRoles (modules/queries.xqm).
 : range:index-keys-for-field scopes its lookup to the *evaluating*
 : query's own default collection, not the collection actually bound to
 : it via `$q:col/...` - a direct call from any deployed BetMasWeb
 : resource (this test runner included) used to silently return zero
 : results, even though the identical call worked as an ad-hoc REST
 : eval. That made it invisible to `xst execute`/ad-hoc-style checks
 : while still broken on every real request.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/124
 :)
module namespace tsrangeidx = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-rangeindex";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

declare %test:assertTrue function tsrangeidx:rangeindexlookup-script-returns-options() {
	exists(q:rangeindexlookup("script"))
};

declare %test:assertTrue function tsrangeidx:rangeindexlookup-options-are-option-elements() {
	every $o in q:rangeindexlookup("script") satisfies local-name($o) = ("option", "optgroup")
};

declare %test:assertTrue function tsrangeidx:rangeindexlookup-persrole-returns-options() {
	exists(q:rangeindexlookup("persrole"))
};
