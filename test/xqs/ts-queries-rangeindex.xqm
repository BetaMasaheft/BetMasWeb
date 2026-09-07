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
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

declare %test:assertTrue function tsrangeidx:rangeindexlookup-script-returns-options() {
	exists(q:rangeindexlookup("script"))
};

declare %test:assertTrue function tsrangeidx:rangeindexlookup-options-are-option-elements() {
	every $o in q:rangeindexlookup("script") satisfies local-name($o) = ("option", "optgroup")
};

declare %test:assertTrue function tsrangeidx:rangeindexlookup-persrole-returns-options() {
	exists(q:rangeindexlookup("persrole"))
};

declare variable $tsrangeidx:mss-col := $config:data-root || "/manuscripts/_mssPersRolesTest";

declare variable $tsrangeidx:role := "TESTmssRoleXYZ";

declare variable $tsrangeidx:person1 := "PRSTESTmssRoleXYZOne";

declare variable $tsrangeidx:person2 := "PRSTESTmssRoleXYZTwo";

(:~
 : A role name unique to this fixture so q:MssPersRoles' own unindexed
 : `$q:col//t:persName[@role eq $role]` scan can only ever match these
 : two fabricated persons, regardless of what real roles/persons exist
 : in the corpus this test runs against.
 :)
declare variable $tsrangeidx:mss-tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="MSTESTmssRoleXYZ">
	<teiHeader><titleStmt><title type="full">MssPersRoles test fixture</title></titleStmt></teiHeader>
	<text>
		<body>
			<msDesc>
				<history>
					<persName
						ref="https://betamasaheft.eu/{ $tsrangeidx:person1 }"
						role="{ $tsrangeidx:role }"
					>Person One</persName>
					<persName
						ref="https://betamasaheft.eu/{ $tsrangeidx:person1 }"
						role="{ $tsrangeidx:role }"
					>Person One again</persName>
					<persName
						ref="https://betamasaheft.eu/{ $tsrangeidx:person2 }"
						role="{ $tsrangeidx:role }"
					>Person Two</persName>
				</history>
			</msDesc>
		</body>
	</text>
</TEI>;

declare %private function tsrangeidx:ensure-mss-src() {
	if (not(xmldb:collection-available($config:data-root || "/manuscripts"))) then
		xmldb:create-collection($config:data-root, "manuscripts")
	else (
	),
	if (xmldb:collection-available($tsrangeidx:mss-col)) then (
	) else
		xmldb:create-collection($config:data-root || "/manuscripts", "_mssPersRolesTest"),
	xmldb:store($tsrangeidx:mss-col, "MSTESTmssRoleXYZ.xml", $tsrangeidx:mss-tei)
};

declare %private function tsrangeidx:cleanup-mss-src() {
	if (xmldb:collection-available($tsrangeidx:mss-col)) then
		try { xmldb:remove($tsrangeidx:mss-col) } catch * { () }
	else (
	)
};

declare %test:setUp function tsrangeidx:setUp() {
	tsrangeidx:cleanup-mss-src(), tsrangeidx:ensure-mss-src()
};

declare %test:tearDown function tsrangeidx:tearDown() {
	tsrangeidx:cleanup-mss-src()
};

declare %test:assertTrue function tsrangeidx:MssPersRoles-lists-test-role() {
	let $out := q:MssPersRoles(<a />, map {})
	return exists($out//*:label[starts-with(., $tsrangeidx:role)])
};

(:~
 : The badge shows distinct people (2), not total attestations (3) -
 : person1 is attested twice.
 :)
declare %test:assertEquals(2) function tsrangeidx:MssPersRoles-badge-counts-distinct-people() {
	let $out := q:MssPersRoles(<a />, map {})
	let $label := $out//*:label[starts-with(., $tsrangeidx:role)]
	return xs:integer($label/*:span/text())
};
