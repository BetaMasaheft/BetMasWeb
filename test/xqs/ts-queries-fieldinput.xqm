xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for newSearch.html's "#fields" field-scoped search rows
 : (q:fieldInputXXX, modules/queries.xqm): q:fieldinputTemplate never
 : echoed a submitted search string or operator, so a reload reset every
 : row to its default (empty text, "AND"). q:fieldInputTitle's auto-bound
 : parameter was also named "titleStmt-field", not "title-field" - the
 : name the rendered `<input>` actually submits - so it could never have
 : resolved from a real request even after adding the echo.
 : @see https://github.com/eeditiones/tei-publisher-lib
 :)
module namespace tsfieldinput = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-fieldinput";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

declare %test:assertTrue function tsfieldinput:template-echoes-value() {
	q:fieldinputTemplate("Signature", "signature", "foo bar", ())//input/@value = "foo bar"
};

declare %test:assertTrue function tsfieldinput:template-defaults-operator-to-AND() {
	let $out := q:fieldinputTemplate("Signature", "signature", (), ())
	return $out//option[@value = "AND"]/@selected = "selected" and empty($out//option[@value = "OR"]/@selected)
};

declare %test:assertTrue function tsfieldinput:template-selects-OR-when-submitted() {
	let $out := q:fieldinputTemplate("Signature", "signature", (), "OR")
	return $out//option[@value = "OR"]/@selected = "selected" and empty($out//option[@value = "AND"]/@selected)
};

(:~
 : Every q:fieldInputXXX wrapper is a thin pass-through to
 : q:fieldinputTemplate - checked together (rather than one near-identical
 : test function each) since the one bug this class of function has shown
 : in practice (q:fieldInputTitle's stale "titleStmt-field" parameter name)
 : is exactly a copy-paste mismatch between the wrapper's own parm name and
 : its rendered `<input>`/`<select>` @name attributes.
 :)
declare %test:assertTrue function tsfieldinput:every-wrapper-names-its-input-after-its-own-parm() {
	let $cases := map {
		"q:fieldInputSignature": "signature-field",
		"q:fieldInputDecoDesc": "decoDesc-field",
		"q:fieldInputHandDesc": "handDesc-field",
		"q:fieldInputBinding": "binding-field",
		"q:fieldInputSupportDesc": "supportDesc-field",
		"q:fieldInputMsContent": "msContent-field",
		"q:fieldInputText": "text-field",
		"q:fieldInputColophon": "colophon-field",
		"q:fieldInputIncipit": "incipit-field",
		"q:fieldInputExplicit": "explicit-field",
		"q:fieldInputAdditions": "additions-field",
		"q:fieldInputTitle": "title-field",
		"q:fieldInputPlace": "place-field",
		"q:fieldInputPerson": "person-field"
	}
	return every
		$fn-name in
		map:keys($cases) satisfies
		let $fn := function-lookup(xs:QName($fn-name), 4)
		let $out := $fn(<a />, map {}, "probe-value", "OR")
		return $out//input/@value = "probe-value" and
			$out//option[@value = "OR"]/@selected = "selected" and
			$out//input/@name = $cases($fn-name)
};

declare
	%test:assertXPath("$result//input/@name eq 'title-field'")
function tsfieldinput:fieldInputTitle-input-named-title-field() {
	q:fieldInputTitle(<a />, map {}, "Miracles of Mary", ())
};
