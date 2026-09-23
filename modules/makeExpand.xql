xquery version "3.1" encoding "UTF-8";

(:~
 : HTTP / REST entry for parametrized batch expand.
 : GET|POST …/modules/makeExpand.xql?collection=/db/apps/BetMasData/works/1-1000
 : GET|POST …/modules/makeExpand.xql?mode=unmirrored&collection=/db/apps/BetMasData/manuscripts
 :
 : Requires an authenticated non-guest principal who is DBA or in Editors.
 : For xst / util:eval without HTTP, call batchExpand:expandCollection or
 : batchExpand:expandUnmirrored directly (an unbound `external` variable
 : breaks REST ?collection= in eXist).
 :
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 : @see https://github.com/BetaMasaheft/expanded/issues/40
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace batchExpand = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/batchExpand" at "batchExpand.xqm";

declare option output:method "text";
declare option output:media-type "text/plain";

let $user := sm:id()//sm:real/sm:username/string()
let $groups := sm:get-user-groups($user)
let $allowed := sm:is-authenticated() and $user ne "guest" and (sm:is-dba($user) or $groups = "Editors")
let $col := try { request:get-parameter("collection", ())[1] } catch * { () }
let $mode := try { request:get-parameter("mode", "collection")[1] } catch * { "collection" }
return if (not($allowed)) then
	error(xs:QName("batchExpand:FORBIDDEN"), "makeExpand requires an authenticated DBA or Editors user")
else if ($mode = "unmirrored") then
	batchExpand:expandUnmirrored($col)
else
	batchExpand:expandCollection($col)
