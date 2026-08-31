xquery version "3.1";

(:~
 : Targeted XQSuite runner — edition @xml:id minting only.
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace inspect = "http://exist-db.org/xquery/inspection";
import module namespace tsexpedids = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-edition-ids" at "../ts-expand-edition-ids.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

test:suite((inspect:module-functions(xs:anyURI("../ts-expand-edition-ids.xqm"))))
