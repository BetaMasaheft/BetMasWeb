xquery version "3.1" encoding "UTF-8";

(:~
 : module for the different item views, decides what kind of item it is, in which way to display it
 :
 : @author Pietro Liuzzo
 :)

module namespace PermRestItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/PermRestItem";

(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "xmldb:exist:///db/apps/BetMasWeb/modules/item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "xmldb:exist:///db/apps/BetMasWeb/modules/charts.xqm";
import module namespace LitFlow = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/LitFlow" at "xmldb:exist:///db/apps/BetMasWeb/modules/LitFlow.xqm";
import module namespace dtsc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtsc" at "xmldb:exist:///db/apps/BetMasWeb/modules/dtsclient.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "xmldb:exist:///db/apps/BetMasWeb/modules/viewItem.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";

declare variable $PermRestItem:deleted := doc("/db/apps/lists/deleted.xml");

(:~
 : templates:apply lookup function for this module, referenced by name
 : (PermRestItem:lookup#2) at each templates:apply call site here instead
 : of each writing its own copy - see config:template-lookup-resolve for
 : why the function-lookup() probe still has to be written locally per
 : module rather than shared in config.xqm too.
 :)
declare function PermRestItem:lookup($functionName as xs:string, $arity as xs:integer) as function(*)? {
	config:template-lookup-resolve(
		"permanentItems.xqm",
		$functionName,
		$arity,
		try { function-lookup(xs:QName($functionName), $arity) } catch * { () }
	)
};

declare function PermRestItem:capitalize-first($arg as xs:string?) as xs:string? {
	concat(upper-case(substring($arg, 1, 1)), substring($arg, 2))
};

(: parameter hi is used to highlight searched word when coming query from Dillmann
parameters start and perpage are for the text visualization with pagination as per standard usage :)
declare function PermRestItem:getItem($request as map(*)) {
	let $sha as xs:string* := $request?parameters?sha
	let $id as xs:string* := $request?parameters?id
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $hi as xs:string* := $request?parameters?hi
	let $item := item2:getTEIbyID($id)
	let $col := switch2:col($item/@type)
	let $log := log:add-log-message("/" || $id || "/main", sm:id()//sm:real/sm:username/string(), "item")
	return PermRestItem:ITEM("main", $id, $col, $start, $per-page, $hi, $sha)
};

declare function PermRestItem:getItemC($request as map(*)) {
	let $sha as xs:string* := $request?parameters?sha
	let $collection as xs:string* := $request?parameters?collection
	let $id as xs:string* := $request?parameters?id
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $hi as xs:string* := $request?parameters?hi
	let $log := log:add-log-message(
		"/" || $collection || "/" || $id || "/main",
		sm:id()//sm:real/sm:username/string(),
		"item"
	)
	return PermRestItem:ITEM("main", $id, $collection, $start, $per-page, $hi, $sha)
};

declare function PermRestItem:getgeoBrowser($request as map(*)) {
	let $sha as xs:string* := $request?parameters?sha
	let $collection as xs:string* := $request?parameters?collection
	let $id as xs:string* := $request?parameters?id
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $hi as xs:string* := $request?parameters?hi
	let $log := log:add-log-message(
		"/" || $collection || "/" || $id || "/geoBrowser",
		sm:id()//sm:real/sm:username/string(),
		"item"
	)
	return PermRestItem:ITEM("geobrowser", $id, $collection, $start, $per-page, $hi, $sha)
};

declare function PermRestItem:gettext($request as map(*)) {
	let $sha as xs:string* := $request?parameters?sha
	let $collection as xs:string* := $request?parameters?collection
	let $id as xs:string* := $request?parameters?id
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $hi as xs:string* := $request?parameters?hi
	let $log := log:add-log-message(
		"/" || $collection || "/" || $id || "/text",
		sm:id()//sm:real/sm:username/string(),
		"item"
	)
	return PermRestItem:ITEM("text", $id, $collection, $start, $per-page, $hi, $sha)
};

declare function PermRestItem:getanalytic($request as map(*)) {
	let $sha as xs:string* := $request?parameters?sha
	let $collection as xs:string* := $request?parameters?collection
	let $id as xs:string* := $request?parameters?id
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $hi as xs:string* := $request?parameters?hi
	let $log := log:add-log-message(
		"/" || $collection || "/" || $id || "/analytic",
		sm:id()//sm:real/sm:username/string(),
		"item"
	)
	return PermRestItem:ITEM("analytic", $id, $collection, $start, $per-page, $hi, $sha)
};

declare function PermRestItem:getgraph($request as map(*)) {
	let $sha as xs:string* := $request?parameters?sha
	let $collection as xs:string* := $request?parameters?collection
	let $id as xs:string* := $request?parameters?id
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $hi as xs:string* := $request?parameters?hi
	return PermRestItem:ITEM("graph", $id, $collection, $start, $per-page, $hi, $sha)
};

declare function PermRestItem:getcorpus($request as map(*)) {
	let $sha as xs:string* := $request?parameters?sha
	let $id as xs:string* := $request?parameters?id
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $hi as xs:string* := $request?parameters?hi
	let $log := log:add-log-message("/corpus/" || $id, sm:id()//sm:real/sm:username/string(), "item")
	return PermRestItem:ITEM("corpus", $id, "corpora", $start, $per-page, $hi, $sha)
};

declare function PermRestItem:ITEM(
	$type,
	$id,
	$collection,
	$start as xs:integer*,
	$per-page as xs:integer*,
	$hi as xs:string*,
	$sha as xs:string*
) {
	let $collect := switch2:collectionVar($collection)
	let $coll := $config:data-root || "/" || $collection
	let $capCol := PermRestItem:capitalize-first($collection)
	let $permapath := if ($PermRestItem:deleted//t:item[. eq $id]) then (
		replace(string($PermRestItem:deleted//t:item[. eq $id]/@source), $collection, "") => replace("^/", "") ||
			"/" ||
			$PermRestItem:deleted//t:item[. eq $id]/text() ||
			".xml"
	) else
		replace(
			PermRestItem:capitalize-first(substring-after(base-uri(item2:getTEIbyID($id)), $config:data-root || "/")),
			$capCol,
			""
		)
	let $docpath := "https://raw.githubusercontent.com/BetaMasaheft/" || $capCol || "/" || $sha || "/" || $permapath
	(: THIS WILL HAVE TO EXPAND FIRST! without storing, otherwise all functions will not work. :)
	let $this := doc($docpath)//t:TEI
	let $id := $this/@xml:id
	let $title := exptit:printTitle($id)
	let $biblio := <bibl>
		{
			for $author in config:distinct-values(($this//t:revisionDesc/t:change/@who | $this//t:editor/@key))
			return <author>{ editors:editorKey(string($author)) }</author>
		}
		{
			let $time := max($this//t:revisionDesc/t:change/xs:date(@when))
			return <date type="lastModified">{ format-date($time, "[D].[M].[Y]") }</date>
		}
		<idno type="url">{ ($config:appUrl || "/permanent/" || $sha || "/" || $id) }</idno>
		<coll>{ $collection }</coll>
	</bibl>
	let $Cmap := map {"type": "collection", "name": $collection, "path": $coll}
	let $Imap := map {"type": "item", "name": $id, "path": $collection}
	return (
		<html xmlns="http://www.w3.org/1999/xhtml" version="XHTML+RDFa 1.1">
			<head>
				{ scriptlinks:app-title($title) }
				<link
					href="https://betamasaheft.eu/rdf/{ $collection }/{ $id }.rdf"
					rel="alternate"
					title="RDF Representation"
					type="application/rdf+xml" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				{ scriptlinks:app-meta($this) }
				{ scriptlinks:scriptStyle() }
				{
					if ($type = "text") then (
					) else
						scriptlinks:ItemScriptStyle()
				}
				{
					if ($type = "graph") then (
						<script src="https://d3js.org/d3.v5.min.js" />, <script src="resources/js/d3sparql.js" />
					) else (
					)
				}
				{
					if ($type = "text") then (
						(: mirador  manuscripts viewer under the text view for editions :)
						<style type="text/css">
							{
								"
                #viewer {{
                display: block;
                width: 100%;
                height: 600px;
                margin: 1em 5%;
                position: relative;
                }}"
							}
						</style>,
						<link href="resources/mirador/css/mirador-combined.css" rel="stylesheet" type="text/css" />,
						<script src="resources/mirador/mirador.js" />
					) else (
					)
				}
			</head>
			<body id="body">
				{ nav:barNew() }
				{ nav:modalsNew() }
				<div class="w3-container w3-padding-48" id="content">
					{
						(:
						 : RestViewOptions routed through templates:apply instead of
						 : called directly - see item2:RestViewOptionsTemplate.
						 :)
						templates:apply(
							<div data-template="item2:RestViewOptionsTemplate" />,
							PermRestItem:lookup#2,
							map {"this": $this, "collection": $collection},
							config:template-apply-config()
						)
					}
					{
						if ($PermRestItem:deleted//t:item[. eq $id]) then
							<div class='w3-red w3-container'>
								{ $PermRestItem:deleted//t:item[. eq $id]/text() } was deleted permanently on {
									string($PermRestItem:deleted//t:item[. eq $id]/@change)
								}
							</div>
						else (
						)
					}
					{
						(:
						 : RestItemHeader routed through templates:apply instead of
						 : called directly - see item2:RestItemHeaderTemplate.
						 :)
						templates:apply(
							<div data-template="item2:RestItemHeaderTemplate" />,
							PermRestItem:lookup#2,
							map {"this": $this, "collection": $collection},
							config:template-apply-config()
						)
					}
					{
						if ($type = "corpus") then (
						) else
							item2:RestNav($this, $collection, $type)
					}
					<div class="w3-main alpheios-enabled" id="main">
						{
							if ($type = "corpus") then (
							) else
								attribute style { "margin-left:10%" }
						}
						{
							(:
							 : mainContent routed through templates:apply instead of
							 : called directly - see PermRestItem:mainContentTemplate.
							 :)
							templates:apply(
								<div data-template="PermRestItem:mainContentTemplate" />,
								PermRestItem:lookup#2,
								map {"type": $type, "this": $this, "id": $id, "collection": $collection},
								config:template-apply-config()
							)
						}
						<div class="w3-container w3-margin-bottom">
							<div class="w3-container w3-padding w3-black w3-card-4 ">This page contains RDFa. 
   <a
									href="/rdf/{ $collection }/{ $id }.rdf"
								>RDF+XML</a> graph of this resource. Alternate representations available via <a
									href="/api/void/{ $id }"
								>VoID</a>.</div>
							<div
								class="w3-container w3-padding w3-card-4 "
								data-id="{ $id }"
								data-path="{ $permapath }"
								data-type="{ PermRestItem:capitalize-first($collection) }"
								id="permanentIDs"
								style="max-heigh:400px;overflow:auto"
							>YOU ARE LOOKING AT VERSION
   { $sha }. <a
									class="w3-btn w3-gray"
									id="LoadPermanentIDs"
								>See all permalinks.</a>
							</div>
							<script src="resources/js/permanentID.js" type="text/javascript" />
						</div>
						{ item2:authorsSHA($id, $this, $collection, $sha) }
					</div>
				</div>
				{ nav:footerNew() }
				{ scriptlinks:ItemFooterScript() }
			</body>
		</html>
	)
};

(:~
 : Split out of PermRestItem:ITEM's inline switch($type) - same shape and
 : motivation as restItem:mainContent's split of the sibling switch in
 : restviews/items.xqm: maintainability and testability for a large
 : inline switch, not an html-templating conversion.
 :
 : This is a genuinely separate, already-diverged copy of that switch
 : (different corpus-doc lookup, an uncommented BetMasRel block in
 : "analytic", inlined contained-works logic in "text", an
 : "institutions" case in the extras switch that restItem:mainContent's
 : version doesn't have) - each function below preserves its own file's
 : exact original content, not restItem:mainContent's.
 :)
declare function PermRestItem:mainContentCorpus($id as xs:string*) {
	<div class="w3-container">
		<label class="switch diplomaticHighlight">
			<input class="w3-check" type="checkbox" />
			<div class="slider round" data-toggle="tooltip" title="Highlight diplomatic disourse interpretation" />
		</label>
		{
			for $document in item2:rels($id)
			let $rootid := string($document/@active)
			let $itemid := substring-after($rootid, "#")
			let $msid := substring-before($rootid, "#")
			return <div class="w3-row documentcorpus w3-panel w3-leftbar">
				{
					let $doc := doc(base-uri($document))//id($itemid)
					return (
						<div class="w3-col" style="width:15%">
							<a href="{ $msid }">{ exptit:printTitle($msid) }</a>
							<br />
							<a href="/{ $rootid }">
								{
									if ($doc/t:title) then
										string:additionstitles($doc/t:title/node())
									else if ($doc/t:desc/@type) then
										string($doc/t:desc/@type)
									else
										$itemid
								}
							</a>
    ({ string:additionstitles($doc/t:locus) })

     </div>,
						<div class="w3-rest">{ viewItem:documents($doc) }</div>
					)
				}
			</div>
		}
	</div>
};

(:~
 : templates:apply adapter for PermRestItem:mainContentCorpus - reads
 : the same $id PermRestItem:mainContent used to pass directly, out of
 : $model. No %templates:wrap: mainContentCorpus already returns
 : complete, specific content, so the calling marker element is meant
 : to be replaced outright, not wrapped - same shape as
 : PermRestItem:mainContentTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with id
 : @return PermRestItem:mainContentCorpus's own output for the given $model
 :)
declare function PermRestItem:mainContentCorpusTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentCorpus($model("id"))
};

declare function PermRestItem:mainContentAnalytic($this as element(), $id as xs:string*, $collection as xs:string*) {
	<div class="w3-container">
		<img id="loading" src="resources/Loading.gif" style="display: none;" />
		<div class="w3-container">
			<div class="w3-half w3-padding" id="BetMasRel" style="display: none;">
				<div class="input-group container">
					<button class="w3-button w3-gray" id="clusterOutliers">Cluster outliers</button>
					<button class="w3-button w3-gray" id="clusterByHubsize">Cluster by hubsize</button>
				</div>
				<div class="w3-container" data-value="{ $id }" id="BetMasRelView" />
				<script src="resources/js/visgraphspec.js" type="text/javascript" />
			</div>
			<div class="container w3-half w3-padding">{ item2:EntityRelsTable($this, $collection) }</div>
		</div>
		<div class="w3-container">
			<div class="w3-half w3-padding">
				<div class="w3-container" id="timeLine" />
				<script type="text/javascript">{ item2:timeline($this, $collection) }</script>
			</div>
			<div class="w3-half w3-padding">{ item2:RestPersRole($this, $collection) }</div>
		</div>
	</div>
};

(:~
 : templates:apply adapter for PermRestItem:mainContentAnalytic - reads
 : the same $this/$id/$collection PermRestItem:mainContent used to pass
 : directly, out of $model. No %templates:wrap: mainContentAnalytic
 : already returns complete, specific content, so the calling marker
 : element is meant to be replaced outright, not wrapped - same shape
 : as PermRestItem:mainContentTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with this/id/collection
 : @return PermRestItem:mainContentAnalytic's own output for the given $model
 :)
declare function PermRestItem:mainContentAnalyticTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentAnalytic($model("this"), $model("id"), $model("collection"))
};

declare function PermRestItem:mainContentText($this as element(), $id as xs:string*, $collection as xs:string*) {
	(
		<div class="w3-container">
			<div class="w3-twothird" id="dtstext">
				{
					if ($this//t:div[@type eq "edition"]) then
						dtsc:text($id, $this//t:div[@type eq "edition"], "", "", "", $collection)
					else
						<p>No text available here.</p>
				}
			</div>
			<!--<div class="w3-third w3-gray w3-padding">{item2:textBibl($this, $id)}</div>-->
		</div>,
		for $contains in $this//t:relation[@name eq "saws:contains"]/@passive
		let $ids := if (contains($contains, " ")) then
			for $x in tokenize($contains, " ")
			return $x
		else
			string($contains)
		for $contained in $ids
		let $cfile := item2:getTEIbyID($contained)
		return <div class="w3-container">
			{
				<div class="w3-twothird" id="dtstext">Contains  { item2:title($contained) }
					{
						if ($cfile//t:div[@type eq "edition"]) then
							dtsc:text($contained, "", "", "", "", "works")
						else (
						)
					}
				</div>,
				<!--<div class="w3-third w3-gray w3-padding">{item2:textBibl($this, $id)}</div>-->
			}
		</div>
	)
};

(:~
 : templates:apply adapter for PermRestItem:mainContentText - reads the
 : same $this/$id/$collection PermRestItem:mainContent used to pass
 : directly, out of $model. No %templates:wrap: mainContentText already
 : returns complete, specific content, so the calling marker element is
 : meant to be replaced outright, not wrapped - same shape as
 : PermRestItem:mainContentTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with this/id/collection
 : @return PermRestItem:mainContentText's own output for the given $model
 :)
declare function PermRestItem:mainContentTextTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentText($model("this"), $model("id"), $model("collection"))
};

declare function PermRestItem:mainContentGraph($this as element(), $id as xs:string*, $collection as xs:string*) {
	item2:mainContentGraph($this, $id, $collection, PermRestItem:lookup#2)
};

(:~
 : templates:apply adapter for PermRestItem:mainContentGraph - reads
 : the same $this/$id/$collection PermRestItem:mainContent used to
 : pass directly, out of $model. No %templates:wrap: mainContentGraph
 : already returns complete, specific content, so the calling marker
 : element is meant to be replaced outright, not wrapped - same shape
 : as PermRestItem:mainContentTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with this/id/collection
 : @return PermRestItem:mainContentGraph's own output for the given $model
 :)
declare function PermRestItem:mainContentGraphTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentGraph($model("this"), $model("id"), $model("collection"))
};

(:~
 : templates:apply adapter for PermRestItem:mainContentExtrasPersons -
 : reads the same $id PermRestItem:mainContentExtras used to pass
 : directly, out of $model. No %templates:wrap:
 : mainContentExtrasPersons already returns complete, specific content,
 : so the calling marker element is meant to be replaced outright, not
 : wrapped - same shape as PermRestItem:mainContentTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with id
 : @return PermRestItem:mainContentExtrasPersons's own output for the given $model
 :)
declare function PermRestItem:mainContentExtrasPersonsTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentExtrasPersons($model("id"))
};

declare function PermRestItem:mainContentExtrasPersons($id as xs:string*) {
	(item2:RestTabot($id), item2:RestAdditions($id), item2:RestMiniatures($id))
};

(:~
 : templates:apply adapter for PermRestItem:mainContentExtrasAuthorityFiles
 : - same shape/rationale as PermRestItem:mainContentExtrasPersonsTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with id
 : @return PermRestItem:mainContentExtrasAuthorityFiles's own output for the given $model
 :)
declare function PermRestItem:mainContentExtrasAuthorityFilesTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentExtrasAuthorityFiles($model("id"))
};

declare function PermRestItem:mainContentExtrasAuthorityFiles($id as xs:string*) {
	<div class="w3-container">
		<h4>Art Objects associated with this Art Theme in miniatures and other manuscript decorations</h4>
		<div class="w3-panel w3-red">{ item2:RestMiniaturesKeys($id) }</div>
		<div class="w3-panel w3-red">{ item2:RestMiniatures($id) }</div>
	</div>
};

(:~
 : templates:apply adapter for PermRestItem:mainContentExtrasInstitutions
 : - same shape/rationale as PermRestItem:mainContentExtrasPersonsTemplate.
 : No restItem equivalent - the "institutions" $collection branch is
 : PermRestItem-only, restItem:mainContentExtras has no matching case.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with id
 : @return PermRestItem:mainContentExtrasInstitutions's own output for the given $model
 :)
declare function PermRestItem:mainContentExtrasInstitutionsTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentExtrasInstitutions($model("id"))
};

declare function PermRestItem:mainContentExtrasInstitutions($id as xs:string*) {
	(
		<div class="w3-container">
			<iframe
				allowfullscreen="true"
				height="400"
				src="https://peripleo.pelagios.org/embed/{ encode-for-uri(concat("http://betamasaheft.eu/places/", $id)) }"
				style="border:none;"
				width="100%" />
		</div>,
		<div id="entitymap" style="width: 100%; height: 400px" />,
		<script>{ 'var placeid = "' || $id || '"' }</script>,
		<script src="resources/geo/geojsonentitymap.js" type="text/javascript" />
	)
};

declare function PermRestItem:mainContentExtras($id as xs:string*, $collection as xs:string*) {
	(:
	 : Each non-empty branch routed through templates:apply instead of
	 : called directly - see item2:mainContentExtrasWorksTemplate/
	 : PermRestItem:mainContentExtrasPersonsTemplate/
	 : mainContentExtrasAuthorityFilesTemplate/mainContentExtrasInstitutionsTemplate.
	 :)
	switch ($collection)
		case "works" return
			templates:apply(
				<div data-template="item2:mainContentExtrasWorksTemplate" />,
				PermRestItem:lookup#2,
				map {"id": $id},
				config:template-apply-config()
			)
		case "persons" return
			templates:apply(
				<div data-template="PermRestItem:mainContentExtrasPersonsTemplate" />,
				PermRestItem:lookup#2,
				map {"id": $id},
				config:template-apply-config()
			)
		case "authority-files" return
			templates:apply(
				<div data-template="PermRestItem:mainContentExtrasAuthorityFilesTemplate" />,
				PermRestItem:lookup#2,
				map {"id": $id},
				config:template-apply-config()
			)
		case "institutions" return
			templates:apply(
				<div data-template="PermRestItem:mainContentExtrasInstitutionsTemplate" />,
				PermRestItem:lookup#2,
				map {"id": $id},
				config:template-apply-config()
			)
		default return
			()
};

declare function PermRestItem:mainContentDefault($this as element(), $id as xs:string*, $collection as xs:string*) {
	(
		if ($collection = "places") then (
			<div class="w3-container">
				<div class="w3-half w3-padding"><div id="entitymap" style="height: 400px" /></div>
				<div class="w3-half w3-padding">
					<iframe
						allowfullscreen="true"
						height="400"
						src="https://peripleo.pelagios.org/embed/{ encode-for-uri(concat("http://betamasaheft.eu/places/", $id)) }"
						style="border:none;"
						width="100%" />
				</div>
			</div>,
			<script>{ 'var placeid = "' || $id || '"' }</script>,
			<script src="resources/geo/geojsonentitymap.js" type="text/javascript" />
		) else (
		),
		<div class="alpheios-enabled">{ item2:RestItem($this, $collection) }</div>,
		(: item2:namedentitiescorresps($this, $collection), :)
		(: the form with a list of potental relation keywords to find related items. value is used by Jquery to query rest again on api:SharedKeyword($keyword) :)
		PermRestItem:mainContentExtras($id, $collection)
	)
};

(:~
 : templates:apply adapter for PermRestItem:mainContentDefault - reads
 : the same $this/$id/$collection PermRestItem:mainContent used to
 : pass directly, out of $model. No %templates:wrap: mainContentDefault
 : already returns complete, specific content, so the calling marker
 : element is meant to be replaced outright, not wrapped - same shape
 : as PermRestItem:mainContentTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with this/id/collection
 : @return PermRestItem:mainContentDefault's own output for the given $model
 :)
declare function PermRestItem:mainContentDefaultTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContentDefault($model("this"), $model("id"), $model("collection"))
};

declare function PermRestItem:mainContent(
	$type as xs:string*,
	$this as element(),
	$id as xs:string*,
	$collection as xs:string*
) {
	(:
	 : Each branch routed through templates:apply instead of called
	 : directly - see PermRestItem:mainContentCorpusTemplate/
	 : item2:mainContentGeobrowserTemplate/mainContentAnalyticTemplate/
	 : mainContentTextTemplate/mainContentGraphTemplate/
	 : mainContentDefaultTemplate.
	 :)
	switch ($type)
		case "corpus" return
			templates:apply(
				<div data-template="PermRestItem:mainContentCorpusTemplate" />,
				PermRestItem:lookup#2,
				map {"id": $id},
				config:template-apply-config()
			)
		case "geobrowser" return
			templates:apply(
				<div data-template="item2:mainContentGeobrowserTemplate" />,
				PermRestItem:lookup#2,
				map {"id": $id},
				config:template-apply-config()
			)
		case "analytic" return
			templates:apply(
				<div data-template="PermRestItem:mainContentAnalyticTemplate" />,
				PermRestItem:lookup#2,
				map {"this": $this, "id": $id, "collection": $collection},
				config:template-apply-config()
			)
		case "text" return
			templates:apply(
				<div data-template="PermRestItem:mainContentTextTemplate" />,
				PermRestItem:lookup#2,
				map {"this": $this, "id": $id, "collection": $collection},
				config:template-apply-config()
			)
		case "graph" return
			templates:apply(
				<div data-template="PermRestItem:mainContentGraphTemplate" />,
				PermRestItem:lookup#2,
				map {"this": $this, "id": $id, "collection": $collection},
				config:template-apply-config()
			)
		default return
			(: THE MAIN VIEW :)
			templates:apply(
				<div data-template="PermRestItem:mainContentDefaultTemplate" />,
				PermRestItem:lookup#2,
				map {"this": $this, "id": $id, "collection": $collection},
				config:template-apply-config()
			)
};

(:~
 : templates:apply adapter for PermRestItem:mainContent - reads the same
 : parameters PermRestItem:ITEM used to pass directly, out of $model. No
 : %templates:wrap: mainContent already returns complete, specific
 : content, so the calling marker element is meant to be replaced
 : outright, not wrapped - same shape as restItem:mainContentTemplate.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model map with type/this/id/collection
 : @return PermRestItem:mainContent's own output for the given $model
 :)
declare function PermRestItem:mainContentTemplate($node as node(), $model as map(*)) {
	PermRestItem:mainContent($model("type"), $model("this"), $model("id"), $model("collection"))
};
