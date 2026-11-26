xquery version "3.1";

(:~
 : Human TEI download: expanded record with optional bibl enrich-on-read.
 : Default enrich=bibl (EthioStudies inject). Pass enrich= (empty) or omit bibl
 : from an allowlist for raw passthrough.
 : Wired from controller /tei/{id}.xml — Debake Task 2b / #312.
 :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "config.xqm";
import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "expand.xqm";
import module namespace batchExpand = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/batchExpand" at "batchExpand.xqm";

declare option output:method "xml";
declare option output:media-type "application/xml";
declare option output:indent "no";

let $id := normalize-space(request:get-parameter("id", ())[1])
let $enrich-raw := try { request:get-parameter("enrich", "bibl") } catch * { "bibl" }
(: Absent enrich param → bibl (human download). Explicit empty allowlist → raw. :)
let $opts := if (empty($enrich-raw)) then
	batchExpand:enrich-opts("bibl")
else if (count($enrich-raw) eq 1 and normalize-space(string($enrich-raw[1])) eq "") then
	batchExpand:enrich-opts("")
else
	batchExpand:enrich-opts($enrich-raw)
let $doc := collection($config:data-root)/id($id)[self::t:TEI][1]
return if (empty($id) or empty($doc)) then (
	response:set-status-code(404), <error>TEI not found for id={ $id }</error>
) else if (map:get($opts, "enrich-bibl") = true()) then
	expand:enrich-bibl-tei($doc)
else
	$doc
