xquery version "3.1" encoding "UTF-8";

(:~
 : test implementation of the https://github.com/distributed-text-services
 : CLIENT
 : @author Pietro Liuzzo
 :
 : can take any number of specified DTS endpoints to parse and display them,
 : so, insted of just calling the functions in the DTS module or directly query the db, it sends
 : http requests and follows the structures of the DTS endpoint.
 :)

module namespace dtsc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtsc";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace functx = "http://www.functx.com";
import module namespace localdts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/localdts" at "xmldb:exist:///db/apps/BetMasWeb/modules/localdts.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "xmldb:exist:///db/apps/BetMasWeb/modules/viewItem.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace rutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/rutil" at "xmldb:exist:///db/apps/BetMasWeb/modules/roaster-util.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

(:~
 : HTML text view for a work, preferring in-process localdts for BM resources.
 :
 : Distinguishes:
 : - HTTP entity — DTS API paths on this deployment ($config:baseURI)
 : - Data entity — resource `?id=` values always use canonical $config:BMurl
 :
 : @param $id         BM short id
 : @param $edition    optional edition suffix from the URN
 : @param $ref        optional passage ref
 : @param $start      optional range start
 : @param $end        optional range end
 : @param $collection works|mss|…
 : @return HTML fragment
 :)
declare function dtsc:text($id, $edition, $ref, $start, $end, $collection) {
	(: HTTP entity: this deployment's DTS API :)
	let $APIroot := $config:baseURI || "api/dts/"
	let $NavAPI := "navigation"
	let $ColAPI := "collections"
	let $DocAPI := "document"
	let $AnnoAPI := "annotations"
	(: Data entity: canonical corpus URN baked into the records :)
	let $baseid := "?id=" || $config:BMurl
	let $ps := (
		if ($ref = "") then (
		) else
			"ref=" || $ref,
		if ($start = "") then (
		) else
			"start=" || $start,
		if ($end = "") then (
		) else
			"end=" || $end
	)
	let $parm := if (count($ps) ge 1) then
		"&amp;" || string-join($ps, "&amp;")
	else (
	)
	let $refstart := if ($ref != "") then (
		"." || $ref
	) else if ($start != "") then (
		"." || $start || "-" || $end
	) else (
	)
	let $citationuri := ($config:BMurl || $id || $edition || $refstart)
	let $fullid := $config:BMurl || $id || $edition
	let $fullidpar := $baseid || $id || $edition
	let $uricol := ($APIroot || $ColAPI || $fullidpar)
	let $urinav := ($APIroot || $NavAPI || $fullidpar || $parm)
	let $uridoc := ($APIroot || $DocAPI || $fullidpar || $parm)
	let $urianno := ($APIroot || $AnnoAPI || "/" || $collection || "/items/" || $id)
	let $fullxml := $config:BMurl || $id || ".xml"
	let $DTScol := if (starts-with($fullid, $config:BMurl)) then
		localdts:Collection($fullid, 1, "children")
	else
		dtsc:request($uricol)
	let $DTSnav := if (starts-with($fullid, $config:BMurl)) then
		localdts:Navigation($fullid, $ref, "", $start, $end, "", "", "", "no")
	else
		dtsc:request($urinav)
	let $DTSanno := if (starts-with($fullid, $config:BMurl)) then
		localdts:Annotations($collection, $id, "1", "1", "no")
	else
		dtsc:request($urianno)
	(:~
	 : Local BM resources: DocumentPack returns TEI + Link (data path).
	 : Remote: EXPath http sequence; rutil unwraps body/headers.
	 :)
	let $localDoc := if (starts-with($fullid, $config:BMurl)) then
		localdts:DocumentPack($fullid, $ref, $start, $end)
	else (
	)
	let $remoteDoc := if (starts-with($fullid, $config:BMurl)) then (
	) else
		dtsc:requestXML($uridoc)
	let $DTSdoc := if (exists($localDoc)) then
		$localDoc?body
	else
		rutil:body($remoteDoc)
	let $linkHeader := (
		if (exists($localDoc)) then
			$localDoc?link
		else
			rutil:header($remoteDoc, "Link"),
		""
	)[1]
	let $links :=
		for $link in tokenize($linkHeader, ",")
		return <link>
			<val>{ substring-after(substring-before($link, "&gt;"), "ref=") }</val>
			<dir>{ replace(substring-after($link, "&gt; ; rel="), "'", "") }</dir>
		</link>
	let $selectedFrag := if ($DTSdoc//dts:fragment) then
		$DTSdoc//dts:fragment
	else
		$DTSdoc//t:div[@type = "edition"]

	(: let $test := util:log('info', $selectedFrag/name()) :)(: This checks for the presence of a corresp and print the edition of that if present :)
	let $docnode := if (
		$selectedFrag[self::dts:fragment][t:div/@corresp[starts-with(., "LIT")] and
			not(t:div/t:ab | t:div/t:div[@type = "textpart"])]
	) then
		let $corresp := string($selectedFrag/t:div/@corresp)
		return (: construct a node to be transformed which has the corresp for linking and a label which says it is imported from the linked entity :) <div
			xmlns="http://www.tei-c.org/ns/1.0"
		>
			{
				$selectedFrag/t:div/@corresp,
				$selectedFrag/t:div/@type,
				<label xmlns="http://www.tei-c.org/ns/1.0">Text imported from linked Textual Unit</label>,
				collection("/db/apps/expanded")//id($corresp)//t:div[@type = "edition"]/node()
			}
		</div>
	else
		$selectedFrag
	return <div class="w3-container">
		<div class="w3-row">
			<div class="w3-bar">
				{
					try {
						for $d in $DTScol?("dts:dublincore")?("dc:title")?*?("@value")
						return <div class="w3-bar-item w3-small">{ $d }</div>
					} catch * { util:log("info", $err:description) }
				}
				<button class="w3-bar-item w3-gray w3-small" id="toogleTextBibl">Hide/Show Bibliography</button>
				<button class="w3-bar-item w3-gray w3-small" id="toogleNavIndex">Hide/Show Text Navigation</button>
				{
					try {
						for $index in $DTSanno?member
						return <button class="w3-bar-item w3-gray w3-small
DTSannoCollectionLink">
							{
								(
									attribute data-value { replace($index?("@id"), replace($config:BMurl, "/$", ""), "") },
									substring-before($index?title, " for")
								)
							}
						</button>
					} catch * { <button class="w3-bar-item w3-gray w3-small">No available Indexes</button> }
				}
				<!--<input type='text' placeholder="add the ID of another text (e.g. LIT1349EpistlEusebius)" id="addtextid"/><button id="addtext">Add</button>-->
			</div>
			{
				if ($DTScol?("@type") = "Collection") then (
					<div class="w3-bar w3-border">
						<div class="w3-bar-item">Editions and translations: </div>
						{
							for $ed in $DTScol?member
							return <div class="w3-bar-item"><a href="{ $ed?("@id") }" target="_blank">{ $ed?title }</a></div>
						}
					</div>
				) else (
				)
			}
		</div>
		<div class="w3-col w3-hide " id="indexNav" style="width:15%">
			<div class="w3-bar w3-gray" id="indexnavigation" />
			<div class="w3-bar-block" id="indexitems" />
			<script src="resources/js/dtsAnno.js" type="text/javascript" />
		</div>
		<div class="w3-col" id="refslist" style="width:10%">
			{
				if ($ref != "" or $start != "") then
					<div class="w3-bar-item">
						<div class="w3-bar w3-gray" id="textnavigation">
							<div class="w3-bar-item textNavigation" style="padding: 8px 8px;">
								<a href="/{ $collection }/{ $id }/text?ref={ $links[dir = "prev"]/val/text() }">
									<i class="fa fa-angle-left" />
								</a>
							</div>
							<div class="w3-bar-item textNavigation" style="padding: 8px 8px;">
								<a href="/{ $collection }/{ $id }/text?level={ $DTSnav?("dts:level") }">level</a>
							</div>
							<div class="w3-bar-item  textNavigation" style="padding: 8px 8px;">
								<a href="/{ $collection }/{ $id }/text?ref={ $links[dir = "next"]/val/text() }">
									<i class="fa fa-angle-right" />
								</a>
							</div>
						</div>
					</div>
				else (
				)
			}
			<div class="w3-bar-block w3-border-0">
				<div class="w3-bar-item w3-black w3-small">
					<a href="http://voyant-tools.org/?input={ $config:BMurl }works/{ $id }.xml" target="_blank">Voyant</a>
				</div>
				{
					if ($ref != "" or $start != "") then (
						<div class="w3-bar-item w3-red w3-small">
							<a
								href="/{ $collection }/{ $id }/text"
							>
                                    Full text view
                                </a>
						</div>
					) else (
					)
				}
				{
					for $member in $DTSnav?member?*
					let $r := $member?("dts:ref")
					return <div class="w3-bar-item w3-gray w3-tiny w3-border-0 w3-left">
						<span class="w3-tooltip w3-border-0">
							<a href="/{ $id }{ $edition }.{ $r }">{ $r }</a>
							<a class="page-scroll w3-right" href="#{ $r }">↓</a>
							<span class="w3-text w3-tag" style="word-break:break-all;">
								{ $config:BMurl }
								{ $id }
								{ $edition }.{ $r }
							</span>
						</span>
					</div>
				}
				<button
					class="w3-bar-item w3-black w3-small w3-button"
					onclick="openAccordion('dtsuris')"
				>
                        DTS uris</button>
			</div>
			<ul class="w3-ul w3-border w3-hide" id="dtsuris" style="word-break:break-word;">
				<li><b>Citation URI</b>: { $citationuri }</li>
				<li><b>Collection API</b>: { $uricol }</li>
				<li><b>Navigation API</b>: { $urinav }</li>
				<li><b>Document API</b>: { $uridoc }</li>
			</ul>
		</div>
		<div class="w3-rest">
			{ (: Cache the XML request outside the loop to avoid making the same HTTP request multiple times :)
				let $fullxmlDoc := if (starts-with($fullid, $config:BMurl)) then
					(: For local requests, use the DTSdoc we already have or fetch from collection :)
					if ($DTSdoc instance of element()) then
						$DTSdoc
					else
						(: Fallback: try to get from collection if available :)
						try { collection("/db/apps/expanded")//t:TEI[@xml:id = $id] } catch * { () }
				else
					(: For external requests, cache the HTTP response :)
					dtsc:requestXML($fullxml)[2]
				return (: ranges :) if ($start != "" and $end != "") then (
					let $fullxmlDocClean := $fullxmlDoc/node()[name() != "http:response"]
					let $ab := $fullxmlDocClean//t:ab[1]
					(: calculate start :)
					let $folio := replace($start, "^([0-9]+).*$", "$1")
					let $side := replace($start, "^[0-9]+([rv]).*$", "$1")
					let $side := if ($side = $start) then (
					) else
						$side
					let $cols := replace($start, "^[0-9]+[rv]([ab]).*", "$1")
					let $col := if ($cols castable as xs:integer) then
						$cols
					else (
					)
					let $lines := replace($start, "^[0-9]+[rv][ab]([0-9]+)", "$1")
					let $line := if ($lines castable as xs:integer) then
						$lines
					else (
					)
					let $pb := $ab/t:pb[@n = concat($folio, $side)][1]
					let $cb := if ($col) then
						($pb/following::t:cb[@n = $col])[1]
					else
						$pb
					let $start-node := if ($line) then
						($cb/following::t:lb[@n = $line])[1]
					else if ($col) then
						$cb
					else
						$pb
					(: calculate end :)
					let $folio1 := replace($end, "^([0-9]+).*$", "$1")
					let $side1 := replace($end, "^[0-9]+([rv]).*$", "$1")
					let $side1 := if ($side1 = $end) then (
					) else
						$side1
					let $cols1 := replace($end, "^[0-9]+[rv]([ab]).*", "$1")
					let $col1 := if ($cols1 castable as xs:integer) then
						$cols1
					else (
					)
					let $lines1 := replace($end, "^[0-9]+[rv][ab]([0-9]+)", "$1")
					let $line1 := if ($lines1 castable as xs:integer) then
						$lines1
					else (
					)
					let $pb1 := $ab/t:pb[@n = concat($folio1, $side1)][1]
					let $cb1 := if ($col1) then
						($pb1/following::t:cb[@n = $col1])[1]
					else
						$pb1
					let $end-node := if ($line1) then
						($cb1/following::t:lb[@n = $line1])[last()]
					else if ($col1) then
						$cb1
					else
						$pb1
					return if ($start-node and $end-node) then
						let $slice := ($start-node, $ab//node()[. >> $start-node][. << $end-node], $end-node)
						return viewItem:textfragment(<ab xmlns="http://www.tei-c.org/ns/1.0">{ $slice }</ab>)
					else
						<div>No text found for range { $start }-{ $end }</div>
				) else
					try { viewItem:textfragment($docnode) } catch * { util:log("info", $err:description) }
			}
		</div>)
        </div>
};

(:~
 : Render a remote or local DTS text given an API base URL and resource id.
 :
 : Accepts collection, navigation, or document-style entry points and follows
 : dts:references / dts:passage where present. Divergences between endpoints
 : make this best-effort; prefer opening remote texts in a separate window.
 :
 : @param $base DTS API root (HTTP entity); empty → canonical data host
 : @param $id   collection/document id (data entity; use $config:BMurl for BM)
 : @return HTML viewer fragment
 :)
declare function dtsc:DTStext($base, $id) {
	let $cleanbase := (
		if ($base = "") then
			replace($config:BMurl, "/$", "")
		else if (contains($base, "/api")) then
			substring-before($base, "/api")
		else
			$base
	)
	let $dtsCollection := $cleanbase || dtsc:request($base)?collections || "?id=" || $id
	let $DTScol := dtsc:request($dtsCollection)
	let $context := $DTScol?("@context")
	let $vocab := $context?("@vocab")
	let $dtsprefix := if ($vocab = "https://w3id.org/dts/api#") then (
	) else
		"dts:"
	let $dtsReferences := $cleanbase || $DTScol?($dtsprefix || "references")
	let $DTSnav := dtsc:request(normalize-unicode($dtsReferences))
	let $dtsPassage := $cleanbase || $DTSnav?($dtsprefix || "passage")
	let $cleanDTSpass := replace($dtsPassage, "\{&amp;ref\}\{&amp;start\}\{&amp;end\}", "")
	let $memberprefix := $member?($dtsprefix || "ref")
	let $citetype := $member?($dtsprefix || "citeType")
	let $DTSdoc := dtsc:requestXML($cleanDTSpass)
	let $voyantPassage := substring-after($dtsPassage, "?id=")
	return <div class="w3-container">
		<div class="w3-row">
			<div class="w3-bar">
				{
					try {
						for $d in $DTScol?($dtsprefix || "dublincore")?("dc:title")?*?("@value")
						return <div class="w3-bar-item w3-small">{ $d }</div>
					} catch * { util:log("info", $err:description) }
				}
			</div>
			{
				if ($DTScol?("@type") = "Collection") then (
					<div class="w3-bar w3-border">
						{
							for $ed in $DTScol?member?*
							return <div class="w3-bar-item"><a href="{ $ed?("@id") }" target="_blank">{ $ed?title }</a></div>
						}
					</div>
				) else (
				)
			}
		</div>
		<div class="w3-col" style="width:10%">
			<div class="w3-bar-block">
				<div class="w3-bar-item w3-black w3-small">
					<a href="http://voyant-tools.org/?input={ $voyantPassage }" target="_blank">Voyant</a>
				</div>
				{
					for $member in $DTSnav?member?*
					return try {
						<div class="w3-bar-item w3-gray w3-small">
							<a href="{ $dtsReferences }&amp;ref={ $member?($dtsprefix || "ref") }">
								{ ($member?($dtsprefix || "citeType") || " " || $member?($dtsprefix || "ref")) }
							</a>
						</div>
					} catch * { util:log("info", $err:description) }
				}
				<button
					class="w3-bar-item w3-black w3-small w3-button"
					onclick="openAccordion('dtsuris')"
				>
                        DTS uris</button>
			</div>
			<ul class="w3-ul w3-border w3-hide" id="dtsuris" style="word-break:break-word;">
				<li><b>Collection API</b>: { $dtsCollection }</li>
				<li><b>Navigation API</b>: { $dtsReferences }</li>
				<li><b>Document API</b>: { $dtsPassage }</li>
			</ul>
		</div>
		<div class="w3-rest">
			{
				try { viewItem:textfragment($DTSdoc/node()[name() != "teiHeader"]) } catch * {
					util:log("info", $err:description)
				}
			}
		</div>
	</div>
};

declare function dtsc:request($dtspaths) {
	for $dtspath in $dtspaths
	let $request := <http:request href="{ xs:anyURI($dtspath) }" method="GET" />
	let $file := http:send-request($request)[2]
	let $payload := util:base64-decode($file)
	let $parse-payload := parse-json($payload)
	return $parse-payload
};

declare function dtsc:requestXML($dtspaths) {
	for $dtspath in $dtspaths
	let $request := <http:request href="{ xs:anyURI($dtspath) }" method="GET" />
	return http:send-request($request)
};
