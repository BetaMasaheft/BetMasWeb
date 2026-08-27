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
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";

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
	let $select := app:persRole(<a />, tspersrole:model-for((), ()), $tspersrole:context)
	return exists($select//*:option[starts-with(@value, $tspersrole:role)][contains(., "4")])
};

declare %test:assertFalse function tspersrole:persRole-is-not-multiple() {
	let $select := app:persRole(<a />, tspersrole:model-for((), ()), $tspersrole:context)
	return exists($select/@multiple)
};

(:~
 : Selecting a role echoes back as the selected option -
 : templates:form-control's own job now (see app:persRole's doc), the
 : zero-JS equivalent of restoring $("#persRole").val() on reload.
 :)
declare %test:assertTrue function tspersrole:persRole-echoes-selected-value() {
	let $select := app:persRole(<a />, tspersrole:model-for($tspersrole:role, ()), $tspersrole:context)
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

(:~
 : Echoes the "role" checkbox's checked state - the zero-JS piece of
 : as.html's state-restoration fix.
 :)
declare %test:assertTrue function tspersrole:roleCheckbox-checked-when-role-selected() {
	let $node := <input data-template="app:roleCheckbox" type="checkbox" value="role" />
	let $out := app:roleCheckbox($node, map {}, $tspersrole:role)
	return exists($out/@checked)
};

declare %test:assertFalse function tspersrole:roleCheckbox-unchecked-without-role() {
	let $node := <input data-template="app:roleCheckbox" type="checkbox" value="role" />
	let $out := app:roleCheckbox($node, map {}, ())
	return exists($out/@checked)
};

declare %test:assertFalse function tspersrole:roleCheckbox-strips-data-template() {
	let $node := <input data-template="app:roleCheckbox" type="checkbox" value="role" />
	let $out := app:roleCheckbox($node, map {}, ())
	return exists($out/@data-template)
};

(:~
 : Minimal templates:apply-shaped $model, standing in for what
 : templates:apply normally builds - needed here since
 : app:includeRoleForm calls templates:process directly (it *is* the
 : server-side equivalent of an AJAX include, so it has to). The
 : param-resolver is fixed to test values instead of the real request,
 : the same role $context override the other tests use.
 :)
declare %private function tspersrole:model-for($role as xs:string?, $person as xs:string?) as map(*) {
	map {
		$templates:CONFIGURATION:
			map {
				$templates:CONFIG_FN_RESOLVER:
					function ($name as xs:string, $arity as xs:integer) as function(*)? {
						try { function-lookup(xs:QName($name), $arity) } catch * { () }
					},
				$templates:CONFIG_PARAM_RESOLVER:
					function ($var as xs:string) as item()* {
						switch ($var)
							case "role" return
								$role
							case "person" return
								$person
							case "context" return
								$tspersrole:context
							default return
								()
					},
				$templates:CONFIG_USE_CLASS_SYNTAX: false(),
				$templates:CONFIG_STOP_ON_ERROR: false(),
				$templates:CONFIG_APP_ROOT: $config:app-root
			}
	}
};

(:~
 : Reveals the persFilters wrapper server-side when role is active.
 :)
declare %test:assertFalse function tspersrole:persFiltersSection-visible-when-role-selected() {
	let $node := <div id="persFilters" style="display: none"><input type="checkbox" value="role" /></div>
	let $out := app:persFiltersSection($node, tspersrole:model-for($tspersrole:role, ()), $tspersrole:role)
	return exists($out/@style)
};

declare %test:assertTrue function tspersrole:persFiltersSection-hidden-without-role() {
	let $node := <div id="persFilters" style="display: none"><input type="checkbox" value="role" /></div>
	let $out := app:persFiltersSection($node, tspersrole:model-for((), ()), ())
	return exists($out/@style)
};

(:~
 : Server-side include of formrole.html - hidden without a role,
 : rendering the same content a live AJAX fetch would have, without
 : needing one.
 :)
declare %test:assertTrue function tspersrole:includeRoleForm-hidden-without-role() {
	let $node := <div data-template="app:includeRoleForm" />
	let $out := app:includeRoleForm($node, tspersrole:model-for((), ()), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tspersrole:includeRoleForm-visible-with-role() {
	let $node := <div data-template="app:includeRoleForm" />
	let $out := app:includeRoleForm($node, tspersrole:model-for($tspersrole:role, ()), $tspersrole:role)
	return exists($out/@style)
};

declare %test:assertTrue function tspersrole:includeRoleForm-renders-results-with-role() {
	let $node := <div data-template="app:includeRoleForm" />
	let $out := app:includeRoleForm($node, tspersrole:model-for($tspersrole:role, ()), $tspersrole:role)
	return exists($out//*[@data-person])
};
