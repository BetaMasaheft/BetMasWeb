xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for the zero-JS persRole lookup feature: app:persRole (the
 : corpus-driven role select), app:persRoleResults (people with a
 : given role, rendered from a request parameter), and
 : app:persRolePersonDetail (one person's specific records for that
 : role) - replacing personswithrole.js's AJAX/JSON round-trips with
 : server-rendered content driven by real query-string parameters.
 :)
module namespace tspersrole = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-app-persrole";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app" at "../../modules/app.xqm";

declare variable $tspersrole:col := "/db/apps/expanded/manuscripts/_persRoleTest";

declare variable $tspersrole:context := "collection('" || $tspersrole:col || "')";

declare variable $tspersrole:role := "TESTrole77";

declare variable $tspersrole:person1 := "PRSTESTrole77One";

declare variable $tspersrole:person2 := "PRSTESTrole77Two";

declare variable $tspersrole:placeholder-person := "PRS0000";

(:~
 : @ref values are BMurl-prefixed full URLs, matching what
 : expand:reflike actually produces in real expanded data - a bare-id
 : fixture missed a real bug (double-prefixed hrefs, empty titles)
 : that only showed up smoke-testing against the live corpus.
 :)
declare variable $tspersrole:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="MSTESTrole77">
	<teiHeader><titleStmt><title type="full">persRole test fixture</title></titleStmt></teiHeader>
	<text>
		<body>
			<msDesc>
				<history>
					<persName
						ref="https://betamasaheft.eu/{ $tspersrole:person1 }"
						role="{ $tspersrole:role }"
					>Person One</persName>
					<persName
						ref="https://betamasaheft.eu/{ $tspersrole:person1 }"
						role="{ $tspersrole:role }"
					>Person One again</persName>
					<persName
						ref="https://betamasaheft.eu/{ $tspersrole:person2 }"
						role="{ $tspersrole:role }"
					>Person Two</persName>
					<persName
						ref="https://betamasaheft.eu/{ $tspersrole:placeholder-person }"
						role="{ $tspersrole:role }"
					>Unidentified</persName>
				</history>
			</msDesc>
		</body>
	</text>
</TEI>;

declare %private function tspersrole:ensure-src() {
	if (not(xmldb:collection-available("/db/apps/expanded/manuscripts"))) then
		xmldb:create-collection("/db/apps/expanded", "manuscripts")
	else (
	),
	if (xmldb:collection-available($tspersrole:col)) then (
	) else
		xmldb:create-collection("/db/apps/expanded/manuscripts", "_persRoleTest"),
	xmldb:store($tspersrole:col, "MSTESTrole77.xml", $tspersrole:tei)
};

declare %private function tspersrole:cleanup() {
	if (xmldb:collection-available($tspersrole:col)) then
		try { xmldb:remove($tspersrole:col) } catch * { () }
	else (
	)
};

declare %test:setUp function tspersrole:setUp() {
	tspersrole:cleanup(), tspersrole:ensure-src()
};

declare %test:tearDown function tspersrole:tearDown() {
	tspersrole:cleanup()
};

(:~
 : The test role appears as a real option, single-select (no
 : "multiple" attribute - app:selectors' generic path would have
 : broken personswithrole.js-equivalent single-value handling).
 :)
declare %test:assertTrue function tspersrole:persRole-lists-role-with-count() {
	(: 4 attestations total: person1 twice, person2 once, the
	   placeholder once - the option's count is total attestations,
	   not distinct (non-placeholder) people. :)
	let $select := app:persRole(<a />, map {}, $tspersrole:context, ())
	return exists($select//*:option[starts-with(@value, $tspersrole:role)][contains(., "4")])
};

declare %test:assertFalse function tspersrole:persRole-is-not-multiple() {
	let $select := app:persRole(<a />, map {}, $tspersrole:context, ())
	return exists($select/@multiple)
};

(:~
 : Selecting a role echoes back as the selected option - the
 : zero-JS equivalent of restoring $("#persRole").val() on reload.
 :)
declare %test:assertTrue function tspersrole:persRole-echoes-selected-value() {
	let $select := app:persRole(<a />, map {}, $tspersrole:context, $tspersrole:role)
	return exists($select//*:option[starts-with(@value, $tspersrole:role)][@selected])
};

(:~
 : No role parameter - no results rendered at all (must stay
 : genuinely lazy, not eagerly compute every role's people list).
 :)
declare %test:assertEmpty function tspersrole:persRoleResults-empty-without-role() {
	app:persRoleResults(<a />, map {}, $tspersrole:context, ())
};

(:~
 : With a role parameter, both distinct people show up, each with
 : their attestation count and a real link carrying role+person
 : forward (not a JS click handler).
 :)
declare %test:assertEquals(2) function tspersrole:persRoleResults-lists-distinct-people() {
	let $out := app:persRoleResults(<a />, map {}, $tspersrole:context, $tspersrole:role)
	return count($out//*[@data-person])
};

(:~
 : PRS0000 is a known placeholder for an unidentified person
 : (confirmed against the real corpus: its own record's title is
 : literally "Placeholder record") - the original BetMasApi
 : implementation excluded it explicitly; this must too.
 :)
declare %test:assertEmpty function tspersrole:persRoleResults-excludes-placeholder-person() {
	let $out := app:persRoleResults(<a />, map {}, $tspersrole:context, $tspersrole:role)
	return $out//*[@data-person = $tspersrole:placeholder-person]
};

declare %test:assertTrue function tspersrole:persRoleResults-person-one-count-is-two() {
	let $out := app:persRoleResults(<a />, map {}, $tspersrole:context, $tspersrole:role)
	return $out//*[@data-person = $tspersrole:person1]//text()[contains(., "2")]
};

declare %test:assertTrue function tspersrole:persRoleResults-links-carry-role-and-person() {
	let $out := app:persRoleResults(<a />, map {}, $tspersrole:context, $tspersrole:role)
	return exists(
		$out//*:a[contains(@href, "role=" || $tspersrole:role)][contains(@href, "person=" || $tspersrole:person1)]
	)
};

(:~
 : Regression guard: the person's own link must resolve to the bare
 : id, not a double-prefixed "/https://..." href built from an
 : unstripped BMurl-prefixed @ref.
 :)
declare %test:assertFalse function tspersrole:persRoleResults-header-link-is-not-double-prefixed() {
	let $out := app:persRoleResults(<a />, map {}, $tspersrole:context, $tspersrole:role)
	return exists($out//*:header/*:a[contains(@href, "/https://")])
};

(:~
 : No person parameter - no per-record detail rendered.
 :)
declare %test:assertEmpty function tspersrole:persRolePersonDetail-empty-without-person() {
	app:persRolePersonDetail(<a />, map {}, $tspersrole:context, $tspersrole:role, ())
};

(:~
 : With role+person, the specific record(s) show up - this fixture
 : has one manuscript with person1 attested twice.
 :)
declare %test:assertEquals(1) function tspersrole:persRolePersonDetail-lists-source-records() {
	let $out := app:persRolePersonDetail(<a />, map {}, $tspersrole:context, $tspersrole:role, $tspersrole:person1)
	return count($out//*[@data-source])
};
