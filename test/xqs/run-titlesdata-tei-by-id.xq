xquery version "3.1";

(:~
 : Focused runner for ts-titlesdata-tei-by-id.
 : XQS_URL=http://127.0.0.1:8082/exist/rest/db/apps/BetMasWeb/test/xqs/run-titlesdata-tei-by-id.xq
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace inspect = "http://exist-db.org/xquery/inspection";

declare option output:method "json";
declare option output:media-type "application/json";

test:suite(inspect:module-functions(xs:anyURI("ts-titlesdata-tei-by-id.xqm")))
