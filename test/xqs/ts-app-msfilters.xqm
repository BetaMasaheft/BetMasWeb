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
 : own tspersrole:model-for for why this is needed
 : (app:manuscriptsFiltersSection and friends call templates:process
 : directly on their children). Map-keyed rather than positional -
 : this module tests a growing number of independent request
 : parameters, and a positional signature stopped being readable once
 : it passed a handful.
 :
 : @param $params a map of request-parameter-name to value, e.g.
 : map { "folia": "5,42" } - any name not present resolves to ()
 :)
declare %private function tsmssfilters:model-for($params as map(*)) as map(*) {
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
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {"folia": "5,42"}),
		"5,42",
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
	return exists($out/@style)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-wL-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="writtenLines" /></div>
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {"wL": "3,17"}),
		(),
		"3,17",
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
	return exists($out/@style)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-qn-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="quires" /></div>
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {"qn": "5,42"}),
		(),
		(),
		"5,42",
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
	return exists($out/@style)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-qcn-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="quiresComp" /></div>
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {"qcn": "3,17"}),
		(),
		(),
		(),
		"3,17",
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
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:manuscriptsFiltersSection-hidden-when-all-default() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="folia" /></div>
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {}),
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
	let $out := app:includeFoliaForm($node, tsmssfilters:model-for(map {}), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeFoliaForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeFoliaForm" />
	let $out := app:includeFoliaForm($node, tsmssfilters:model-for(map {"folia": "5,42"}), "5,42")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeFoliaForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeFoliaForm" />
	let $out := app:includeFoliaForm($node, tsmssfilters:model-for(map {"folia": "5,42"}), "5,42")
	return exists($out//*:input[@id = "folia"][@data-slider-value = "[5,42]"])
};

declare %test:assertTrue function tsmssfilters:includeWLForm-hidden-without-param() {
	let $node := <div data-template="app:includeWLForm" />
	let $out := app:includeWLForm($node, tsmssfilters:model-for(map {}), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeWLForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeWLForm" />
	let $out := app:includeWLForm($node, tsmssfilters:model-for(map {"wL": "3,17"}), "3,17")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeWLForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeWLForm" />
	let $out := app:includeWLForm($node, tsmssfilters:model-for(map {"wL": "3,17"}), "3,17")
	return exists($out//*:input[@id = "writtenLines"][@data-slider-value = "[3,17]"])
};

declare %test:assertTrue function tsmssfilters:includeQuiresForm-hidden-without-param() {
	let $node := <div data-template="app:includeQuiresForm" />
	let $out := app:includeQuiresForm($node, tsmssfilters:model-for(map {}), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeQuiresForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeQuiresForm" />
	let $out := app:includeQuiresForm($node, tsmssfilters:model-for(map {"qn": "5,42"}), "5,42")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeQuiresForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeQuiresForm" />
	let $out := app:includeQuiresForm($node, tsmssfilters:model-for(map {"qn": "5,42"}), "5,42")
	return exists($out//*:input[@id = "quires"][@data-slider-value = "[5,42]"])
};

declare %test:assertTrue function tsmssfilters:includeQuiresCompForm-hidden-without-param() {
	let $node := <div data-template="app:includeQuiresCompForm" />
	let $out := app:includeQuiresCompForm($node, tsmssfilters:model-for(map {}), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeQuiresCompForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeQuiresCompForm" />
	let $out := app:includeQuiresCompForm($node, tsmssfilters:model-for(map {"qcn": "3,17"}), "3,17")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeQuiresCompForm-echoes-range-when-active() {
	let $node := <div data-template="app:includeQuiresCompForm" />
	let $out := app:includeQuiresCompForm($node, tsmssfilters:model-for(map {"qcn": "3,17"}), "3,17")
	return exists($out//*:input[@id = "quiresComp"][@data-slider-value = "[3,17]"])
};

declare %test:assertTrue function tsmssfilters:cuNumberCheckbox-checked-with-value() {
	let $node := <input data-template="app:CUnumberCheckbox" type="checkbox" value="CUnumber" />
	let $out := app:CUnumberCheckbox($node, map {}, "3")
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:cuNumberCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:CUnumberCheckbox" type="checkbox" value="CUnumber" />
	let $out := app:CUnumberCheckbox($node, map {}, ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-numberOfParts-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="CUnumber" /></div>
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {"numberOfParts": "3"}),
		(),
		(),
		(),
		(),
		"3",
		(),
		(),
		(),
		(),
		(),
		(),
		(),
		()
	)
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeCUnumberForm-hidden-without-param() {
	let $node := <div data-template="app:includeCUnumberForm" />
	let $out := app:includeCUnumberForm($node, tsmssfilters:model-for(map {}), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeCUnumberForm-visible-with-value() {
	let $node := <div data-template="app:includeCUnumberForm" />
	let $out := app:includeCUnumberForm($node, tsmssfilters:model-for(map {"numberOfParts": "3"}), "3")
	return exists($out/@style)
};

declare %test:assertTrue function tsmssfilters:includeCUnumberForm-echoes-value-when-active() {
	let $node := <div data-template="app:includeCUnumberForm" />
	let $out := app:includeCUnumberForm($node, tsmssfilters:model-for(map {"numberOfParts": "3"}), "3")
	return exists($out//*:input[@name = "numberOfParts"][@value = "3"])
};

(:~
 : scribe/donor/patron/owner/binder/objectType/contents/bindingtype:
 : same checkbox+section+include recipe as folia/writtenLines, but
 : simpler - all list-style params (app:list-param-active), and their
 : own field's value-echo was already working via app:formcontrol's
 : existing templates:form-control call (app:scribes/app:donors/etc),
 : untouched here.
 :)
declare %test:assertTrue function tsmssfilters:scribeCheckbox-checked-with-value() {
	let $node := <input data-template="app:scribeCheckbox" type="checkbox" value="scribe" />
	return exists(app:scribeCheckbox($node, map {}, "PRS1")/@checked)
};

declare %test:assertFalse function tsmssfilters:scribeCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:scribeCheckbox" type="checkbox" value="scribe" />
	return exists(app:scribeCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeScribeForm-hidden-without-param() {
	let $node := <div data-template="app:includeScribeForm" />
	return exists(app:includeScribeForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeScribeForm-visible-with-value() {
	let $node := <div data-template="app:includeScribeForm" />
	return exists(app:includeScribeForm($node, tsmssfilters:model-for(map {"scribe": "PRS1"}), "PRS1")/@style)
};

declare %test:assertTrue function tsmssfilters:donorCheckbox-checked-with-value() {
	let $node := <input data-template="app:donorCheckbox" type="checkbox" value="donor" />
	return exists(app:donorCheckbox($node, map {}, "PRS1")/@checked)
};

declare %test:assertFalse function tsmssfilters:donorCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:donorCheckbox" type="checkbox" value="donor" />
	return exists(app:donorCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeDonorForm-hidden-without-param() {
	let $node := <div data-template="app:includeDonorForm" />
	return exists(app:includeDonorForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeDonorForm-visible-with-value() {
	let $node := <div data-template="app:includeDonorForm" />
	return exists(app:includeDonorForm($node, tsmssfilters:model-for(map {"donor": "PRS1"}), "PRS1")/@style)
};

declare %test:assertTrue function tsmssfilters:patronCheckbox-checked-with-value() {
	let $node := <input data-template="app:patronCheckbox" type="checkbox" value="patron" />
	return exists(app:patronCheckbox($node, map {}, "PRS1")/@checked)
};

declare %test:assertFalse function tsmssfilters:patronCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:patronCheckbox" type="checkbox" value="patron" />
	return exists(app:patronCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includePatronForm-hidden-without-param() {
	let $node := <div data-template="app:includePatronForm" />
	return exists(app:includePatronForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includePatronForm-visible-with-value() {
	let $node := <div data-template="app:includePatronForm" />
	return exists(app:includePatronForm($node, tsmssfilters:model-for(map {"patron": "PRS1"}), "PRS1")/@style)
};

declare %test:assertTrue function tsmssfilters:ownerCheckbox-checked-with-value() {
	let $node := <input data-template="app:ownerCheckbox" type="checkbox" value="owner" />
	return exists(app:ownerCheckbox($node, map {}, "PRS1")/@checked)
};

declare %test:assertFalse function tsmssfilters:ownerCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:ownerCheckbox" type="checkbox" value="owner" />
	return exists(app:ownerCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeOwnerForm-hidden-without-param() {
	let $node := <div data-template="app:includeOwnerForm" />
	return exists(app:includeOwnerForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeOwnerForm-visible-with-value() {
	let $node := <div data-template="app:includeOwnerForm" />
	return exists(app:includeOwnerForm($node, tsmssfilters:model-for(map {"owner": "PRS1"}), "PRS1")/@style)
};

declare %test:assertTrue function tsmssfilters:binderCheckbox-checked-with-value() {
	let $node := <input data-template="app:binderCheckbox" type="checkbox" value="binder" />
	return exists(app:binderCheckbox($node, map {}, "PRS1")/@checked)
};

declare %test:assertFalse function tsmssfilters:binderCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:binderCheckbox" type="checkbox" value="binder" />
	return exists(app:binderCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeBinderForm-hidden-without-param() {
	let $node := <div data-template="app:includeBinderForm" />
	return exists(app:includeBinderForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeBinderForm-visible-with-value() {
	let $node := <div data-template="app:includeBinderForm" />
	return exists(app:includeBinderForm($node, tsmssfilters:model-for(map {"binder": "PRS1"}), "PRS1")/@style)
};

declare %test:assertTrue function tsmssfilters:objectTypeCheckbox-checked-with-value() {
	let $node := <input data-template="app:objectTypeCheckbox" type="checkbox" value="objectType" />
	return exists(app:objectTypeCheckbox($node, map {}, "parchment")/@checked)
};

declare %test:assertFalse function tsmssfilters:objectTypeCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:objectTypeCheckbox" type="checkbox" value="objectType" />
	return exists(app:objectTypeCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeObjectTypeForm-hidden-without-param() {
	let $node := <div data-template="app:includeObjectTypeForm" />
	return exists(
		app:includeObjectTypeForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")]
	)
};

declare %test:assertFalse function tsmssfilters:includeObjectTypeForm-visible-with-value() {
	let $node := <div data-template="app:includeObjectTypeForm" />
	return exists(
		app:includeObjectTypeForm($node, tsmssfilters:model-for(map {"support": "parchment"}), "parchment")/@style
	)
};

declare %test:assertTrue function tsmssfilters:contentsCheckbox-checked-with-value() {
	let $node := <input data-template="app:contentsCheckbox" type="checkbox" value="contents" />
	return exists(app:contentsCheckbox($node, map {}, "LIT1")/@checked)
};

declare %test:assertFalse function tsmssfilters:contentsCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:contentsCheckbox" type="checkbox" value="contents" />
	return exists(app:contentsCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeContentsForm-hidden-without-param() {
	let $node := <div data-template="app:includeContentsForm" />
	return exists(app:includeContentsForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeContentsForm-visible-with-value() {
	let $node := <div data-template="app:includeContentsForm" />
	return exists(app:includeContentsForm($node, tsmssfilters:model-for(map {"content": "LIT1"}), "LIT1")/@style)
};

declare %test:assertTrue function tsmssfilters:bindingtypeCheckbox-checked-with-value() {
	let $node := <input data-template="app:bindingtypeCheckbox" type="checkbox" value="bindingtype" />
	return exists(app:bindingtypeCheckbox($node, map {}, "contemporary")/@checked)
};

declare %test:assertFalse function tsmssfilters:bindingtypeCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:bindingtypeCheckbox" type="checkbox" value="bindingtype" />
	return exists(app:bindingtypeCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeBindingtypeForm-hidden-without-param() {
	let $node := <div data-template="app:includeBindingtypeForm" />
	return exists(
		app:includeBindingtypeForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")]
	)
};

declare %test:assertFalse function tsmssfilters:includeBindingtypeForm-visible-with-value() {
	let $node := <div data-template="app:includeBindingtypeForm" />
	return exists(
		app:includeBindingtypeForm(
			$node,
			tsmssfilters:model-for(map {"bindingtype": "contemporary"}),
			"contemporary"
		)/@style
	)
};

(:~
 : One representative check that the new facets actually participate
 : in app:manuscriptsFiltersSection's OR-condition (not just their own
 : checkbox/include functions) - the wiring most likely to have a
 : copy-paste slip across 8 near-identical additions.
 :)
declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-scribe-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="scribe" /></div>
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {"scribe": "PRS1"}),
		(),
		(),
		(),
		(),
		(),
		"PRS1",
		(),
		(),
		(),
		(),
		(),
		(),
		()
	)
	return exists($out/@style)
};

declare %test:assertFalse function tsmssfilters:manuscriptsFiltersSection-visible-when-bindingtype-active() {
	let $node := <div id="manuscriptsFilters" style="display: none"><input type="checkbox" value="bindingtype" /></div>
	let $out := app:manuscriptsFiltersSection(
		$node,
		tsmssfilters:model-for(map {"bindingtype": "contemporary"}),
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
		"contemporary"
	)
	return exists($out/@style)
};
