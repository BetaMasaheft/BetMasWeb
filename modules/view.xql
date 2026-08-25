xquery version "3.0" encoding "UTF-8";

declare namespace saxon = "http://saxon.sf.net/";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "xmldb:exist:///db/apps/BetMasWeb/modules/queries.xqm";
import module namespace apidoc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apidoc" at "xmldb:exist:///db/apps/BetMasWeb/modules/apidocumentation.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace new = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/new" at "xmldb:exist:///db/apps/BetMasWeb/modules/newEntry.xqm";
import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "xmldb:exist:///db/apps/BetMasWeb/modules/resources.xqm";
import module namespace indexesNE = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/indexesNE" at "xmldb:exist:///db/apps/BetMasWeb/modules/indexesNE.xqm";
import module namespace tl = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/timeline" at "xmldb:exist:///db/apps/BetMasWeb/modules/timeline.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app" at "xmldb:exist:///db/apps/BetMasWeb/modules/app.xqm";

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

(:
 : No template in this app uses class="ns:function" dispatch (data-template
 : is the only syntax in use) - disabling class-syntax lookup skips a
 : tokenize+regex check on @class for every element that isn't templated.
 :)
let $config := map {
	$templates:CONFIG_APP_ROOT: $config:app-root,
	$templates:CONFIG_STOP_ON_ERROR: true(),
	$templates:CONFIG_USE_CLASS_SYNTAX: false(),
	(:
	 : %templates:wrap (used by local:include-page below, and pre-existing
	 : on e.g. lists:titlesRes) reconstructs the calling element and, by
	 : default, keeps its own data-template attribute on the output - not
	 : just harmless dead markup, but a mismatch against the old
	 : templates:surround-produced output. Strip it.
	 :)
	$templates:CONFIG_FILTER_ATTRIBUTES: true()
}

(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :
 : templates:resolve() probes arity 2..$templates:MAX_ARITY, calling this
 : function once per arity until one succeeds - most of those calls are
 : expected misses, not errors. Only log when the *last* arity in that
 : range still comes up empty, since that's the one call that means
 : "genuinely no such function", not "wrong arity, keep trying". Without
 : this, a typo'd/removed data-template target fails completely silently -
 : the element just gets copied through unprocessed with no trace anywhere.
 :)
let $lookup := function ($functionName as xs:string, $arity as xs:int) {
	let $fn := try { function-lookup(xs:QName($functionName), $arity) } catch * { () }
	return if (empty($fn) and $arity = $templates:MAX_ARITY) then (
		util:log(
			"warn",
			'view.xql: no function found for data-template="' ||
				$functionName ||
				'" (probed arity 2..' ||
				$templates:MAX_ARITY ||
				")"
		),
		()
	) else
		$fn
}
(:
 : The page forwarded by the controller declares which wrapper it mounts
 : into via @data-wrapper on its own root element - plain data read
 : directly here, not a templating instruction (the page itself is never
 : passed to templates:apply). $model is pre-populated with the page's own
 : content before rendering starts, then templates:apply runs against the
 : WRAPPER as the root document - see local:include-page above.
 :)
let $page := request:get-data()
let $root := ($page/self::element(), $page/*)[1]
let $wrapperPath := $root/@data-wrapper/string()
return templates:apply(config:resolve($wrapperPath), $lookup, map {"page-content": $root}, $config)
