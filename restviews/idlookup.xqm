xquery version "3.1" encoding "UTF-8";

(:~
 : returns entities which share a same keyword
 :
 : @author Pietro Liuzzo
 :)
module namespace lookID = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lookID";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.json.org";

import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";

(:~
 : searches the content of the ids and returns a JSON object containing an array of objects with possible matches. id here can be a full id or any part of it.
 :)
declare function lookID:IDSlookup($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	return (
		log:add-log-message("/api/idlookup?id=" || $id, sm:id()//sm:real/sm:username/string(), "REST"),
		let $query := (
			$exptit:col/t:TEI[contains(@xml:id, $id)],
			$exptit:col//t:msPart[contains(@xml:id, $id)],
			$exptit:col//t:msItem[contains(@xml:id, $id)],
			$exptit:col//t:title[contains(@xml:id, $id)],
			$exptit:col//t:div[contains(@xml:id, $id)]
		)
		let $results :=
			for $hit in $query
			let $i := string($hit/@xml:id)
			(: let $rootID := string(root($hit)/t:TEI/@xml:id) :)(: let $title := if ($i = $rootID) then exptit:printTitleID($i) else api:printSubtitle(root($hit),$i) :)
			return map {"id": $i}

		let $c := count($query)
		return if (count($query) gt 0) then (
			map {"items": $results, "total": $c}
		) else (
			<json:value><json:value json:array="true"><info>No results, sorry</info></json:value></json:value>
		)
	)
};
