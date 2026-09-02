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
			map:merge(
				(
					config:template-apply-config(),
					map {
						$templates:CONFIG_FN_RESOLVER:
							function ($name as xs:string, $arity as xs:integer) as function(*)? {
								try { function-lookup(xs:QName($name), $arity) } catch * { () }
							},
						$templates:CONFIG_PARAM_RESOLVER: function ($var as xs:string) as item()* { () },
						$templates:CONFIG_APP_ROOT: $config:app-root
					}
				)
			)
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

declare %private function tsfilterspanel:model-with-mss-values($values as map(*)) as map(*) {
	map:merge((tsfilterspanel:model(), map {"mssFieldValues": $values}))
};

declare %test:assertTrue function tsfilterspanel:includeMssRangeIndexesFilters-inactive-is-empty-placeholder() {
	let $out := q:includeMssRangeIndexesFilters(<div />, tsfilterspanel:model-with-mss-values(map {}))
	return $out/@id = "mssRangeIndexes" and empty($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeMssRangeIndexesFilters-active-renders-content() {
	let $out := q:includeMssRangeIndexesFilters(<div />, tsfilterspanel:model-with-mss-values(map {"script": "geez"}))
	return $out/@id = "mssRangeIndexes" and exists($out/*)
};

declare %test:assertTrue function tsfilterspanel:includeMssPersRoles-inactive-is-empty-placeholder() {
	let $out := q:includeMssPersRoles(<div />, tsfilterspanel:model-with-mss-values(map {}))
	return $out/@id = "mssPersRoles" and empty($out/*)
};

(:
 : author-collision fix: q:includeMssPersRoles' "author" branch also reads
 : work-types via request:get-parameter directly (not $model), so it
 : can't be exercised from a direct XQSuite call - see
 : newSearch-collectionSections.cy.js for the live coverage.
 :)

declare %test:assertTrue function tsfilterspanel:includeMssPersRoles-active-renders-content() {
	let $out := q:includeMssPersRoles(<div />, tsfilterspanel:model-with-mss-values(map {"scribe": "yes"}))
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

declare %private function tsfilterspanel:fieldset() as element(fieldset) {
	<fieldset
		data-template="q:manuscriptsFiltersSection"
		disabled="disabled"
		id="manuscriptsFilters"
		style="display: none" />
};

declare %test:assertTrue function tsfilterspanel:sectionReveal-strips-style-and-disabled-when-active() {
	let $out := q:sectionReveal(tsfilterspanel:fieldset(), map {}, true())
	return empty($out/@style) and empty($out/@disabled)
};

declare %test:assertTrue function tsfilterspanel:sectionReveal-keeps-style-and-disabled-when-inactive() {
	let $out := q:sectionReveal(tsfilterspanel:fieldset(), map {}, false())
	return $out/@style = "display: none" and $out/@disabled = "disabled"
};

declare %test:assertEquals("manuscriptsFilters") function tsfilterspanel:sectionReveal-preserves-other-attributes() {
	let $out := q:sectionReveal(tsfilterspanel:fieldset(), map {}, true())
	return string($out/@id)
};

declare %test:assertTrue function tsfilterspanel:sectionReveal-strips-data-template-attrs-with-real-config() {
	let $out := q:sectionReveal(tsfilterspanel:fieldset(), tsfilterspanel:model(), true())
	return empty($out/@data-template)
};

declare %test:assertTrue function tsfilterspanel:sectionReveal-without-config-falls-back-to-keeping-data-template() {
	let $out := q:sectionReveal(tsfilterspanel:fieldset(), map {}, true())
	return $out/@data-template = "q:manuscriptsFiltersSection"
};

declare %test:assertTrue function tsfilterspanel:manuscripts-filter-param-names-includes-all-form-m-indexes() {
	let $expected := doc("/db/apps/BetMasWeb/paramargs.xml")/indexes/rangeindex[@form = "m"]/@name/string()
	let $actual := q:manuscripts-filter-param-names()
	return every $name in $expected satisfies $name = $actual
};

declare %test:assertTrue function tsfilterspanel:manuscripts-section-active-on-script-param() {
	q:manuscripts-section-active-impl(map {"script": "geez"}, ())
};

declare %test:assertTrue function tsfilterspanel:manuscripts-section-inactive-on-bare-author() {
	not(q:manuscripts-section-active-impl(map {"author": "PRS12345"}, ()))
};

declare %test:assertTrue function tsfilterspanel:manuscripts-section-active-on-author-with-mss-work-type() {
	q:manuscripts-section-active-impl(map {"author": "PRS12345"}, "mss")
};

declare %test:assertTrue function tsfilterspanel:mss-author-role-active-requires-mss-work-type() {
	q:mss-author-role-active-impl("PRS12345", "mss") and not(q:mss-author-role-active-impl("PRS12345", ()))
};
(:
 : q:fieldsSection/q:generalFiltersSection read request:get-parameter
 : internally (via q:sectionReveal/q:any-active) - not directly callable
 : from XQSuite (no live request bound). Covered live instead: see
 : newSearch-fieldsReveal.cy.js and newSearch-collectionSections.cy.js.
 :)
