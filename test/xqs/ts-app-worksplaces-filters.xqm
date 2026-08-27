xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for as.html's Works/Places Filters state-restoration slice:
 : app:authorsCheckbox/app:includeAuthorsForm/app:worksFiltersSection
 : and app:tabotsCheckbox/app:includeTabotsForm/app:placesFiltersSection -
 : same recipe as the Manuscripts/Persons Filters slices
 : (ts-app-msfilters.xqm/ts-app-persrole.xqm), split into its own
 : module since these two facets are the first in their own sections.
 :)
module namespace tswpfilters = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-app-worksplaces-filters";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app" at "../../modules/app.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";

(:~
 : Minimal templates:apply-shaped $model - see ts-app-persrole.xqm's
 : own tspersrole:model-for for why this is needed.
 :
 : @param $params a map of request-parameter-name to value
 :)
declare %private function tswpfilters:model-for($params as map(*)) as map(*) {
	map {
		$templates:CONFIGURATION:
			map {
				$templates:CONFIG_FN_RESOLVER:
					function ($name as xs:string, $arity as xs:integer) as function(*)? {
						try { function-lookup(xs:QName($name), $arity) } catch * { () }
					},
				$templates:CONFIG_PARAM_RESOLVER: function ($var as xs:string) as item()* { $params($var) },
				$templates:CONFIG_USE_CLASS_SYNTAX: false(),
				$templates:CONFIG_STOP_ON_ERROR: false(),
				$templates:CONFIG_APP_ROOT: $config:app-root
			}
	}
};

declare %test:assertTrue function tswpfilters:authorsCheckbox-checked-with-value() {
	let $node := <input data-template="app:authorsCheckbox" type="checkbox" value="authors" />
	return exists(app:authorsCheckbox($node, map {}, "REL1")/@checked)
};

declare %test:assertFalse function tswpfilters:authorsCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:authorsCheckbox" type="checkbox" value="authors" />
	return exists(app:authorsCheckbox($node, map {}, ())/@checked)
};

declare %test:assertFalse function tswpfilters:worksFiltersSection-visible-when-author-active() {
	let $node := <div id="worksFilters" style="display: none"><input type="checkbox" value="authors" /></div>
	let $out := app:worksFiltersSection($node, tswpfilters:model-for(map {"author": "REL1"}), "REL1")
	return exists($out/@style)
};

declare %test:assertTrue function tswpfilters:worksFiltersSection-hidden-without-author() {
	let $node := <div id="worksFilters" style="display: none"><input type="checkbox" value="authors" /></div>
	let $out := app:worksFiltersSection($node, tswpfilters:model-for(map {}), ())
	return exists($out/@style)
};

declare %test:assertTrue function tswpfilters:includeAuthorsForm-hidden-without-param() {
	let $node := <div data-template="app:includeAuthorsForm" />
	let $out := app:includeAuthorsForm($node, tswpfilters:model-for(map {}), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tswpfilters:includeAuthorsForm-visible-with-value() {
	let $node := <div data-template="app:includeAuthorsForm" />
	let $out := app:includeAuthorsForm($node, tswpfilters:model-for(map {"author": "REL1"}), "REL1")
	return exists($out/@style)
};

declare %test:assertTrue function tswpfilters:tabotsCheckbox-checked-with-value() {
	let $node := <input data-template="app:tabotsCheckbox" type="checkbox" value="tabots" />
	return exists(app:tabotsCheckbox($node, map {}, "PLA1")/@checked)
};

declare %test:assertFalse function tswpfilters:tabotsCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:tabotsCheckbox" type="checkbox" value="tabots" />
	return exists(app:tabotsCheckbox($node, map {}, ())/@checked)
};

declare %test:assertFalse function tswpfilters:placesFiltersSection-visible-when-tabot-active() {
	let $node := <div id="placesFilters" style="display: none"><input type="checkbox" value="tabots" /></div>
	let $out := app:placesFiltersSection($node, tswpfilters:model-for(map {"tabot": "PLA1"}), "PLA1")
	return exists($out/@style)
};

declare %test:assertTrue function tswpfilters:placesFiltersSection-hidden-without-tabot() {
	let $node := <div id="placesFilters" style="display: none"><input type="checkbox" value="tabots" /></div>
	let $out := app:placesFiltersSection($node, tswpfilters:model-for(map {}), ())
	return exists($out/@style)
};

declare %test:assertTrue function tswpfilters:includeTabotsForm-hidden-without-param() {
	let $node := <div data-template="app:includeTabotsForm" />
	let $out := app:includeTabotsForm($node, tswpfilters:model-for(map {}), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tswpfilters:includeTabotsForm-visible-with-value() {
	let $node := <div data-template="app:includeTabotsForm" />
	let $out := app:includeTabotsForm($node, tswpfilters:model-for(map {"tabot": "PLA1"}), "PLA1")
	return exists($out/@style)
};
