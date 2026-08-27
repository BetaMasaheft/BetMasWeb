xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for as.html's Manuscripts Filters state-restoration slice:
 : app:foliaInput/app:writtenLinesInput/
 : app:quiresInput/app:quiresCompInput echoing their slider's submitted
 : range, app:foliaCheckbox/app:writtenLinesCheckbox/app:quiresCheckbox/
 : app:quiresCompCheckbox echoing checkbox state, and
 : app:manuscriptsFiltersSection revealing the wrapping section - all
 : driven by the real request parameters (folia/wL/qn/qcn), not JS
 : state that used to be lost on reload.
 :)
module namespace tsmssfilters = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-app-msfilters";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app" at "../../modules/app.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";

(:~
 : Minimal templates:apply-shaped $model - see ts-app-persrole.xqm's
 : own tspersrole:model-for for why this is needed (app:manuscriptsFiltersSection
 : calls templates:process directly on its children).
 :)
declare %private function tsmssfilters:model-for(
	$folia as xs:string?,
	$wL as xs:string?,
	$qn as xs:string?,
	$qcn as xs:string?
) as map(*) {
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
							case "folia" return
								$folia
							case "wL" return
								$wL
							case "qn" return
								$qn
							case "qcn" return
								$qcn
							default return
								()
					},
				$templates:CONFIG_USE_CLASS_SYNTAX: false(),
				$templates:CONFIG_STOP_ON_ERROR: false(),
				$templates:CONFIG_APP_ROOT: $config:app-root
			}
	}
};

declare %test:assertTrue function tsmssfilters:foliaInput-echoes-submitted-range() {
	let $out := app:foliaInput(<a />, map {}, "5,42")
	return $out/@data-slider-value = "[5,42]"
};

declare %test:assertTrue function tsmssfilters:foliaInput-defaults-to-full-range-without-param() {
	let $max := q:max-folia()
	let $out := app:foliaInput(<a />, map {}, ())
	return $out/@data-slider-value = ("[1," || $max || "]")
};

declare %test:assertTrue function tsmssfilters:writtenLinesInput-echoes-submitted-range() {
	let $out := app:writtenLinesInput(<a />, map {}, "3,17")
	return $out/@data-slider-value = "[3,17]"
};

declare %test:assertTrue function tsmssfilters:writtenLinesInput-defaults-to-full-range-without-param() {
	let $max := q:max-written-lines()
	let $out := app:writtenLinesInput(<a />, map {}, ())
	return $out/@data-slider-value = ("[1," || $max || "]")
};

declare %test:assertTrue function tsmssfilters:quiresInput-echoes-submitted-range() {
	let $out := app:quiresInput(<a />, map {}, "5,42")
	return $out/@data-slider-value = "[5,42]"
};

declare %test:assertTrue function tsmssfilters:quiresInput-defaults-to-full-range-without-param() {
	let $out := app:quiresInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,100]"
};

declare %test:assertTrue function tsmssfilters:quiresCompInput-echoes-submitted-range() {
	let $out := app:quiresCompInput(<a />, map {}, "3,17")
	return $out/@data-slider-value = "[3,17]"
};

declare %test:assertTrue function tsmssfilters:quiresCompInput-defaults-to-full-range-without-param() {
	let $out := app:quiresCompInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,40]"
};

declare %test:assertTrue function tsmssfilters:foliaCheckbox-checked-with-nondefault-range() {
	let $node := <input data-template="app:foliaCheckbox" type="checkbox" value="folia" />
	let $out := app:foliaCheckbox($node, map {}, "5,42")
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:foliaCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:foliaCheckbox" type="checkbox" value="folia" />
	let $out := app:foliaCheckbox($node, map {}, ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:foliaCheckbox-unchecked-with-default-range() {
	let $max := q:max-folia()
	let $node := <input data-template="app:foliaCheckbox" type="checkbox" value="folia" />
	let $out := app:foliaCheckbox($node, map {}, "1," || $max)
	return exists($out/@checked)
};

declare %test:assertTrue function tsmssfilters:writtenLinesCheckbox-checked-with-nondefault-range() {
	let $node := <input data-template="app:writtenLinesCheckbox" type="checkbox" value="writtenLines" />
	let $out := app:writtenLinesCheckbox($node, map {}, "3,17")
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:writtenLinesCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:writtenLinesCheckbox" type="checkbox" value="writtenLines" />
	let $out := app:writtenLinesCheckbox($node, map {}, ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:writtenLinesCheckbox-unchecked-with-default-range() {
	let $max := q:max-written-lines()
	let $node := <input data-template="app:writtenLinesCheckbox" type="checkbox" value="writtenLines" />
	let $out := app:writtenLinesCheckbox($node, map {}, "1," || $max)
	return exists($out/@checked)
};

declare %test:assertTrue function tsmssfilters:quiresCheckbox-checked-with-nondefault-range() {
	let $node := <input data-template="app:quiresCheckbox" type="checkbox" value="quires" />
	let $out := app:quiresCheckbox($node, map {}, "5,42")
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:quiresCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:quiresCheckbox" type="checkbox" value="quires" />
	let $out := app:quiresCheckbox($node, map {}, ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:quiresCheckbox-unchecked-with-default-range() {
	let $node := <input data-template="app:quiresCheckbox" type="checkbox" value="quires" />
	let $out := app:quiresCheckbox($node, map {}, "1,100")
	return exists($out/@checked)
};

declare %test:assertTrue function tsmssfilters:quiresCompCheckbox-checked-with-nondefault-range() {
	let $node := <input data-template="app:quiresCompCheckbox" type="checkbox" value="quiresComp" />
	let $out := app:quiresCompCheckbox($node, map {}, "3,17")
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:quiresCompCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:quiresCompCheckbox" type="checkbox" value="quiresComp" />
	let $out := app:quiresCompCheckbox($node, map {}, ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:quiresCompCheckbox-unchecked-with-default-range() {
	let $node := <input data-template="app:quiresCompCheckbox" type="checkbox" value="quiresComp" />
	let $out := app:quiresCompCheckbox($node, map {}, "1,40")
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-folia-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="folia" /></div>
	let $out := app:manuscriptsFiltersSection($node, tsmssfilters:model-for("5,42", (), (), ()), "5,42", (), (), ())
	return exists($out/@style)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-wL-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="writtenLines" /></div>
	let $out := app:manuscriptsFiltersSection($node, tsmssfilters:model-for((), "3,17", (), ()), (), "3,17", (), ())
	return exists($out/@style)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-qn-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="quires" /></div>
	let $out := app:manuscriptsFiltersSection($node, tsmssfilters:model-for((), (), "5,42", ()), (), (), "5,42", ())
	return exists($out/@style)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-qcn-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="quiresComp" /></div>
	let $out := app:manuscriptsFiltersSection($node, tsmssfilters:model-for((), (), (), "3,17"), (), (), (), "3,17")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:manuscriptsFiltersSection-hidden-when-all-default() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="folia" /></div>
	let $out := app:manuscriptsFiltersSection($node, tsmssfilters:model-for((), (), (), ()), (), (), (), ())
	return exists($out/@style)
};

(:~
 : Server-side include of formfolia.html - hidden without an active
 : filter, rendering the same content a live AJAX fetch would have,
 : without needing one (the bootstrap-slider widget was verified live
 : to position handles with percentages, not cached pixels, so
 : hidden-then-shown is safe).
 :)
declare %test:assertTrue function tsmssfilters:includeFoliaForm-hidden-without-param() {
	let $node := <div data-template="app:includeFoliaForm" />
	let $out := app:includeFoliaForm($node, tsmssfilters:model-for((), (), (), ()), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeFoliaForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeFoliaForm" />
	let $out := app:includeFoliaForm($node, tsmssfilters:model-for("5,42", (), (), ()), "5,42")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeFoliaForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeFoliaForm" />
	let $out := app:includeFoliaForm($node, tsmssfilters:model-for("5,42", (), (), ()), "5,42")
	return exists($out//*:input[@id = "folia"][@data-slider-value = "[5,42]"])
};

declare %test:assertTrue function tsmssfilters:includeWLForm-hidden-without-param() {
	let $node := <div data-template="app:includeWLForm" />
	let $out := app:includeWLForm($node, tsmssfilters:model-for((), (), (), ()), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeWLForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeWLForm" />
	let $out := app:includeWLForm($node, tsmssfilters:model-for((), "3,17", (), ()), "3,17")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeWLForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeWLForm" />
	let $out := app:includeWLForm($node, tsmssfilters:model-for((), "3,17", (), ()), "3,17")
	return exists($out//*:input[@id = "writtenLines"][@data-slider-value = "[3,17]"])
};

declare %test:assertTrue function tsmssfilters:includeQuiresForm-hidden-without-param() {
	let $node := <div data-template="app:includeQuiresForm" />
	let $out := app:includeQuiresForm($node, tsmssfilters:model-for((), (), (), ()), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeQuiresForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeQuiresForm" />
	let $out := app:includeQuiresForm($node, tsmssfilters:model-for((), (), "5,42", ()), "5,42")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeQuiresForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeQuiresForm" />
	let $out := app:includeQuiresForm($node, tsmssfilters:model-for((), (), "5,42", ()), "5,42")
	return exists($out//*:input[@id = "quires"][@data-slider-value = "[5,42]"])
};

declare %test:assertTrue function tsmssfilters:includeQuiresCompForm-hidden-without-param() {
	let $node := <div data-template="app:includeQuiresCompForm" />
	let $out := app:includeQuiresCompForm($node, tsmssfilters:model-for((), (), (), ()), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeQuiresCompForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeQuiresCompForm" />
	let $out := app:includeQuiresCompForm($node, tsmssfilters:model-for((), (), (), "3,17"), "3,17")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeQuiresCompForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeQuiresCompForm" />
	let $out := app:includeQuiresCompForm($node, tsmssfilters:model-for((), (), (), "3,17"), "3,17")
	return exists($out//*:input[@id = "quiresComp"][@data-slider-value = "[3,17]"])
};
