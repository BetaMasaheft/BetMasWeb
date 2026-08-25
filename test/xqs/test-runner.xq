xquery version "3.1";

(:~
 : XQSuite runner for BetMasWeb.
 : Returns JSON (for mocha test/xqs/xqSuite.js), following exist-markdown.
 :
 : @see https://github.com/eXist-db/exist-markdown/blob/master/test/xqs/test-runner.xq
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/44
 : @see http://www.exist-db.org/exist/apps/doc/xqsuite
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace inspect = "http://exist-db.org/xquery/inspection";
(: Relative imports resolve when this runner lives under /db/apps/BetMasWeb/test/xqs/. :)
import module namespace tsrutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-roaster-util" at "ts-roaster-util.xqm";
import module namespace tsdtsdoc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-dtslib-document" at "ts-dtslib-document.xqm";
import module namespace tszc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-zotero-cache" at "ts-zotero-cache.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

test:suite(
	(
		inspect:module-functions(xs:anyURI("ts-roaster-util.xqm")),
		inspect:module-functions(xs:anyURI("ts-dtslib-document.xqm")),
		inspect:module-functions(xs:anyURI("ts-zotero-cache.xqm"))
	)
)
