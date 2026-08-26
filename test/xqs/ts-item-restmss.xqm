xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/item.xqm's item2:RestMssTemplate - the
 : templates:apply adapter item2:RestSeeAlso now calls instead of
 : item2:RestMss directly. Naming follows tei-publisher-lib:
 : test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :)
module namespace tsrestmss = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-item-restmss";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "../../modules/item.xqm";

(:~
 : Confirms the adapter produces the exact same output as the plain call
 : it replaces, for a work with known manuscript witnesses.
 :)
declare %test:assertTrue function tsrestmss:template-adapter-matches-direct-call() {
	deep-equal(item2:RestMssTemplate(<div />, map {"id": "LIT3508Epistle"}), item2:RestMss("LIT3508Epistle"))
};
