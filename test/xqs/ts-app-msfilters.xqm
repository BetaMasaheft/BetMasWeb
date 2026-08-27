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
 : languages/keywords/relations live under "General filters" directly
 : (no wrapping reveal section - unlike every other facet in this
 : module, that div has no id/style of its own to toggle), so only
 : checkbox+include need testing here, no section-active case.
 :)
declare %test:assertTrue function tsmssfilters:languagesCheckbox-checked-with-value() {
	let $node := <input data-template="app:languagesCheckbox" type="checkbox" value="languages" />
	return exists(app:languagesCheckbox($node, map {}, "eng")/@checked)
};

declare %test:assertFalse function tsmssfilters:languagesCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:languagesCheckbox" type="checkbox" value="languages" />
	return exists(app:languagesCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeLanguagesForm-hidden-without-param() {
	let $node := <div data-template="app:includeLanguagesForm" />
	return exists(app:includeLanguagesForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeLanguagesForm-visible-with-value() {
	let $node := <div data-template="app:includeLanguagesForm" />
	return exists(app:includeLanguagesForm($node, tsmssfilters:model-for(map {"language": "eng"}), "eng")/@style)
};

declare %test:assertTrue function tsmssfilters:keywordsCheckbox-checked-with-value() {
	let $node := <input data-template="app:keywordsCheckbox" type="checkbox" value="keywords" />
	return exists(app:keywordsCheckbox($node, map {}, "kw1")/@checked)
};

declare %test:assertFalse function tsmssfilters:keywordsCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:keywordsCheckbox" type="checkbox" value="keywords" />
	return exists(app:keywordsCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeKeywordsForm-hidden-without-param() {
	let $node := <div data-template="app:includeKeywordsForm" />
	return exists(app:includeKeywordsForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeKeywordsForm-visible-with-value() {
	let $node := <div data-template="app:includeKeywordsForm" />
	return exists(app:includeKeywordsForm($node, tsmssfilters:model-for(map {"keyword": "kw1"}), "kw1")/@style)
};

declare %test:assertTrue function tsmssfilters:relationsCheckbox-checked-with-value() {
	let $node := <input data-template="app:relationsCheckbox" type="checkbox" value="relations" />
	return exists(app:relationsCheckbox($node, map {}, "rel1")/@checked)
};

declare %test:assertFalse function tsmssfilters:relationsCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:relationsCheckbox" type="checkbox" value="relations" />
	return exists(app:relationsCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeRelationsForm-hidden-without-param() {
	let $node := <div data-template="app:includeRelationsForm" />
	return exists(app:includeRelationsForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeRelationsForm-visible-with-value() {
	let $node := <div data-template="app:includeRelationsForm" />
	return exists(app:includeRelationsForm($node, tsmssfilters:model-for(map {"relType": "rel1"}), "rel1")/@style)
};

declare %test:assertTrue function tsmssfilters:dateInput-echoes-submitted-range() {
	let $out := app:dateInput(<a />, map {}, "500,1500")
	return $out/@data-slider-value = "[500,1500]"
};

declare %test:assertTrue function tsmssfilters:dateInput-defaults-to-full-range-without-param() {
	let $out := app:dateInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,2000]"
};

declare %test:assertTrue function tsmssfilters:dateCheckbox-checked-with-nondefault-range() {
	let $node := <input data-template="app:dateCheckbox" type="checkbox" value="date" />
	let $out := app:dateCheckbox($node, map {}, "500,1500")
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:dateCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:dateCheckbox" type="checkbox" value="date" />
	let $out := app:dateCheckbox($node, map {}, ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:dateCheckbox-unchecked-with-default-range() {
	let $node := <input data-template="app:dateCheckbox" type="checkbox" value="date" />
	let $out := app:dateCheckbox($node, map {}, "1,2000")
	return exists($out/@checked)
};

declare %test:assertTrue function tsmssfilters:includeDateForm-hidden-without-param() {
	let $node := <div data-template="app:includeDateForm" />
	return exists(app:includeDateForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeDateForm-visible-with-nondefault-range() {
	let $node := <div data-template="app:includeDateForm" />
	return exists(app:includeDateForm($node, tsmssfilters:model-for(map {"dateRange": "500,1500"}), "500,1500")/@style)
};

declare %test:assertTrue function tsmssfilters:scriptCheckbox-checked-with-value() {
	let $node := <input data-template="app:scriptCheckbox" type="checkbox" value="script" />
	return exists(app:scriptCheckbox($node, map {}, "GeezScript")/@checked)
};

declare %test:assertFalse function tsmssfilters:scriptCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:scriptCheckbox" type="checkbox" value="script" />
	return exists(app:scriptCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeScriptForm-hidden-without-param() {
	let $node := <div data-template="app:includeScriptForm" />
	return exists(app:includeScriptForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeScriptForm-visible-with-value() {
	let $node := <div data-template="app:includeScriptForm" />
	return exists(app:includeScriptForm($node, tsmssfilters:model-for(map {"script": "GeezScript"}), "GeezScript")/@style)
};

declare %test:assertTrue function tsmssfilters:parchmentMakerCheckbox-checked-with-value() {
	let $node := <input data-template="app:parchmentMakerCheckbox" type="checkbox" value="parchmentMaker" />
	return exists(app:parchmentMakerCheckbox($node, map {}, "PRS1")/@checked)
};

declare %test:assertFalse function tsmssfilters:parchmentMakerCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:parchmentMakerCheckbox" type="checkbox" value="parchmentMaker" />
	return exists(app:parchmentMakerCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeParchmentMakerForm-hidden-without-param() {
	let $node := <div data-template="app:includeParchmentMakerForm" />
	return exists(
		app:includeParchmentMakerForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")]
	)
};

declare %test:assertFalse function tsmssfilters:includeParchmentMakerForm-visible-with-value() {
	let $node := <div data-template="app:includeParchmentMakerForm" />
	return exists(
		app:includeParchmentMakerForm($node, tsmssfilters:model-for(map {"parchmentMaker": "PRS1"}), "PRS1")/@style
	)
};

declare %test:assertTrue function tsmssfilters:materialCheckbox-checked-with-value() {
	let $node := <input data-template="app:materialCheckbox" type="checkbox" value="material" />
	return exists(app:materialCheckbox($node, map {}, "parchment")/@checked)
};

declare %test:assertFalse function tsmssfilters:materialCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:materialCheckbox" type="checkbox" value="material" />
	return exists(app:materialCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeMaterialForm-hidden-without-param() {
	let $node := <div data-template="app:includeMaterialForm" />
	return exists(app:includeMaterialForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeMaterialForm-visible-with-value() {
	let $node := <div data-template="app:includeMaterialForm" />
	return exists(
		app:includeMaterialForm($node, tsmssfilters:model-for(map {"material": "parchment"}), "parchment")/@style
	)
};

declare %test:assertTrue function tsmssfilters:bmaterialCheckbox-checked-with-value() {
	let $node := <input data-template="app:bmaterialCheckbox" type="checkbox" value="bmaterial" />
	return exists(app:bmaterialCheckbox($node, map {}, "leather")/@checked)
};

declare %test:assertFalse function tsmssfilters:bmaterialCheckbox-unchecked-without-param() {
	let $node := <input data-template="app:bmaterialCheckbox" type="checkbox" value="bmaterial" />
	return exists(app:bmaterialCheckbox($node, map {}, ())/@checked)
};

declare %test:assertTrue function tsmssfilters:includeBmaterialForm-hidden-without-param() {
	let $node := <div data-template="app:includeBmaterialForm" />
	return exists(app:includeBmaterialForm($node, tsmssfilters:model-for(map {}), ())/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeBmaterialForm-visible-with-value() {
	let $node := <div data-template="app:includeBmaterialForm" />
	return exists(app:includeBmaterialForm($node, tsmssfilters:model-for(map {"bmaterial": "leather"}), "leather")/@style)
};

declare %test:assertTrue function tsmssfilters:heightInput-echoes-submitted-range() {
	let $out := app:heightInput(<a />, map {}, "50,300")
	return $out/@data-slider-value = "[50,300]"
};

declare %test:assertTrue function tsmssfilters:heightInput-defaults-to-full-range-without-param() {
	let $out := app:heightInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,1000]"
};

declare %test:assertTrue function tsmssfilters:widthInput-echoes-submitted-range() {
	let $out := app:widthInput(<a />, map {}, "50,300")
	return $out/@data-slider-value = "[50,300]"
};

declare %test:assertTrue function tsmssfilters:widthInput-defaults-to-full-range-without-param() {
	let $out := app:widthInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,1000]"
};

declare %test:assertTrue function tsmssfilters:depthInput-echoes-submitted-range() {
	let $out := app:depthInput(<a />, map {}, "10,60")
	return $out/@data-slider-value = "[10,60]"
};

declare %test:assertTrue function tsmssfilters:depthInput-defaults-to-full-range-without-param() {
	let $out := app:depthInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,1000]"
};

declare %test:assertTrue function tsmssfilters:columnsNumInput-echoes-submitted-range() {
	let $out := app:columnsNumInput(<a />, map {}, "1,3")
	return $out/@data-slider-value = "[1,3]"
};

declare %test:assertTrue function tsmssfilters:columnsNumInput-defaults-to-full-range-without-param() {
	let $out := app:columnsNumInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,20]"
};

declare %test:assertTrue function tsmssfilters:tmarginInput-echoes-submitted-range() {
	let $out := app:tmarginInput(<a />, map {}, "5,40")
	return $out/@data-slider-value = "[5,40]"
};

declare %test:assertTrue function tsmssfilters:tmarginInput-defaults-to-full-range-without-param() {
	let $out := app:tmarginInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,100]"
};

declare %test:assertTrue function tsmssfilters:bmarginInput-echoes-submitted-range() {
	let $out := app:bmarginInput(<a />, map {}, "5,40")
	return $out/@data-slider-value = "[5,40]"
};

declare %test:assertTrue function tsmssfilters:bmarginInput-defaults-to-full-range-without-param() {
	let $out := app:bmarginInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,100]"
};

declare %test:assertTrue function tsmssfilters:rmarginInput-echoes-submitted-range() {
	let $out := app:rmarginInput(<a />, map {}, "5,40")
	return $out/@data-slider-value = "[5,40]"
};

declare %test:assertTrue function tsmssfilters:rmarginInput-defaults-to-full-range-without-param() {
	let $out := app:rmarginInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,100]"
};

declare %test:assertTrue function tsmssfilters:lmarginInput-echoes-submitted-range() {
	let $out := app:lmarginInput(<a />, map {}, "5,40")
	return $out/@data-slider-value = "[5,40]"
};

declare %test:assertTrue function tsmssfilters:lmarginInput-defaults-to-full-range-without-param() {
	let $out := app:lmarginInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,100]"
};

declare %test:assertTrue function tsmssfilters:intercolumnInput-echoes-submitted-range() {
	let $out := app:intercolumnInput(<a />, map {}, "5,40")
	return $out/@data-slider-value = "[5,40]"
};

declare %test:assertTrue function tsmssfilters:intercolumnInput-defaults-to-full-range-without-param() {
	let $out := app:intercolumnInput(<a />, map {}, ())
	return $out/@data-slider-value = "[1,100]"
};

declare %test:assertTrue function tsmssfilters:dimensionsCheckbox-checked-when-one-field-active() {
	let $node := <input data-template="app:dimensionsCheckbox" type="checkbox" value="dimensions" />
	let $out := app:dimensionsCheckbox($node, map {}, "50,300", (), (), (), (), (), (), (), ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:dimensionsCheckbox-unchecked-without-any-param() {
	let $node := <input data-template="app:dimensionsCheckbox" type="checkbox" value="dimensions" />
	let $out := app:dimensionsCheckbox($node, map {}, (), (), (), (), (), (), (), (), ())
	return exists($out/@checked)
};

declare %test:assertFalse function tsmssfilters:dimensionsCheckbox-unchecked-when-all-at-default() {
	let $node := <input data-template="app:dimensionsCheckbox" type="checkbox" value="dimensions" />
	let $out := app:dimensionsCheckbox(
		$node,
		map {},
		"1,1000",
		"1,1000",
		"1,1000",
		"1,20",
		"1,100",
		"1,100",
		"1,100",
		"1,100",
		"1,100"
	)
	return exists($out/@checked)
};

declare %test:assertTrue function tsmssfilters:includeDimensionsForm-hidden-without-any-param() {
	let $node := <div data-template="app:includeDimensionsForm" />
	let $out := app:includeDimensionsForm($node, tsmssfilters:model-for(map {}), (), (), (), (), (), (), (), (), ())
	return exists($out/@style[contains(., "display:none")])
};

declare %test:assertFalse function tsmssfilters:includeDimensionsForm-visible-when-one-field-active() {
	let $node := <div data-template="app:includeDimensionsForm" />
	let $out := app:includeDimensionsForm(
		$node,
		tsmssfilters:model-for(map {"height": "50,300"}),
		"50,300",
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
