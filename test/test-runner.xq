xquery version "3.1";

(:~ This library runs the XQSuite unit tests for the BetMasWeb.
 : TODO(DP): untested scaffold  here to collect pre-existing test code
 :
 : @author Duncan Paterson
 : @version 1.0.0-Alpha
 : @see http://www.exist-db.org/exist/apps/doc/xqsuite
 :)
import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all";


declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";


test:suite(
  (
    inspect:module-functions(xs:anyURI("all.xqm")),
    inspect:module-functions(xs:anyURI("wordCount.xqm"))
  )
)