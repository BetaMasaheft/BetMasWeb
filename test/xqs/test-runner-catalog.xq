xquery version "3.1";

(:~
 : Focused XQSuite runner: catalog contract + selectors only.
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace test = "http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace inspect = "http://exist-db.org/xquery/inspection";

declare option output:method "json";
declare option output:media-type "application/json";

test:suite(
	(
		inspect:module-functions(xs:anyURI("ts-catalog-contract.xqm")),
		inspect:module-functions(xs:anyURI("ts-catalog-selectors.xqm"))
	)
)
