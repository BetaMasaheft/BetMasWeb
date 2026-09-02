xquery version "3.0" encoding "UTF-8";

declare namespace saxon = "http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "xmldb:exist:///db/apps/BetMasWeb/modules/queries.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace new = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/new" at "xmldb:exist:///db/apps/BetMasWeb/modules/newEntry.xqm";
import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "xmldb:exist:///db/apps/BetMasWeb/modules/resources.xqm";
import module namespace indexesNE = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/indexesNE" at "xmldb:exist:///db/apps/BetMasWeb/modules/indexesNE.xqm";
import module namespace tl = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/timeline" at "xmldb:exist:///db/apps/BetMasWeb/modules/timeline.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app" at "xmldb:exist:///db/apps/BetMasWeb/modules/app.xqm";
import module namespace zc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/zc" at "xmldb:exist:///db/apps/BetMasWeb/modules/zoteroCache.xqm";

declare option output:method "xhtml";
declare option output:omit-xml-declaration "no";
declare option saxon:output "omit-xml-declaration=no";
declare option output:media-type "text/html";

(:~
 : Top-down replacement for the now-unused templates:surround (deprecated
 : upstream - github.com/eXist-db/templating#37 - not for removal, but its
 : inner-evaluated-first/outer-evaluated-after order made the model hard
 : to reason about at any given point). Called from the wrapper's own
 : content slot (see e.g. templates/newpage.html's id="content" div) - the
 : wrapper, not the page, is templates:apply's root document (see below),
 : so this renders $model("page-content")'s own children into that slot:
 : the same "insert the page's content into the wrapper's content slot"
 : shape templates:surround always produced, just reached top-down - the
 : wrapper is the entry point and pulls the page in, instead of the page
 : pulling the wrapper in around itself.
 :)
declare %templates:wrap function local:include-page($node as node(), $model as map(*)) {
	templates:process($model("page-content")/node(), $model)
};

(:~
 : templates:apply lookup function for this module, referenced by name
 : (local:lookup#2) below instead of an inline closure - see
 : config:template-lookup-resolve for why the function-lookup() probe
 : still has to be written locally per module rather than shared in
 : config.xqm too.
 :)
declare function local:lookup($functionName as xs:string, $arity as xs:integer) as function(*)? {
	config:template-lookup-resolve(
		"view.xql",
		$functionName,
		$arity,
		try { function-lookup(xs:QName($functionName), $arity) } catch * { () }
	)
};

(:
 : No template in this app uses class="ns:function" dispatch (data-template
 : is the only syntax in use) - disabling class-syntax lookup skips a
 : tokenize+regex check on @class for every element that isn't templated.
 :)
let $config := map:merge((config:template-apply-config(), map {$templates:CONFIG_APP_ROOT: $config:app-root}))

(:
 : A full page declares which wrapper it mounts into via @data-wrapper on
 : its own root element - plain data read directly here, not a templating
 : instruction (the page itself is never passed to templates:apply in that
 : case). $model is pre-populated with the page's own content before
 : rendering starts, then templates:apply runs against the WRAPPER as the
 : root document - see local:include-page above.
 :
 : Every .html resource in this app is forwarded through this view
 : (controller.xql's generic catch-all matches by extension, not by
 : content), including the standalone forms/*.html fragments fetched
 : client-side via AJAX and injected into an already-rendered page - those
 : have no @data-wrapper and were never meant to be wrapped at all, so they
 : fall through to plain templates:apply on the fragment itself, same as
 : before this file had any wrapper concept.
 :)
let $page := request:get-data()
let $root := ($page/self::element(), $page/*)[1]
let $wrapperPath := $root/@data-wrapper/string()
return if ($wrapperPath) then
	templates:apply(config:resolve($wrapperPath), local:lookup#2, map {"page-content": $root}, $config)
else
	templates:apply($page, local:lookup#2, (), $config)
