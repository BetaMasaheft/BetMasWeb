xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for the titlesData.xqm/titles.xqm consolidation
 : (issues/BetaMasaheft/BetMasWeb#99): dts.xqm now imports
 : titlesData.xqm directly rather than a separate, drifted fork, which
 : means unresolved ids resolve as plain strings instead of leaking
 : raw HTML markup into JSON responses.
 :)
module namespace tstitlesconsol = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-titles-consolidation";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../../modules/titlesData.xqm";

(:~
 : An unresolvable id must resolve to a plain string, never an
 : element - embedding an element's serialized markup into a JSON
 : field (as dts.xqm does for several fields) is exactly how #99
 : happened.
 :)
declare %test:assertFalse function tstitlesconsol:printTitleMainID-unresolved-id-is-not-an-element() {
	titles:printTitleMainID("LITTESTconsolidationDoesNotExist77") instance of element()
};

declare
	%test:assertEquals("No item: LITTESTconsolidationDoesNotExist77")
function tstitlesconsol:printTitleMainID-unresolved-id-is-plain-string() {
	string(titles:printTitleMainID("LITTESTconsolidationDoesNotExist77"))
};

declare %test:assertFalse function tstitlesconsol:printTitleID-unresolved-id-is-not-an-element() {
	titles:printTitleID("LITTESTconsolidationDoesNotExist77") instance of element()
};
