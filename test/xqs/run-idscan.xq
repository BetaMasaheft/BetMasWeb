xquery version "3.1";

(:~
 : Targeted XQSuite runner for the id-bearing scans in modules/queries.xqm.
 :
 : The full runner (test/xqs/test-runner.xq) executes every suite in one
 : request, which makes a single-function change slow to iterate on. This
 : runner inspects ts-queries-idscan.xqm alone and speaks the same JSON
 : protocol, so test/xqs/xqSuite.js can drive it unchanged:
 :
 : XQS_URL=http://127.0.0.1:8080/exist/rest/db/apps/BetMasWeb/test/xqs/run-idscan.xq \
 : EXISTDB_USER=admin EXISTDB_PASS= node --test test/xqs/xqSuite.js
 :
 : ts-queries-idscan.xqm stays registered in the full runner too, so this is
 : an iteration aid, not a second home for the tests.
 :
 : @see https://github.com/eXist-db/exist-markdown/blob/master/test/xqs/test-runner.xq
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace inspect = "http://exist-db.org/xquery/inspection";
import module namespace tsidscan = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-idscan" at "ts-queries-idscan.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

test:suite(inspect:module-functions(xs:anyURI("ts-queries-idscan.xqm")))
