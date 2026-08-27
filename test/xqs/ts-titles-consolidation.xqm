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

(:~
 : Locks in a real behaviour change from this consolidation: dts.xqm's
 : person titles now go through titlesData.xqm's persNameSelector,
 : which restricts its "two-part name" branch to a persName with
 : @xml:id="n1" - the deleted titles.xqm had no such restriction, so
 : records without that marker (most of the corpus - measured 412 of
 : 472 candidates) now resolve via a different branch than they did
 : through DTS before. Not a regression: expand:file has used
 : titlesData.xqm's persNameSelector for every already-expanded
 : person's own title all along (confirmed against a real record,
 : /db/apps/expanded/persons/PRS11021Entones.xml), so this makes
 : DTS's person titles consistent with the rest of the app - DTS was
 : the one place still out of sync, via the now-deleted fork.
 :)
declare
	%test:assertEquals("ʾƎnṭonǝs (Antoine)")
function tstitlesconsol:printTitleMainID-person-selection-matches-expand-pipeline() {
	string(titles:printTitleMainID("PRS11021Entones"))
};
