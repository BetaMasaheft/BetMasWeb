xquery version "3.1";

(:~
 : Local fast path for agent-stack iteration. CI and full suite use ../test-runner.xq.
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace inspect = "http://exist-db.org/xquery/inspection";
import module namespace tsexpnorm = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-normalize-dimensions" at "../ts-expand-normalize-dimensions.xqm";
import module namespace tsvicomputed = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-computed" at "../ts-viewitem-computed.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

test:suite(
	(
		inspect:module-functions(xs:anyURI("../ts-expand-normalize-dimensions.xqm")),
		inspect:module-functions(xs:anyURI("../ts-viewitem-computed.xqm"))
	)
)
