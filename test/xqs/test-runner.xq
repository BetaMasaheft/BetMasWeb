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
import module namespace tsrestmss = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-item-restmss" at "ts-item-restmss.xqm";
import module namespace tszc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-zotero-cache" at "ts-zotero-cache.xqm";
import module namespace tsexpandtax = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-taxonomy" at "ts-expand-taxonomy.xqm";
import module namespace tsexpandtit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-titles" at "ts-expand-titles.xqm";
import module namespace tsexpedids = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-edition-ids" at "ts-expand-edition-ids.xqm";
import module namespace tsmaincontent = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-restitem-maincontent" at "ts-restitem-maincontent.xqm";
import module namespace tspermmaincontent = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-permrestitem-maincontent" at "ts-permrestitem-maincontent.xqm";
import module namespace tsformbounds = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-formbounds" at "ts-queries-formbounds.xqm";
import module namespace tsbatchexp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-batch-expand" at "ts-batch-expand.xqm";
import module namespace tstitlecache = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-title-cache" at "ts-title-cache.xqm";
import module namespace tsreslookup = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-resources-titlelookup" at "ts-resources-titlelookup.xqm";
import module namespace tstitlesres = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-resources-titlesres" at "ts-resources-titlesres.xqm";
import module namespace tsformbatch = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-resources-formbatch" at "ts-resources-formbatch.xqm";
import module namespace tstitlesconsol = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-titles-consolidation" at "ts-titles-consolidation.xqm";
import module namespace tsprinttitle = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-exptit-printtitle" at "ts-exptit-printtitle.xqm";
import module namespace tspersrole = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-app-persrole" at "ts-app-persrole.xqm";
import module namespace tsmssfilters = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-app-msfilters" at "ts-app-msfilters.xqm";
import module namespace tscrange = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-computed-range-filters" at "ts-computed-range-filters.xqm";
import module namespace tswpfilters = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-app-worksplaces-filters" at "ts-app-worksplaces-filters.xqm";
import module namespace tsfieldinput = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-fieldinput" at "ts-queries-fieldinput.xqm";
import module namespace tssortingkey = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-sortingkey" at "ts-queries-sortingkey.xqm";
import module namespace tsfacetdiv = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-facetdiv" at "ts-queries-facetdiv.xqm";
import module namespace tsfilterspanel = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-filterspanel" at "ts-queries-filterspanel.xqm";
import module namespace tsplainfields = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-plainfields" at "ts-queries-plainfields.xqm";
import module namespace tscharts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-charts-datefilter" at "ts-charts-datefilter.xqm";
import module namespace tstaglia = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-charts-tagliasupport" at "ts-charts-tagliasupport.xqm";
import module namespace tslistids = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-listids-cache" at "ts-listids-cache.xqm";

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
		inspect:module-functions(xs:anyURI("ts-item-restmss.xqm")),
		inspect:module-functions(xs:anyURI("ts-zotero-cache.xqm")),
		inspect:module-functions(xs:anyURI("ts-expand-taxonomy.xqm")),
		inspect:module-functions(xs:anyURI("ts-expand-titles.xqm")),
		inspect:module-functions(xs:anyURI("ts-expand-edition-ids.xqm")),
		inspect:module-functions(xs:anyURI("ts-expand-normalize-dimensions.xqm")),
		inspect:module-functions(xs:anyURI("ts-viewitem-computed.xqm")),
		inspect:module-functions(xs:anyURI("ts-restitem-maincontent.xqm")),
		inspect:module-functions(xs:anyURI("ts-permrestitem-maincontent.xqm")),
		inspect:module-functions(xs:anyURI("ts-queries-formbounds.xqm")),
		inspect:module-functions(xs:anyURI("ts-batch-expand.xqm")),
		inspect:module-functions(xs:anyURI("ts-title-cache.xqm")),
		inspect:module-functions(xs:anyURI("ts-resources-titlelookup.xqm")),
		inspect:module-functions(xs:anyURI("ts-resources-titlesres.xqm")),
		inspect:module-functions(xs:anyURI("ts-resources-formbatch.xqm")),
		inspect:module-functions(xs:anyURI("ts-titles-consolidation.xqm")),
		inspect:module-functions(xs:anyURI("ts-exptit-printtitle.xqm")),
		inspect:module-functions(xs:anyURI("xmldb:exist:///db/apps/BetMasWeb/modules/titlesData.xqm")),
		inspect:module-functions(xs:anyURI("ts-app-persrole.xqm")),
		inspect:module-functions(xs:anyURI("ts-app-msfilters.xqm")),
		inspect:module-functions(xs:anyURI("ts-computed-range-filters.xqm")),
		inspect:module-functions(xs:anyURI("ts-app-worksplaces-filters.xqm")),
		inspect:module-functions(xs:anyURI("ts-queries-fieldinput.xqm")),
		inspect:module-functions(xs:anyURI("ts-queries-sortingkey.xqm")),
		inspect:module-functions(xs:anyURI("ts-queries-facetdiv.xqm")),
		inspect:module-functions(xs:anyURI("ts-queries-filterspanel.xqm")),
		inspect:module-functions(xs:anyURI("ts-queries-plainfields.xqm")),
		inspect:module-functions(xs:anyURI("ts-charts-datefilter.xqm")),
		inspect:module-functions(xs:anyURI("ts-charts-tagliasupport.xqm")),
		inspect:module-functions(xs:anyURI("ts-listids-cache.xqm"))
	)
)
