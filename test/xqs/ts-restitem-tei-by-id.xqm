xquery version "3.1" encoding "UTF-8";

(:~
 : restItem:ITEM used to resolve via $collect//t:TEI[@xml:id eq $id].
 : Contract: same node as ($collect/id($id))[self::t:TEI] (test helper shape).
 :)
module namespace tsresttei = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-restitem-tei-by-id";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "../../modules/switch2.xqm";

declare %private function tsresttei:via-xpath($collect as node()*, $id as xs:string) as element(t:TEI)* {
	$collect//t:TEI[@xml:id eq $id]
};

declare %private function tsresttei:via-id($collect as node()*, $id as xs:string) as element(t:TEI)* {
	($collect/id($id))[self::t:TEI]
};

declare
	%test:name("restItem tei resolve: manuscripts AG00001") %test:assertEquals(1, 1, "AG00001")
function tsresttei:mss-ag00001() {
	let $c := switch2:collectionVar("manuscripts")
	let $xpath := tsresttei:via-xpath($c, "AG00001")
	let $idfn := tsresttei:via-id($c, "AG00001")
	return (count($xpath), count($idfn), string(($idfn/@xml:id)[1]))
};

declare
	%test:name("restItem tei resolve: works LIT3508Epistle") %test:assertEquals(1, 1, "LIT3508Epistle")
function tsresttei:works-lit3508() {
	let $c := switch2:collectionVar("works")
	let $xpath := tsresttei:via-xpath($c, "LIT3508Epistle")
	let $idfn := tsresttei:via-id($c, "LIT3508Epistle")
	return (count($xpath), count($idfn), string(($idfn/@xml:id)[1]))
};

declare %test:name("restItem tei resolve: xpath and id() same TEI") %test:assertTrue function tsresttei:parity-persons(

) {
	let $c := switch2:collectionVar("persons")
	let $id := "PRS8278SablaWa"
	return deep-equal(tsresttei:via-xpath($c, $id), tsresttei:via-id($c, $id))
};
