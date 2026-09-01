xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for newSearch.html's "#filters" advanced-search panel
 : (modules/queries.xqm): q:filtersPanelFieldset (panel-level reveal) and
 : the nine q:includeXXX section guards (q:include-facet-form) that
 : replaced filters.html.txt's dead, unexecuted data-template calls (#117).
 : Each guard must render nothing costly (an empty, id-carrying
 : placeholder) when its section has no active state, and its full
 : corpus-driven content when it does - the whole point of #116/#117 is
 : that newSearch.html should stay as fast as before for the common
 : (no-filters) case while still restoring active state on reload.
 :)
module namespace tsfilterspanel = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-filterspanel";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";

(:~
 : Minimal templates:apply-shaped $model, needed only by the "active"
 : cases below - q:include-facet-form's active branch calls lib:include,
 : which needs a real templates model to process the fetched form
 : fragment's own data-template call. See ts-app-msfilters.xqm's own
 : tsmssfilters:model-for for the same requirement/shape.
 :)
declare %private function tsfilterspanel:model() as map(*) {
	map {
		$templates:CONFIGURATION:
			map {
				$templates:CONFIG_FN_RESOLVER:
					function ($name as xs:string, $arity as xs:integer) as function(*)? {
						try { function-lookup(xs:QName($name), $arity) } catch * { () }
					},
				$templates:CONFIG_PARAM_RESOLVER: function ($var as xs:string) as item()* { () },
				$templates:CONFIG_USE_CLASS_SYNTAX: false(),
				$templates:CONFIG_STOP_ON_ERROR: false(),
				$templates:CONFIG_APP_ROOT: $config:app-root
			}
	}
};

declare %test:assertTrue function tsfilterspanel:includeGeneralRangeIndexesFilters-inactive-is-empty-placeholder() {
	let $out := q:includeGeneralRangeIndexesFilters(<div />, map {}, (), (), ())
	return $out/@id = "generalRangeIndexes" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeGeneralRangeIndexesFilters-active-renders-content() {
	let $out := q:includeGeneralRangeIndexesFilters(<div />, tsfilterspanel:model(), "am", (), ())
	return $out/@id = "generalRangeIndexes" and exists($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeMssRangeIndexesFilters-inactive-is-empty-placeholder() {
	let $out := q:includeMssRangeIndexesFilters(<div />, map {}, (), (), (), (), (), (), (), (), (), (), (), (), (), ())
	return $out/@id = "mssRangeIndexes" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeMssRangeIndexesFilters-active-renders-content() {
	let $out := q:includeMssRangeIndexesFilters(
		<div />,
		tsfilterspanel:model(),
		"geez",
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		()
	)
	return $out/@id = "mssRangeIndexes" and exists($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeMssPersRoles-inactive-is-empty-placeholder() {
	let $out := q:includeMssPersRoles(<div />, map {}, (), (), (), (), (), (), (), (), (), (), (), ())
	return $out/@id = "mssPersRoles" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeMssPersRoles-active-renders-content() {
	let $out := q:includeMssPersRoles(
		<div />,
		tsfilterspanel:model(),
		(),
		(),
		"scribe",
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		()
	)
	return $out/@id = "mssPersRoles" and exists($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeRoles-inactive-is-empty-placeholder() {
	let $out := q:includeRoles(<div />, map {}, ())
	return $out/@id = "rolesLookup" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeRoles-active-renders-content() {
	let $out := q:includeRoles(<div />, tsfilterspanel:model(), "scribe")
	return $out/@id = "rolesLookup" and exists($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeWorksRangeIndexesFilters-inactive-is-empty-placeholder() {
	let $out := q:includeWorksRangeIndexesFilters(<div />, map {}, (), (), ())
	return $out/@id = "worksRangeIndexes" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeWorkAuthors-inactive-is-empty-placeholder() {
	let $out := q:includeWorkAuthors(<div />, map {}, ())
	return $out/@id = "workAuthors" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeWorkAuthors-active-renders-content() {
	let $out := q:includeWorkAuthors(<div />, tsfilterspanel:model(), "PRS12345")
	return $out/@id = "workAuthors" and exists($out/*)
};

declare %test:assertTrue function tsfilterspanel:includePersonsRangeIndexesFilters-inactive-is-empty-placeholder() {
	let $out := q:includePersonsRangeIndexesFilters(<div />, map {}, (), (), ())
	return $out/@id = "personsRangeIndexes" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includePlacesRangeIndexesFilters-inactive-is-empty-placeholder() {
	let $out := q:includePlacesRangeIndexesFilters(<div />, map {}, (), (), (), ())
	return $out/@id = "placesRangeIndexes" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeTabot-inactive-is-empty-placeholder() {
	let $out := q:includeTabot(<div />, map {}, ())
	return $out/@id = "tabotLookup" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeTabot-active-renders-content() {
	let $out := q:includeTabot(<div />, tsfilterspanel:model(), "PRS12345")
	return $out/@id = "tabotLookup" and exists($out/*)
};

declare %test:assertTrue function tsfilterspanel:blank-strings-do-not-count-as-active() {
	let $out := q:includeGeneralRangeIndexesFilters(<div />, map {}, "", "  ", ())
	return empty($out/*)
};
