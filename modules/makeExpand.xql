xquery version "3.1" encoding "UTF-8";

(:~
 : HTTP / REST entry for parametrized batch expand.
 : GET|POST …/modules/makeExpand.xql?collection=/db/apps/BetMasData/works/1-1000
 :
 : For xst / util:eval without HTTP, call batchExpand:expandCollection directly
 : (an unbound `external` variable breaks REST ?collection= in eXist).
 :
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace batchExpand = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/batchExpand" at "batchExpand.xqm";

declare option output:method "text";
declare option output:media-type "text/plain";

let $col := try { request:get-parameter("collection", ())[1] } catch * { () }
return batchExpand:expandCollection($col)
