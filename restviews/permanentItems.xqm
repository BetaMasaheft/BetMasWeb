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
			PermRestItem:capitalize-first(substring-after(base-uri(item2:getTEIbyID($id)), "/db/apps/BetMasData/")),
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
					{ item2:RestViewOptions($this, $collection) }
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
					{ item2:RestItemHeader($this, $collection) }
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
							switch ($type)
								case "corpus" return
									(
										<div class="w3-container">
											<label class="switch diplomaticHighlight">
												<input class="w3-check" type="checkbox" />
												<div
													class="slider round"
													data-toggle="tooltip"
													title="Highlight diplomatic disourse interpretation" />
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
									)
								case "geobrowser" return
									(
										<div class="w3-container">
											<div class="w3-container alert alert-info">You can download the <a
													href="https://betamasaheft.eu/api/KML/places/{ $id }"
												>KML</a> file visualized below in the <a
													href="https://geobrowser.de.dariah.eu"
												>Dariah-DE Geobrowser</a>.</div>
											<h3>Map and timeline of places attestations marked up in the text.</h3>
											<iframe
												id="geobrowserMap"
												src="https://geobrowser.de.dariah.eu/embed/index.html?kml1=https://betamasaheft.eu/api/KML/places/{
													$id
												}"
												style="width: 100%; height: 800px;" />
										</div>
									)
								case "analytic" return
									(
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
									)
								case "text" return
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
								case "graph" return
									(
										switch ($collection)
											case "manuscripts" return
												let $ex := $this//t:msDesc/t:physDesc//t:extent/t:measure[@unit eq "leaf"][not(
													@type eq "blank"
												)]/text()
												return <div class="w3-container">
													<button class="w3-button w3-red" disabled="disabled" id="enrichTable">Enrich Table</button>
													<div
														class="alert alert-info"
														id="graphloadingstatus"
													>Loading graph and synoptique table...</div>
													<div class="w3-container">
														<div class="w3-responsive">
															<table
																class="w3-table w3-bordered w3-hoverable w3-condensed"
																data-extent="{ $ex }"
																data-id="{ $id }"
																id="SdCTable"
															>
																{
																	if ($this//t:msDesc/t:msIdentifier/t:idno[@facs]) then (
																		attribute data-images { string($this//t:msDesc/t:msIdentifier/t:idno/@facs) },
																		attribute data-imagesSource { $this//t:msDesc/t:msIdentifier/t:collection/text() }
																	) else (
																	)
																}
																<thead>
																	<tr>
																		<th>Quires</th>
																		<th>folios</th>
																		<th>UniMat</th>
																		<th>UniMarq</th>
																		<th>UniCah</th>
																		<th>UniCont</th>
																		<th>addition</th>
																		<th>UniMain</th>
																		<th>UniEcri</th>
																		<th>UniRegl</th>
																		<th>UniMep</th>
																		<th>decoration</th>
																		<th>UniProd</th>
																	</tr>
																</thead>
																<tbody />
															</table>
															<script src="resources/js/SdCtable.js" type="text/javascript" />
														</div>
													</div>
													<div data-id="{ $id }" id="graph" />
													<div class="w3-container">
														<div class="w3-container">
															<div class="w3-panel w3-red">
																<p
																	class="w3-panel w3-red"
																>
      Sankey diagram of the manuscript. Showing UniProd
      and UniCirc explicitly related. Transformations are given weight 1.
      UniProd and UniCirc declarations are given weight 2. Exact matches are given weight 3.
    There is no chronological implication.</p>
															</div>
															{ charts:mssSankey($id) }
														</div>
														<div class="w3-container">
															<div class="w3-panel w3-red">
																<p
																>
      Graph of the manuscript transformations using the Syntaxe du Codex ontology.</p>
															</div>
															<div class="w3-container" id="SdCGraph" />
														</div>
													</div>
													<!--  <div class="w3-container">
     <div id="GraphResult"/>
 </div> -->
													<script src="resources/js/d3sparqlsettingsManuscripts.js" type="text/javascript" />
												</div>
											case "places" return
												<div class="w3-container">{ charts:pieAttestations($id, "placeName") }</div>
											case "persons" return
												<div class="w3-container">
													<div data-id="{ $id }" id="graph" />
													<div class="w3-container" id="SNAPGraph" />
													<p>Graph view of the SNAP relations between persons.</p>
													<div class="w3-container" id="AttestationsInWorks" />
													<p>Annotated attestations in texts (works and manuscripts).</p>
													<script src="resources/js/SNAPGraph.js" type="text/javascript" />
													<div class="w3-container">{ charts:pieAttestations($id, "persName") }</div>
												</div>
											case "authority-files" return
												let $Subjects := doc(concat($config:data-rootA, "/taxonomy.xml"))//t:category[t:desc eq
													"Subjects"]//t:category/t:catDesc/text()
												return if ($id = $Subjects) then (
													try { LitFlow:Sankey($id, "works") } catch * { $err:description },
													try { LitFlow:Sankey($id, "mss") } catch * { $err:description }
												) else (
												)
											default return
												<div class="w3-container">
													<div data-id="{ $id }" data-rdf="/api/RDFJSON/{ $collection }/{ $id }" id="graph" />
													<div id="mouseovervalue"><p class="w3-large MainTitle" /></div>
													<div class="w3-container" id="GraphResultNotMS" />
													<script src="resources/js/colorbrewer.js" />
													<script src="resources/js/d3sparqlsettingsITEM.js" type="text/javascript" />
												</div>
									)
								default return
									(: THE MAIN VIEW :)
									(
										if ($collection = "places") then (
											<div class="w3-container">
												<div class="w3-half w3-padding"><div id="entitymap" style="height: 400px" /></div>
												<div class="w3-half w3-padding">
													<iframe
														allowfullscreen="true"
														height="400"
														src="https://peripleo.pelagios.org/embed/{
															encode-for-uri(concat("http://betamasaheft.eu/places/", $id))
														}"
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
										switch ($collection)
											case "works" return
												(item2:RestMiniatures($id))
											case "persons" return
												(item2:RestTabot($id), item2:RestAdditions($id), item2:RestMiniatures($id))
											case "authority-files" return
												<div class="w3-container">
													<h4
													>Art Objects associated with this Art Theme in miniatures and other manuscript decorations</h4>
													<div class="w3-panel w3-red">{ item2:RestMiniaturesKeys($id) }</div>
													<div class="w3-panel w3-red">{ item2:RestMiniatures($id) }</div>
												</div>
											case "institutions" return
												(
													<div class="w3-container">
														<iframe
															allowfullscreen="true"
															height="400"
															src="https://peripleo.pelagios.org/embed/{
																encode-for-uri(concat("http://betamasaheft.eu/places/", $id))
															}"
															style="border:none;"
															width="100%" />
													</div>,
													<div id="entitymap" style="width: 100%; height: 400px" />,
													<script>{ 'var placeid = "' || $id || '"' }</script>,
													<script src="resources/geo/geojsonentitymap.js" type="text/javascript" />
												)
											default return
												()
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
