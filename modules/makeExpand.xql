xquery version "3.1" encoding "UTF-8";

(:~
 : HTTP / REST entry for parametrized batch expand.
 : GET|POST …/modules/makeExpand.xql?collection=/db/apps/BetMasData/works/1-1000
 : GET|POST …/modules/makeExpand.xql?mode=unmirrored&collection=/db/apps/BetMasData/manuscripts
 : Optional ?enrich=bibl,titles — allowlist of enrichments to keep on
 : (absent → expand module defaults; empty → both off). See batchExpand:enrich-opts.
 :
 : Requires an authenticated non-guest principal who is DBA or in Editors.
 : For xst / util:eval without HTTP, call batchExpand:expandCollection or
 : batchExpand:expandUnmirrored directly (an unbound `external` variable
 : breaks REST ?collection= in eXist).
 :
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 : @see https://github.com/BetaMasaheft/expanded/issues/40
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/312
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace batchExpand = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/batchExpand" at "batchExpand.xqm";
import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "xmldb:exist:///db/apps/BetMasWeb/modules/expand.xqm";

declare option output:method "text";
declare option output:media-type "text/plain";

let $allowed := expand:caller-is-dba-or-editor()
let $col := try { request:get-parameter("collection", ())[1] } catch * { () }
let $mode := try { request:get-parameter("mode", "collection")[1] } catch * { "collection" }
let $opts := batchExpand:enrich-opts(try { request:get-parameter("enrich", ()) } catch * { () })
return if (not($allowed)) then
	error(xs:QName("batchExpand:FORBIDDEN"), "makeExpand requires an authenticated DBA or Editors user")
else if ($mode = "unmirrored") then
	batchExpand:expandUnmirrored($col, $opts)
else
	batchExpand:expandCollection($col, $opts)
