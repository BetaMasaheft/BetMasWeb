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
import module namespace tsdtsprev = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-dtslib-prevnext" at "ts-dtslib-prevnext.xqm";
import module namespace tsmainrels = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-item-mainrels" at "ts-item-mainrels.xqm";
import module namespace tsvinar = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-narrative" at "ts-viewitem-narrative.xqm";
import module namespace tsviplace = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-place" at "ts-viewitem-place.xqm";
import module namespace tsviauth = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-auth" at "ts-viewitem-auth.xqm";
import module namespace tsvimss = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-manuscript" at "ts-viewitem-manuscript.xqm";
import module namespace tsviwork = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-work" at "ts-viewitem-work.xqm";
import module namespace tsviperson = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-person" at "ts-viewitem-person.xqm";
import module namespace tsvidocs = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-documents" at "ts-viewitem-documents.xqm";
import module namespace tsseealso = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-item-seealso-options" at "ts-item-seealso-options.xqm";
import module namespace tszc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-zotero-cache" at "ts-zotero-cache.xqm";
import module namespace tsexpandtax = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-taxonomy" at "ts-expand-taxonomy.xqm";
import module namespace tsexpandtit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-titles" at "ts-expand-titles.xqm";
import module namespace tsmaincontent = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-restitem-maincontent" at "ts-restitem-maincontent.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

test:suite(
	(
		inspect:module-functions(xs:anyURI("ts-roaster-util.xqm")),
		inspect:module-functions(xs:anyURI("ts-dtslib-document.xqm")),
		inspect:module-functions(xs:anyURI("ts-dtslib-prevnext.xqm")),
		inspect:module-functions(xs:anyURI("ts-item-mainrels.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-narrative.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-place.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-auth.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-manuscript.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-work.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-person.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-documents.xqm")),
		inspect:module-functions(xs:anyURI("ts-item-seealso-options.xqm")),
		inspect:module-functions(xs:anyURI("ts-zotero-cache.xqm")),
		inspect:module-functions(xs:anyURI("ts-expand-taxonomy.xqm")),
		inspect:module-functions(xs:anyURI("ts-expand-titles.xqm")),
		inspect:module-functions(xs:anyURI("ts-restitem-maincontent.xqm")),
		inspect:module-functions(xs:anyURI("ts-permrestitem-maincontent.xqm"))
	)
)
