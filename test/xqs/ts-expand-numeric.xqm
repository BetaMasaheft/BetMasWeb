xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for expand:normalize-numeric-text/expand:normalize-decimal -
 : the dimension/layout value normalization used so the numeric range
 : index on height/width/depth/dim/writtenLines can be retyped safely
 : (comma-decimals recovered, min-max ranges collapsed to their
 : midpoint, everything else left untouched).
 :)
module namespace tsexpandnum = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-numeric";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

declare
	%test:arg("v", "220")
	%test:assertEquals("220")
	%test:arg("v", "19,5")
	%test:assertEquals("19.5")
	%test:arg("v", "18-19")
	%test:assertEquals("18.5")
	%test:arg("v", "24–30")
	%test:assertEquals("27")
	%test:arg("v", "27 31")
	%test:assertEquals("29")
	%test:arg("v", "ca.153")
	%test:assertEquals("ca.153")
	%test:arg("v", "27.5x24.5x5.5")
	%test:assertEquals("27.5x24.5x5.5")
function tsexpandnum:normalize-numeric-text($v as xs:string) {
	expand:normalize-numeric-text($v)
};

declare %test:assertTrue function tsexpandnum:normalize-decimal-keeps-attributes() {
	let $node := <height xmlns="http://www.tei-c.org/ns/1.0" unit="mm">19,5</height>
	let $out := expand:normalize-decimal($node)
	return string($out/@unit) eq "mm"
};

declare %test:assertEquals("19.5") function tsexpandnum:normalize-decimal-fixes-comma() {
	let $node := <height xmlns="http://www.tei-c.org/ns/1.0">19,5</height>
	return string(expand:normalize-decimal($node))
};

declare %test:assertEquals("18.5") function tsexpandnum:normalize-decimal-collapses-range() {
	let $node := <dim xmlns="http://www.tei-c.org/ns/1.0" type="top">18-19</dim>
	return string(expand:normalize-decimal($node))
};

declare %test:assertEquals("dim") function tsexpandnum:normalize-decimal-keeps-element-name() {
	let $node := <dim xmlns="http://www.tei-c.org/ns/1.0" type="top">18-19</dim>
	return local-name(expand:normalize-decimal($node))
};
