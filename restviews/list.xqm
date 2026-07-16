xquery version "3.1" encoding "UTF-8";

(:~
 : module for the different list views, decides what kind of list it is, in which way to display it and calls the correct functions
 :
 : @author Pietro Liuzzo
 :)
module namespace list = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/list";

(: For interacting with the TEI document :)
declare namespace b = "betmas.biblio";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace apptable = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apptable" at "xmldb:exist:///db/apps/BetMasWeb/modules/apptable.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "xmldb:exist:///db/apps/BetMasWeb/modules/item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "xmldb:exist:///db/apps/BetMasWeb/modules/charts.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

declare variable $list:instit := doc("/db/apps/lists/institutions.xml");

declare variable $list:taxonomy := doc("/db/apps/lists/canonicaltaxonomy.xml");

declare variable $list:catalogues := doc("/db/apps/lists/catalogues.xml")//t:list;

declare variable $list:bibliography := doc("/db/apps/lists/bibliography.xml");

declare variable $list:app-meta := (
	<meta
		xmlns="http://www.w3.org/1999/xhtml"
		content="{ $config:repo-descriptor/repo:description/text() }"
		name="description" />,
	for $genauthor in $config:repo-descriptor/repo:author
	return <meta xmlns="http://www.w3.org/1999/xhtml" content="{ $genauthor/text() }" name="creator" />
);

declare function list:browseMS($request as map(*)) {
	(
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
				<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				{ scriptlinks:scriptStyle() }
			</head>
			<body id="body">
				{ nav:barNew() }
				{ nav:modalsNew() }
				<div class="w3-main w3-margin w3-padding-64">
					<div
						class="w3-panel w3-card-4 w3-padding w3-margin"
					>Here you can browse all shelfmarks available institution by institution and collection by collection. <span
							class="w3-hide-small"
						>The letters on the right may speed up scrolling down the list.</span>
					</div>
					<div class="w3-container">
						{
							let $mss := $apprest:collection-rootMS[descendant::t:repository[@ref]]
							return (
								<div class="w3-row w3-hide-small" style="right: 0px;width: 300px;width:30%;position: fixed;">
									<div class="w3-bar">
										<a class="w3-bar-item page-scroll" href="#group-A">top</a>
										{
											let $letter :=
												for $repoi at $p in $list:instit//t:item
												return upper-case(substring(replace($repoi/string(), "\s", ""), 1, 1))
											for $l in distinct-values($letter)
											order by $l
											return <a class="w3-bar-item page-scroll" href="#group-{ $l }">{ $l }</a>
										}
									</div>
								</div>,
								<div style="left:300px">
									{
										let $reposByRepoId := map:merge(
											for $ref in $mss//t:repository[@ref]
											group by $r := $ref/@ref
											return map:entry($r, $ref)
										)
										return for $repoi at $p in $list:instit//t:item
											let $firstletter := upper-case(substring($repoi/string(), 1, 1))
											group by $First := $firstletter
											order by $First
											return if ($First = "") then (
											) else
												<div id="group-{ $First }">
													<h3>{ $First }</h3>
													{
														for $rep in $repoi
														let $i := string($rep/@xml:id)

														let $inthisrepo := $reposByRepoId("https://betamasaheft.eu/" || $i)
														let $count := count($inthisrepo)
														return if ($count = 0) then (
														) else
															<div class="w3-row">
																<div class="w3-col" style="width:30%">
																	<h4><a href="{ $config:appUrl }/manuscripts/{ $i }/list">{ $rep/text() }</a></h4>
																</div>
																<div class="w3-col" style="width:5%"><span class="w3-badge">{ $count }</span></div>
																<div class="w3-col" style="width:35%">
																	<a class="w3-button w3-red" onclick="openAccordion('list{ $i }')">show list</a>
																	<div class="w3-hide" id="list{ $i }">
																		{
																			if ($count gt 500) then (
																				<div class="w3-card-4 w3-panel w3-gray w3-margin w3-padding">
																					<p
																						class="w3-large"
																					>
                            There are too many manuscripts here. Please click on the repository link for the full list.
                                </p>
																				</div>
																			) else
																				for $m in $inthisrepo
																				let $collection := root($m)//t:collection
																				group by $C := $collection[1]
																				order by $C
																				return <div class="w3-card-4 w3-panel w3-gray w3-margin w3-padding">
																					<p class="w3-large">
																						{ $C }
																						<span />
																						<span class="w3-badge w3-margin">{ string(count($m)) }</span>
																					</p>
																					<ul class="w3-ul w3-hoverable">
																						{
																							for $mcol in $m
																							let $r := root($mcol)
																							let $mainID := ($r//t:msIdentifier/t:idno)[1]/text()
																							order by $mainID
																							return <li>
																								<a href="{ $config:appUrl }/{ string-join($r/t:TEI/@xml:id) }">
																									{ string-join($r//t:msIdentifier//t:idno/text(), ", ") }
																								</a>
																							</li>
																						}
																					</ul>
																				</div>
																		}
																	</div>
																</div>
															</div>
													}
												</div>
									}
								</div>
							)
						}
					</div>
				</div>
				{ nav:footerNew() }
				<script src="resources/js/w3.js" type="text/javascript" />
				<script src="resources/js/titles.js" type="text/javascript" />
			</body>
		</html>
	)
};

declare function list:browseUnits($request as map(*)) {
	let $unitType := $request?parameters?unitType
	return (
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<meta content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea" property="og:site_name" />
				<meta content="en" property="dcterms:language schema:inLanguage" />
				<meta
					content="Copyright © Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."
					property="dcterms:rights" />
				<meta
					content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"
					property="dcterms:publisher schema:publisher" />
				{ scriptlinks:scriptStyle() }
			</head>
			<body id="body">
				{ nav:barNew() }
				{ nav:modalsNew() }
				<div class="w3-container w3-margin w3-padding-64">
					<div class="w3-main" data-value="{ $unitType }" id="result" />
					<script src="resources/js/UnitList.js" type="application/javascript" />
				</div>
				{ nav:footerNew() }
				<script src="resources/js/w3.js" type="text/javascript" />
				<script src="resources/js/titles.js" type="text/javascript" />
			</body>
		</html>
	)
};

declare function list:artthemes($request as map(*)) {
	let $keyword as xs:string* := $request?parameters?keyword
	return <html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
			<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
			<meta content="width=device-width, initial-scale=1.0" name="viewport" />
			{ $list:app-meta }
			{ scriptlinks:listScriptStyle() }
		</head>
		<body id="body">
			{ nav:barNew() }
			{ nav:modalsNew() }
			<div class="w3-container w3-padding-64 w3-margin" id="content">
				<div class="w3-container">
					<div
						class="w3-container w3-quarter w3-animate-left w3-padding "
						data-hint="The values listed here all come from the taxonomy. Click on one of them to see which entities point to it."
					>
						{
							let $collection := "authority-files"
							return for $MainCat in
									$list:taxonomy//t:category[not(parent::t:category)][t:desc = "Art Themes" or
										t:desc = "Art Keywords" or
										t:desc = "Objects and Animals"]
								let $MainCatval := $MainCat/t:desc/text()
								order by replace(lower-case($MainCatval), "\s", "")
								return <div class="w3-panel w3-padding">
									<button
										class="w3-bar-item w3-button w3-red"
										onclick="openAccordion('list{ replace($MainCatval, "\s", "") }')"
									>{ $MainCatval }<span class="w3-badge w3-margin-left">{ count($MainCat/t:category) }</span></button>
									<div class="w3-hide" id="list{ replace($MainCatval, "\s", "") }">
										<ul class="w3-ul w3-hoverable">
											{
												for $subcat in $MainCat/t:category
												let $subcatid := string($subcat/@xml:id)
												order by replace(lower-case($subcat/t:*[1]/text()), "\s", "")
												return if ($subcat/t:desc) then (
													let $subval := $subcat/t:desc
													return (
														<button class="w3-button  w3-gray w3-margin-top" onclick="openAccordion('list{ $subval }')">
															{ $subval }
															<span class="w3-badge  w3-margin-left">{ count($subcat/t:category) }</span>
														</button>,
														<br />,
														<div class="w3-hide" id="list{ $subval }">
															<ul class="w3-ul w3-hoverable">
																{
																	for $c in $subcat/t:category
																	let $subcatid := string($c/@xml:id)
																	let $text := $c/t:catDesc/text()
																	order by $text
																	return <li>
																		<a href="{ $config:appUrl }/art-themes/list?keyword={ $subcatid }">{ $text }</a>
																	</li>
																}
															</ul>
														</div>
													)
												) else
													let $sstext := $subcat/t:catDesc/text()
													order by $sstext
													return if ($subcat/t:category) then (
														<div class="w3-container w3-margin-top">
															<button class="w3-button w3-gray" onclick="openAccordion('list{ $sstext }')">
																{ $sstext }
																<span class="w3-badge  w3-margin-left">{ count($subcat/t:category) }</span>
															</button>
															<br />
															<div class="w3-hide" id="list{ $sstext }">
																<ul class="w3-ul w3-hoverable">
																	{
																		for $subsubcat in $subcat/t:category
																		let $ssid := string($subsubcat/@xml:id)
																		let $stext := $subsubcat/t:catDesc/text()
																		order by $stext
																		return <li>
																			<a href="{ $config:appUrl }/art-themes/list?keyword={ $ssid }">{ $stext }</a>
																		</li>
																	}
																</ul>
															</div>
														</div>
													) else (
														<li><a href="{ $config:appUrl }/art-themes/list?keyword={ $subcatid }">{ $sstext }</a></li>
													)
											}
										</ul>
									</div>
								</div>
						}
					</div>
					<div class="w3-threequarter w3-container w3-padding" id="main">
						{
							if ($keyword = "") then (
								<div
									class="w3-panel w3-gray w3-card-4"
								>Select an entry on the left to see all records where this occurs.</div>
							) else (
								let $res :=
									let $keywordlink := ("https://betamasaheft.eu/" || string($keyword))
									let $terms := $apprest:collection-root/t:TEI[descendant::t:term[@key eq $keyword]]
									let $title := $apprest:collection-root/t:TEI[descendant::t:title[contains(@type, $keyword)]]
									let $person := $apprest:collection-root/t:TEI[descendant::t:person[contains(@type, $keyword)]]
									let $desc := $apprest:collection-root/t:TEI[descendant::t:desc[contains(@type, $keyword)]]
									let $place := $apprest:collection-root/t:TEI[descendant::t:place[contains(@type, $keyword)]]
									let $ab := $apprest:collection-root/t:TEI[descendant::t:ab[contains(@type, $keyword)]]
									let $abc := $apprest:collection-root/t:TEI[descendant::t:ab[@corresp eq $keywordlink]]
									let $rela := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq $keyword]]
									let $relp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keyword]]
									let $rella := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq $keywordlink]]
									let $rellp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keywordlink]]
									let $faith := $apprest:collection-root/t:TEI[descendant::t:faith[contains(@type, $keyword)]]
									let $occupation := $apprest:collection-root/t:TEI[descendant::t:occupation[contains(@type, $keyword)]]
									let $refb := $apprest:collection-root/t:TEI[descendant::t:ref[@corresp eq $keywordlink]]
									let $hits := (
										$terms |
											$title |
											$person |
											$desc |
											$place |
											$ab |
											$abc |
											$faith |
											$occupation |
											$refb |
											$rela |
											$relp |
											$rella |
											$rellp
									)
									return map {"hits": $hits, "collection": "authority-files"}

								return <div class="w3-container">
									<h1>
										<a href="{ $config:appUrl }/authority-files/{ $keyword }/main">{ exptit:printTitleID($keyword) }</a>
									</h1>
									{
										let $file := $list:taxonomy/id($keyword)
										for $element in ($file//t:abstract, $file//t:listBibl)
										return <p>{ string:tei2string($element) }</p>
									}
									<div class="w3-bar">
										<div class="w3-bar-item" id="hit-count">
											{ "There are " || count($res("hits")) || " resources that contain the exact keyword: " }
											<span class="w3-tag w3-red"><a href="{ $config:appUrl }/{ $keyword }">{ $keyword }</a></span>
										</div>
									</div>
									<div class="w3-responsive">
										<table class="w3-table w3--hoverable">
											<thead><tr class="w3-tiny"><th>id</th><th>title</th><th>type</th></tr></thead>
											<tbody>
												{
													for $h in $res("hits")
													return <tr>
														<td>{ string($h/@xml:id) }</td>
														<td>
															<a href="{ $config:appUrl }/{ string($h/@xml:id) }">
																{
																	try { exptit:printTitleID($h/@xml:id) } catch * {
																		util:log("info", string($h/@xml:id))
																	}
																}
															</a>
														</td>
														<td>{ string($h/@type) }</td>
													</tr>
												}
											</tbody>
										</table>
									</div>
								</div>
							)
						}
					</div>
				</div>
			</div>
			{ nav:footerNew() }
			<script src="resources/js/w3.js" type="text/javascript" />
		</body>
	</html>
};

declare function list:getlist($request as map(*)) {
	let $collection as xs:string* := $request?parameters?collection
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $min-hits as xs:integer* := $request?parameters?min-hits
	let $max-pages as xs:integer* := $request?parameters?max-pages
	let $date-range as xs:string* := $request?parameters?date-range
	let $keyword as xs:string* := $request?parameters?keyword
	let $mainname as xs:string* := $request?parameters?mainname
	let $clavisID as xs:string* := $request?parameters?clavisID
	let $CAeID as xs:string* := $request?parameters?CAeID
	let $clavistype as xs:string* := $request?parameters?clavistype
	let $cp as xs:string* := $request?parameters?cp
	let $language as xs:string* := $request?parameters?language
	let $numberOfParts as xs:string* := $request?parameters?numberOfParts
	let $height as xs:string* := $request?parameters?height
	let $width as xs:string* := $request?parameters?width
	let $depth as xs:string* := $request?parameters?depth
	let $columnsNum as xs:string* := $request?parameters?columnsNum
	let $tmargin as xs:string* := $request?parameters?tmargin
	let $bmargin as xs:string* := $request?parameters?bmargin
	let $rmargin as xs:string* := $request?parameters?rmargin
	let $lmargin as xs:string* := $request?parameters?lmargin
	let $intercolumn as xs:string* := $request?parameters?intercolumn
	let $folia as xs:string* := $request?parameters?folia
	let $qn as xs:string* := $request?parameters?qn
	let $qcn as xs:string* := $request?parameters?qcn
	let $wL as xs:string* := $request?parameters?wL
	let $script as xs:string* := $request?parameters?script
	let $scribe as xs:string* := $request?parameters?scribe
	let $donor as xs:string* := $request?parameters?donor
	let $patron as xs:string* := $request?parameters?patron
	let $owner as xs:string* := $request?parameters?owner
	let $binder as xs:string* := $request?parameters?binder
	let $parchmentMaker as xs:string* := $request?parameters?parchmentMaker
	let $objectType as xs:string* := $request?parameters?objectType
	let $material as xs:string* := $request?parameters?material
	let $bmaterial as xs:string* := $request?parameters?bmaterial
	let $contents as xs:string* := $request?parameters?contents
	let $origPlace as xs:string* := $request?parameters?origPlace
	let $tabot as xs:string* := $request?parameters?tabot
	let $placetype as xs:string* := $request?parameters?placetype
	let $authors as xs:string* := $request?parameters?authors
	let $occupation as xs:string* := $request?parameters?occupation
	let $faith as xs:string* := $request?parameters?faith
	let $gender as xs:string* := $request?parameters?gender
	let $period as xs:string* := $request?parameters?period
	let $restorations as xs:string* := $request?parameters?restorations
	let $bindingtype as xs:string* := $request?parameters?bindingtype
	let $country as xs:string* := $request?parameters?country
	let $settlement as xs:string* := $request?parameters?settlement
	let $prms as xs:string* := $request?parameters?prms
	return let $c := $config:data-root || "/" || $collection
		let $log := log:add-log-message("/" || $collection || "/list", sm:id()//sm:real/sm:username/string(), "list")
		let $Cmap := map {"type": "collection", "name": $collection, "path": $c}
		let $parameters := map {
			"key": $keyword,
			"mainname": $mainname,
			"lang": $language,
			"date": $date-range,
			"clavisID": $clavisID,
			"CAeID": $CAeID,
			"clavistype": $clavistype,
			"cp": $cp,
			"numberOfParts": $numberOfParts,
			"height": $height,
			"width": $width,
			"depth": $depth,
			"columnsNum": $columnsNum,
			"tmargin": $tmargin,
			"bmargin": $bmargin,
			"rmargin": $rmargin,
			"lmargin": $lmargin,
			"intercolumn": $intercolumn,
			"folia": $folia,
			"qn": $qn,
			"qcn": $qcn,
			"wL": $wL,
			"script": $script,
			"scribe": $scribe,
			"donor": $donor,
			"patron": $patron,
			"owner": $owner,
			"binder": $binder,
			"parchmentMaker": $parchmentMaker,
			"objectType": $objectType,
			"material": $material,
			"bmaterial": $bmaterial,
			"contents": $contents,
			"origPlace": $origPlace,
			"tabot": $tabot,
			"placetype": $placetype,
			"authors": $authors,
			"occupation": $occupation,
			"faith": $faith,
			"gender": $gender,
			"period": $period,
			"restorations": $restorations,
			"bindingtype": $bindingtype,
			"country": $country,
			"settlement": $settlement
		}
		return (:
needs to add all the parameters added to the mss query to the parameters variable, and thus also to the list of parameters for the function
then in apprest:listrest() all these need to be taken into account for the query :) if (
			xdb:collection-available($c)
		) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ $list:app-meta }
					{ scriptlinks:listScriptStyle() }
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					<div class="w3-container w3-padding-64 w3-margin" id="content">
						{
							if ($collection = "authority-files") then
								<div class="w3-container">
									<div
										class="w3-container w3-quarter w3-animate-left w3-padding "
										data-hint="The values listed here all come from the taxonomy. Click on one of them to see which entities point to it."
									>
										{
											for $MainCat in $list:taxonomy//t:category[not(parent::t:category)]
											let $collection := "authority-files"
											let $MainCatval := $MainCat/t:desc/text()
											order by replace(lower-case($MainCatval), "\s", "")
											return <div class="w3-panel w3-padding">
												<button
													class="w3-bar-item w3-button w3-red"
													onclick="openAccordion('list{ replace($MainCatval, "\s", "") }')"
												>
													{ $MainCatval }
													<span class="w3-badge w3-margin-left">{ count($MainCat/t:category) }</span>
												</button>
												<div class="w3-hide" id="list{ replace($MainCatval, "\s", "") }">
													<ul class="w3-ul w3-hoverable">
														{
															for $subcat in $MainCat/t:category
															let $subcatid := string($subcat/@xml:id)
															order by replace(lower-case($subcat/t:*[1]/text()), "\s", "")
															return if ($subcat/t:desc) then (
																let $subval := $subcat/t:desc
																return (
																	<button
																		class="w3-button  w3-gray w3-margin-top"
																		onclick="openAccordion('list{ $subval }')"
																	>
																		{ $subval }
																		<span class="w3-badge  w3-margin-left">{ count($subcat/t:category) }</span>
																	</button>,
																	<br />,
																	<div class="w3-hide" id="list{ $subval }">
																		<ul class="w3-ul w3-hoverable">
																			{
																				for $c in $subcat/t:category
																				let $subcatid := string($c/@xml:id)
																				let $text := $c/t:catDesc/text()
																				order by $text
																				return <li>
																					<a href="{ $config:appUrl }/{ $collection }/list?keyword={ $subcatid }">
																						{ $text }
																					</a>
																				</li>
																			}
																		</ul>
																	</div>
																)
															) else
																let $sstext := $subcat/t:catDesc/text()
																order by $sstext
																return if ($subcat/t:category) then (
																	<div class="w3-container w3-margin-top">
																		<button class="w3-button w3-gray" onclick="openAccordion('list{ $sstext }')">
																			{ $sstext }
																			<span class="w3-badge  w3-margin-left">{ count($subcat/t:category) }</span>
																		</button>
																		<br />
																		<div class="w3-hide" id="list{ $sstext }">
																			<ul class="w3-ul w3-hoverable">
																				{
																					for $subsubcat in $subcat/t:category
																					let $ssid := string($subsubcat/@xml:id)
																					let $stext := $subsubcat/t:catDesc/text()
																					order by $stext
																					return <li>
																						<a href="{ $config:appUrl }/{ $collection }/list?keyword={ $ssid }">
																							{ $stext }
																						</a>
																					</li>,
																					<ul>
																						{
																							for $sss in $subcat/t:category/t:category
																							let $sssid := string($sss/@xml:id)
																							let $ssstext := concat(
																								$sss/ancestor::t:category[1]/t:catDesc/text(),
																								": ",
																								$sss/t:catDesc/text()
																							)
																							return <li>
																								<a href="{ $config:appUrl }/{ $collection }/list?keyword={ $sssid }">
																									{ $ssstext }
																								</a>
																							</li>
																						}
																					</ul>
																				}
																			</ul>
																		</div>
																	</div>
																) else (
																	<li>
																		<a href="{ $config:appUrl }/{ $collection }/list?keyword={ $subcatid }">
																			{ $sstext }
																		</a>
																	</li>
																)
														}
													</ul>
												</div>
											</div>
										}
										{ apptable:nextID($collection) }
									</div>
									<div class="w3-threequarter w3-container w3-padding" id="main">
										{
											if ($keyword = "") then (
												<div
													class="w3-panel w3-gray w3-card-4"
												>Select an entry on the left to see all records where this occurs.</div>
											) else (
												let $res :=
													let $keywordlink := ("https://betamasaheft.eu/" || string($keyword))
													let $terms := $apprest:collection-root/t:TEI[descendant::t:term[@key eq $keyword]]
													let $title := $apprest:collection-root/t:TEI[descendant::t:title[contains(@type, $keyword)]]
													let $person := $apprest:collection-root/t:TEI[descendant::t:person[contains(@type, $keyword)]]
													let $desc := $apprest:collection-root/t:TEI[descendant::t:desc[contains(@type, $keyword)]]
													let $place := $apprest:collection-root/t:TEI[descendant::t:place[contains(@type, $keyword)]]
													let $ab := $apprest:collection-root/t:TEI[descendant::t:ab[contains(@type, $keyword)]]
													let $abc := $apprest:collection-root/t:TEI[descendant::t:ab[@corresp eq $keywordlink]]
													let $rela := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq $keyword]]
													let $relp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keyword]]
													let $rella := $apprest:collection-root/t:TEI[descendant::t:relation[@active eq $keywordlink]]
													let $rellp := $apprest:collection-root/t:TEI[descendant::t:relation[@passive eq $keywordlink]]
													let $faith := $apprest:collection-root/t:TEI[descendant::t:faith[contains(@type, $keyword)]]
													let $occupation := $apprest:collection-root/t:TEI[descendant::t:occupation[contains(
														@type,
														$keyword
													)]]
													let $refb := $apprest:collection-root/t:TEI[descendant::t:ref[@corresp eq $keywordlink]]
													let $hits := (
														$terms |
															$title |
															$person |
															$desc |
															$place |
															$ab |
															$abc |
															$faith |
															$occupation |
															$refb |
															$rela |
															$relp |
															$rella |
															$rellp
													)
													return map {"hits": $hits, "collection": $collection}

												return <div class="w3-container">
													<h1>
														<a href="{ $config:appUrl }/authority-files/{ $keyword }/main">
															{ exptit:printTitleID($keyword) }
														</a>
													</h1>
													{
														let $file := $list:taxonomy/id($keyword)
														for $element in ($file//t:abstract, $file//t:listBibl)
														return <p>{ string:tei2string($element) }</p>
													}
													<div class="w3-bar">
														<div class="w3-bar-item" id="hit-count">
															{ "There are " || count($res("hits")) || " resources that contain the exact keyword: " }
															<span class="w3-tag w3-red">{ $keyword }</span>
														</div>
													</div>
													<div class="w3-responsive">
														<table class="w3-table w3--hoverable">
															<thead><tr class="w3-tiny"><th>id</th><th>title</th><th>type</th></tr></thead>
															<tbody>
																{
																	for $h in $res("hits")
																	return <tr>
																		<td>{ string($h/@xml:id) }</td>
																		<td>
																			<a href="{ $config:appUrl }/{ string($h/@xml:id) }">
																				{
																					try { exptit:printTitleID($h/@xml:id) } catch * {
																						util:log("info", string($h/@xml:id))
																					}
																				}
																			</a>
																		</td>
																		<td>{ string($h/@type) }</td>
																	</tr>
																}
															</tbody>
														</table>
													</div>
												</div>
											)
										}
									</div>
								</div>

							else
								let $parametersLenght := map:for-each(
									$parameters,
									function ($key, $value) {
										if ($value = "") then
											0
										else
											1
									}
								)
								return if (sum($parametersLenght) ge 1) then
									let $hits := apprest:listrest("collection", $collection, $parameters, $prms)
									return <div class="w3-container">
										<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
											<div class="w3-bar">
												<div class="w3-bar-item" id="hit-count">
													{ "There are " }
													<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
													{ " records in this selection of " || $collection }
												</div>
												<div id="optionsList">
													{
														if ($collection = "manuscripts") then (
															if (count($hits("hits")) lt 1050) then (
																<a
																	class="w3-button w3-bar-item w3-red"
																	href="{ replace(substring-after(request:get-uri(), "BetMas"), "list", "listChart") }?{
																		request:get-query-string()
																	}"
																	target="_blank"
																>Charts</a>
															) else (
																<a
																	class="w3-button w3-bar-item w3-red"
																	disabled="disabled"
																	href="{ replace(substring-after(request:get-uri(), "BetMas"), "list", "listChart") }?{
																		request:get-query-string()
																	}"
																	target="_blank"
																>Charts</a>
															)
														) else (
														)
													}
													{
														if ($collection = "works") then
															let $texts := $hits("hits")[descendant::t:div[@type eq "edition"]//t:ab//text()]
															return if (count($texts) lt 100) then
																let $ids :=
																	for $hit in $texts
																	return "input=https://betamasaheft.eu/works/" || string($hit/@xml:id) || ".xml"
																let $urls := string-join($ids, "&amp;")
																return <a
																	class="w3-button w3-bar-item w3-red"
																	href="http://voyant-tools.org/?{ $urls }"
																	target="_blank"
																>Voyant</a>
															else if (count($texts) eq 0) then (
																<span
																	class="w3-button w3-bar-item w3-red"
																	data-hint="No text available for analysis with Voyant Tools for this selection."
																	disabled="disabled"
																>Voyant</span>
															) else (
																<span
																	class="w3-button w3-bar-item w3-red"
																	data-hint="With less than 100 hits, you will find here a button to analyse the available texts in your selection with Voyant Tools."
																>Voyant</span>
															)
														else (
														)
													}
													<a
														class="w3-button w3-bar-item w3-gray"
														href="javascript:void(0);"
														onclick="javascript:introJs().addHints();"
													>hints</a>
													{ apptable:nextID($collection) }
												</div>
											</div>
											{
												if (count($parameters) gt 1) then
													list:paramsList($parameters)
												else (
												)
											}
										</div>
										<div class="w3-quarter">
											{ apprest:searchFilter-rest($collection, $hits) }
											{
												switch ($collection)
													case "manuscripts" return
														(apprest:institutions(), apprest:catalogues())
													default return
														()
											}
										</div>
										<div class="w3-threequarter">
											<div class="w3-row w3-left">
												{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21) }
											</div>
											<div class="row">{ apptable:table($hits, $start, $per-page) }</div>
											<div class="w3-row w3-left">
												{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21) }
											</div>
										</div>
									</div>
								else
									<div class="w3-container">
										<div
											class="w3-quarter"
											data-hint="The following filters can be applied by clicking on the filter icon below, to return to the full list, click the list, to go to advanced search the cog"
										>
											{
												let $collect := switch2:collection($collection)
												return apprest:searchFilter-rest($collection, map {"hits": <start />, "query": $collect})
											}
											{
												switch ($collection)
													case "manuscripts" return
														(apprest:institutions(), apprest:catalogues())
													default return
														()
											}
										</div>
										<div class="w3-threequarter w3-panel w3-padding w3-red">Please, select a filter.</div>
									</div>
						}
					</div>
					{ nav:footerNew() }
					<script src="resources/js/w3.js" type="text/javascript" />
					<script src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js" type="text/javascript" />
					<script src="resources/js/printgroupbutton.js" type="text/javascript" />
					<script src="resources/js/printgroup.js" type="text/javascript" />
					<script src="resources/js/toogle.js" type="text/javascript" />
					<script src="resources/js/titles.js" type="text/javascript" />
					<script src="resources/js/clavisid.js" type="text/javascript" />
					<script src="resources/js/lookup.js" type="text/javascript" />
					<script src="resources/js/NewBiblio.js" type="text/javascript" />
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:getlistChart($request as map(*)) {
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $min-hits as xs:integer* := $request?parameters?min-hits
	let $max-pages as xs:integer* := $request?parameters?max-pages
	let $date-range as xs:string* := $request?parameters?date-range
	let $keyword as xs:string* := $request?parameters?keyword
	let $mainname as xs:string* := $request?parameters?mainname
	let $clavisID as xs:string* := $request?parameters?clavisID
	let $clavistype as xs:string* := $request?parameters?clavistype
	let $cp as xs:string* := $request?parameters?cp
	let $language as xs:string* := $request?parameters?language
	let $numberOfParts as xs:string* := $request?parameters?numberOfParts
	let $height as xs:string* := $request?parameters?height
	let $width as xs:string* := $request?parameters?width
	let $depth as xs:string* := $request?parameters?depth
	let $columnsNum as xs:string* := $request?parameters?columnsNum
	let $tmargin as xs:string* := $request?parameters?tmargin
	let $bmargin as xs:string* := $request?parameters?bmargin
	let $rmargin as xs:string* := $request?parameters?rmargin
	let $lmargin as xs:string* := $request?parameters?lmargin
	let $intercolumn as xs:string* := $request?parameters?intercolumn
	let $folia as xs:string* := $request?parameters?folia
	let $qn as xs:string* := $request?parameters?qn
	let $qcn as xs:string* := $request?parameters?qcn
	let $wL as xs:string* := $request?parameters?wL
	let $script as xs:string* := $request?parameters?script
	let $scribe as xs:string* := $request?parameters?scribe
	let $donor as xs:string* := $request?parameters?donor
	let $patron as xs:string* := $request?parameters?patron
	let $owner as xs:string* := $request?parameters?owner
	let $binder as xs:string* := $request?parameters?binder
	let $parchmentMaker as xs:string* := $request?parameters?parchmentMaker
	let $objectType as xs:string* := $request?parameters?objectType
	let $material as xs:string* := $request?parameters?material
	let $bmaterial as xs:string* := $request?parameters?bmaterial
	let $contents as xs:string* := $request?parameters?contents
	let $origPlace as xs:string* := $request?parameters?origPlace
	let $tabot as xs:string* := $request?parameters?tabot
	let $placetype as xs:string* := $request?parameters?placetype
	let $authors as xs:string* := $request?parameters?authors
	let $occupation as xs:string* := $request?parameters?occupation
	let $faith as xs:string* := $request?parameters?faith
	let $gender as xs:string* := $request?parameters?gender
	let $period as xs:string* := $request?parameters?period
	let $restorations as xs:string* := $request?parameters?restorations
	let $bindingtype as xs:string* := $request?parameters?bindingtype
	let $country as xs:string* := $request?parameters?country
	let $settlement as xs:string* := $request?parameters?settlement
	let $prms as xs:string* := $request?parameters?prms
	return let $c := $config:data-root || "/"
		let $log := log:add-log-message("/" || "manuscripts" || "/list", sm:id()//sm:real/sm:username/string(), "list")
		let $Cmap := map {"type": "collection", "name": "manuscripts", "path": $c}
		let $parameters := map {
			"key": $keyword,
			"mainname": $mainname,
			"lang": $language,
			"date": $date-range,
			"clavisID": $clavisID,
			"clavistype": $clavistype,
			"cp": $cp,
			"numberOfParts": $numberOfParts,
			"height": $height,
			"width": $width,
			"depth": $depth,
			"columnsNum": $columnsNum,
			"tmargin": $tmargin,
			"bmargin": $bmargin,
			"rmargin": $rmargin,
			"lmargin": $lmargin,
			"intercolumn": $intercolumn,
			"folia": $folia,
			"qn": $qn,
			"qcn": $qcn,
			"wL": $wL,
			"script": $script,
			"scribe": $scribe,
			"donor": $donor,
			"patron": $patron,
			"owner": $owner,
			"binder": $binder,
			"parchmentMaker": $parchmentMaker,
			"objectType": $objectType,
			"material": $material,
			"bmaterial": $bmaterial,
			"contents": $contents,
			"origPlace": $origPlace,
			"tabot": $tabot,
			"placetype": $placetype,
			"authors": $authors,
			"occupation": $occupation,
			"faith": $faith,
			"gender": $gender,
			"period": $period,
			"restorations": $restorations,
			"bindingtype": $bindingtype,
			"country": $country,
			"settlement": $settlement
		}

		return (:
needs to add all the parameters added to the mss query to the parameters variable, and thus also to the list of parameters for the function
then in apprest:listrest() all these need to be taken into account for the query :) if (
			xdb:collection-available($c)
		) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ $list:app-meta }
					{ scriptlinks:scriptStyle() }
					<script src="https://www.gstatic.com/charts/loader.js" type="text/javascript" />
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					{
						let $hits := apprest:listrest("collection", "manuscripts", $parameters, $prms)
						return <div class="w3-container w3-margin w3-padding-64">
							<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
								<div class="w3-bar">
									<div class="w3-bar-item" id="hit-count">
										{ "There are " }
										<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
										{ " manuscripts in this search " }
									</div>
									<div id="optionsList">
										<a
											class="w3-bar-item w3-button w3-red"
											href="{ $config:appUrl }/{
												replace(substring-after(request:get-uri(), "BetMas"), "listChart", "list")
											}?{ request:get-query-string() }"
											target="_blank"
										>List</a>
									</div>
								</div>
								{
									if (count($parameters) gt 1) then
										list:paramsList($parameters)
									else (
									)
								}
							</div>
							<div class="w3-container w3-margin w3-padding">{ charts:chart($hits("hits")) }</div>
						</div>
					}
					{ nav:footerNew() }
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:getrepolist($request as map(*)) {
	let $repoID as xs:string* := $request?parameters?repoID
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $min-hits as xs:integer* := $request?parameters?min-hits
	let $max-pages as xs:integer* := $request?parameters?max-pages
	let $date-range as xs:string* := $request?parameters?date-range
	let $numberOfParts as xs:string* := $request?parameters?numberOfParts
	let $keyword as xs:string* := $request?parameters?keyword
	let $language as xs:string* := $request?parameters?language
	let $height as xs:string* := $request?parameters?height
	let $width as xs:string* := $request?parameters?width
	let $depth as xs:string* := $request?parameters?depth
	let $columnsNum as xs:string* := $request?parameters?columnsNum
	let $tmargin as xs:string* := $request?parameters?tmargin
	let $bmargin as xs:string* := $request?parameters?bmargin
	let $rmargin as xs:string* := $request?parameters?rmargin
	let $lmargin as xs:string* := $request?parameters?lmargin
	let $intercolumn as xs:string* := $request?parameters?intercolumn
	let $folia as xs:string* := $request?parameters?folia
	let $qn as xs:string* := $request?parameters?qn
	let $qcn as xs:string* := $request?parameters?qcn
	let $wL as xs:string* := $request?parameters?wL
	let $script as xs:string* := $request?parameters?script
	let $scribe as xs:string* := $request?parameters?scribe
	let $donor as xs:string* := $request?parameters?donor
	let $patron as xs:string* := $request?parameters?patron
	let $owner as xs:string* := $request?parameters?owner
	let $binder as xs:string* := $request?parameters?binder
	let $parchmentMaker as xs:string* := $request?parameters?parchmentMaker
	let $objectType as xs:string* := $request?parameters?objectType
	let $material as xs:string* := $request?parameters?material
	let $bmaterial as xs:string* := $request?parameters?bmaterial
	let $contents as xs:string* := $request?parameters?contents
	let $origPlace as xs:string* := $request?parameters?origPlace
	let $prms as xs:string* := $request?parameters?prms
	let $mainname as xs:string* := $request?parameters?mainname
	return (: the file for that institution :) let $repos := $config:data-rootIn || "/"
		let $log := log:add-log-message(
			"/manuscripts/" || $repoID || "/list",
			sm:id()//sm:real/sm:username/string(),
			"list"
		)
		let $Cmap := map {"type": "repo", "name": $repoID, "path": $repos}
		let $parameters := map {
			"key": $keyword,
			"lang": $language,
			"date": $date-range,
			"numberOfParts": $numberOfParts,
			"height": $height,
			"mainname": $mainname,
			"width": $width,
			"depth": $depth,
			"columnsNum": $columnsNum,
			"tmargin": $tmargin,
			"bmargin": $bmargin,
			"rmargin": $rmargin,
			"lmargin": $lmargin,
			"intercolumn": $intercolumn,
			"folia": $folia,
			"qn": $qn,
			"qcn": $qcn,
			"wL": $wL,
			"script": $script,
			"scribe": $scribe,
			"donor": $donor,
			"patron": $patron,
			"owner": $owner,
			"binder": $binder,
			"parchmentMaker": $parchmentMaker,
			"objectType": $objectType,
			"material": $material,
			"bmaterial": $bmaterial,
			"contents": $contents,
			"origPlace": $origPlace
		}
		let $file := $apprest:collection-rootIn//id($repoID)[self::t:TEI]
		return if ($file) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ $list:app-meta }
					<link href="{ $config:appUrl }/resources/css/mapbox.css" rel="stylesheet" type="text/css" />
					<link href="{ $config:appUrl }/resources/css/leaflet.css" rel="stylesheet" type="text/css" />
					<link href="{ $config:appUrl }/resources/css/leaflet.fullscreen.css" rel="stylesheet" type="text/css" />
					<link
						xmlns="http://www.w3.org/1999/xhtml"
						href="{ $config:appUrl }/resources/css/leaflet-search.css"
						rel="stylesheet"
						type="text/css" />
					{ scriptlinks:listScriptStyle() }
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.js"
						type="text/javascript" />
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="{ $config:appUrl }/resources/js/mapbox.js"
						type="text/javascript" />
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="{ $config:appUrl }/resources/js/Leaflet.fullscreen.min.js"
						type="text/javascript" />
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="{ $config:appUrl }/resources/js/leaflet-search.js"
						type="text/javascript" />
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="{ $config:appUrl }/resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"
						type="text/javascript" />
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					<div class="w3-main w3-container w3-margin w3-padding-64">
						<div class="w3-quarter w3-hide-small">
							{ item2:RestItem($file, "institutions") }
							<div class="w3-container w3-padding">
								<iframe
									allowfullscreen="true"
									height="400"
									src="https://peripleo.pelagios.org/embed/{
										encode-for-uri(concat("http://betamasaheft.eu/places/", $repoID))
									}"
									style="border:none;"
									width="100%" />
								<div id="entitymap" style="width: 100%; height: 400px; margin-top:100px" />
								<script>{ 'var placeid = "' || $repoID || '"' }</script>
								<script src="resources/geo/geojsonentitymap.js" type="text/javascript" />
							</div>
							{ apprest:EntityRelsTable($file, "institutions") }
						</div>
						{
							let $hits := apprest:listrest("repo", $repoID, $parameters, $prms)
							return <div class="w3-threequarter" id="content">
								<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
									<div class="w3-bar">
										<div class="w3-bar-item" id="hit-count">
											{ "There are " }
											<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
											{ " manuscripts at " || exptit:printTitleID($repoID) }
										</div>
										<div id="optionsList">
											<a
												class="w3-button w3-bar-item w3-red"
												href="{ $config:appUrl }/manuscripts/{ $repoID }/list/viewer"
												target="_blank"
											>Images</a>
											<a
												class="w3-button w3-bar-item w3-red"
												href="{ replace(substring-after(request:get-uri(), "BetMas"), "list", "listChart") }?{
													request:get-query-string()
												}"
												role="button"
												target="_blank"
											>Charts</a>
											<a
												class="w3-button w3-bar-item w3-gray"
												href="javascript:void(0);"
												onclick="javascript:introJs().addHints();"
											>hints</a>
											{ apptable:nextID("manuscripts") }
										</div>
									</div>
									{
										if (count($parameters) gt 1) then
											list:paramsList($parameters)
										else (
										)
									}
								</div>
								<div class="w3-threequarter">
									<div class="w3-row w3-left">
										{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21) }
									</div>
									<div class="w3-row">{ apptable:table($hits, $start, $per-page) }</div>
									<div class="w3-row w3-left">
										{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21) }
									</div>
								</div>
								<div class="w3-quarter w3-white w3-hide-small w3-hide-medium" id="search filters">
									{ apprest:searchFilter-rest($repoID, $hits) }
									<div class="w3-container">
										<a
											class="w3-button w3-large w3-red w3-margin-left"
											href="{ $config:appUrl }/manuscripts/list"
										>Back to full list</a>
									</div>
								</div>
							</div>
						}
						<div class="w3-container w3-margin">
							<div
								class="w3-panel w3-card-4 w3-margin-top w3-padding"
							>The information below is about the institution record, for the manuscript catalogue records, please see the specific information provided with each record.</div>
							{ apprest:authors($file, "institutions") }
						</div>
					</div>
					{ nav:footerNew() }
					<script src="resources/js/w3.js" type="text/javascript" />
					<script src="resources/js/introText.js" type="application/javascript" />
					<script src="resources/js/printgroupbutton.js" type="text/javascript" />
					<script src="resources/js/printgroup.js" type="text/javascript" />
					<script src="resources/js/toogle.js" type="text/javascript" />
					<script src="resources/js/titles.js" type="text/javascript" />
					<script src="resources/js/clavisid.js" type="text/javascript" />
					<script src="resources/js/lookup.js" type="text/javascript" />
					<script src="resources/js/NewBiblio.js" type="text/javascript" />
					<script src="resources/js/allattestations.js" type="text/javascript" />
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:getrepolistchart($request as map(*)) {
	let $repoID as xs:string* := $request?parameters?repoID
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $min-hits as xs:integer* := $request?parameters?min-hits
	let $max-pages as xs:integer* := $request?parameters?max-pages
	let $date-range as xs:string* := $request?parameters?date-range
	let $numberOfParts as xs:string* := $request?parameters?numberOfParts
	let $keyword as xs:string* := $request?parameters?keyword
	let $language as xs:string* := $request?parameters?language
	let $height as xs:string* := $request?parameters?height
	let $width as xs:string* := $request?parameters?width
	let $depth as xs:string* := $request?parameters?depth
	let $columnsNum as xs:string* := $request?parameters?columnsNum
	let $tmargin as xs:string* := $request?parameters?tmargin
	let $bmargin as xs:string* := $request?parameters?bmargin
	let $rmargin as xs:string* := $request?parameters?rmargin
	let $lmargin as xs:string* := $request?parameters?lmargin
	let $intercolumn as xs:string* := $request?parameters?intercolumn
	let $folia as xs:string* := $request?parameters?folia
	let $qn as xs:string* := $request?parameters?qn
	let $qcn as xs:string* := $request?parameters?qcn
	let $wL as xs:string* := $request?parameters?wL
	let $script as xs:string* := $request?parameters?script
	let $scribe as xs:string* := $request?parameters?scribe
	let $donor as xs:string* := $request?parameters?donor
	let $patron as xs:string* := $request?parameters?patron
	let $owner as xs:string* := $request?parameters?owner
	let $binder as xs:string* := $request?parameters?binder
	let $parchmentMaker as xs:string* := $request?parameters?parchmentMaker
	let $objectType as xs:string* := $request?parameters?objectType
	let $material as xs:string* := $request?parameters?material
	let $bmaterial as xs:string* := $request?parameters?bmaterial
	let $contents as xs:string* := $request?parameters?contents
	let $origPlace as xs:string* := $request?parameters?origPlace
	let $prms as xs:string* := $request?parameters?prms
	let $mainname as xs:string* := $request?parameters?mainname
	return (: the file for that institution :) let $repos := $config:data-rootIn || "/"
		let $log := log:add-log-message(
			"/manuscripts/" || $repoID || "/list",
			sm:id()//sm:real/sm:username/string(),
			"list"
		)
		let $Cmap := map {"type": "repo", "name": $repoID, "path": $repos}
		let $parameters := map {
			"key": $keyword,
			"lang": $language,
			"date": $date-range,
			"numberOfParts": $numberOfParts,
			"height": $height,
			"mainname": $mainname,
			"width": $width,
			"depth": $depth,
			"columnsNum": $columnsNum,
			"tmargin": $tmargin,
			"bmargin": $bmargin,
			"rmargin": $rmargin,
			"lmargin": $lmargin,
			"intercolumn": $intercolumn,
			"folia": $folia,
			"qn": $qn,
			"qcn": $qcn,
			"wL": $wL,
			"script": $script,
			"scribe": $scribe,
			"donor": $donor,
			"patron": $patron,
			"owner": $owner,
			"binder": $binder,
			"parchmentMaker": $parchmentMaker,
			"objectType": $objectType,
			"material": $material,
			"bmaterial": $bmaterial,
			"contents": $contents,
			"origPlace": $origPlace
		}
		let $file := $apprest:collection-rootIn//id($repoID)[self::t:TEI]
		return if ($file) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ $list:app-meta }
					{ scriptlinks:scriptStyle() }
					<script src="https://www.gstatic.com/charts/loader.js" type="text/javascript" />
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					{
						let $hits := apprest:listrest("repo", $repoID, $parameters, $prms)
						return <div class="w3-container w3-margin w3-padding-64">
							<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
								<div class="w3-bar">
									<div class="w3-bar-item" id="hit-count">
										{ "There are " }
										<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
										{ " manuscripts at " || exptit:printTitleID($repoID) }
									</div>
									<div id="optionsList">
										<a
											class="w3-bar-item w3-button w3-red"
											href="{ replace(substring-after(request:get-uri(), "BetMas"), "listChart", "list") }?{
												request:get-query-string()
											}"
											target="_blank"
										>List</a>
									</div>
									<a
										class="w3-bar-item w3-button w3-red"
										href="{ $config:appUrl }/manuscripts/{ $repoID }/list/viewer"
										target="_blank"
									>Images</a>
								</div>
								{
									if (count($parameters) gt 1) then
										list:paramsList($parameters)
									else (
									)
								}
							</div>
							<div class="w3-container w3-margin w3-padding">{ charts:chart($hits("hits")) }</div>
						</div>
					}
					{ nav:footerNew() }
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:getplacelist($request as map(*)) {
	let $place as xs:string* := $request?parameters?place
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $min-hits as xs:integer* := $request?parameters?min-hits
	let $max-pages as xs:integer* := $request?parameters?max-pages
	let $date-range as xs:string* := $request?parameters?date-range
	let $numberOfParts as xs:string* := $request?parameters?numberOfParts
	let $keyword as xs:string* := $request?parameters?keyword
	let $language as xs:string* := $request?parameters?language
	let $height as xs:string* := $request?parameters?height
	let $width as xs:string* := $request?parameters?width
	let $depth as xs:string* := $request?parameters?depth
	let $columnsNum as xs:string* := $request?parameters?columnsNum
	let $tmargin as xs:string* := $request?parameters?tmargin
	let $bmargin as xs:string* := $request?parameters?bmargin
	let $rmargin as xs:string* := $request?parameters?rmargin
	let $lmargin as xs:string* := $request?parameters?lmargin
	let $intercolumn as xs:string* := $request?parameters?intercolumn
	let $folia as xs:string* := $request?parameters?folia
	let $qn as xs:string* := $request?parameters?qn
	let $qcn as xs:string* := $request?parameters?qcn
	let $wL as xs:string* := $request?parameters?wL
	let $script as xs:string* := $request?parameters?script
	let $scribe as xs:string* := $request?parameters?scribe
	let $donor as xs:string* := $request?parameters?donor
	let $patron as xs:string* := $request?parameters?patron
	let $owner as xs:string* := $request?parameters?owner
	let $binder as xs:string* := $request?parameters?binder
	let $parchmentMaker as xs:string* := $request?parameters?parchmentMaker
	let $objectType as xs:string* := $request?parameters?objectType
	let $material as xs:string* := $request?parameters?material
	let $bmaterial as xs:string* := $request?parameters?bmaterial
	let $contents as xs:string* := $request?parameters?contents
	let $origPlace as xs:string* := $request?parameters?origPlace
	let $prms as xs:string* := $request?parameters?prms
	let $mainname as xs:string* := $request?parameters?mainname
	return (: the file for that institution :) let $repos := $config:data-rootIn || "/"
		let $log := log:add-log-message("/manuscripts/place/list", sm:id()//sm:real/sm:username/string(), "list")
		let $Cmap := map {"type": "place", "name": $place, "path": $repos}
		let $parameters := map {
			"key": $keyword,
			"lang": $language,
			"date": $date-range,
			"numberOfParts": $numberOfParts,
			"height": $height,
			"mainname": $mainname,
			"width": $width,
			"depth": $depth,
			"columnsNum": $columnsNum,
			"tmargin": $tmargin,
			"bmargin": $bmargin,
			"rmargin": $rmargin,
			"lmargin": $lmargin,
			"intercolumn": $intercolumn,
			"folia": $folia,
			"qn": $qn,
			"qcn": $qcn,
			"wL": $wL,
			"script": $script,
			"scribe": $scribe,
			"donor": $donor,
			"patron": $patron,
			"owner": $owner,
			"binder": $binder,
			"parchmentMaker": $parchmentMaker,
			"objectType": $objectType,
			"material": $material,
			"bmaterial": $bmaterial,
			"contents": $contents,
			"origPlace": $origPlace
		}
		let $file := $apprest:collection-rootPlIn//id($place)[self::t:TEI]
		let $sameAs := string($file//t:place/@sameAs)
		return if ($file or starts-with($place, "wd:")) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ $list:app-meta }
					<link href="{ $config:appUrl }/resources/css/mapbox.css" rel="stylesheet" type="text/css" />
					<link href="{ $config:appUrl }/resources/css/leaflet.css" rel="stylesheet" type="text/css" />
					<link href="{ $config:appUrl }/resources/css/leaflet.fullscreen.css" rel="stylesheet" type="text/css" />
					<link
						xmlns="http://www.w3.org/1999/xhtml"
						href="{ $config:appUrl }/resources/css/leaflet-search.css"
						rel="stylesheet"
						type="text/css" />
					{ scriptlinks:listScriptStyle() }
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.js"
						type="text/javascript" />
					<script xmlns="http://www.w3.org/1999/xhtml" src="resources/js/mapbox.js" type="text/javascript" />
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="resources/js/Leaflet.fullscreen.min.js"
						type="text/javascript" />
					<script xmlns="http://www.w3.org/1999/xhtml" src="resources/js/leaflet-search.js" type="text/javascript" />
					<script
						xmlns="http://www.w3.org/1999/xhtml"
						src="resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"
						type="text/javascript" />
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					<div class="w3-main w3-container w3-margin w3-padding-64">
						<div class="w3-quarter w3-hide-small">
							<h1>Manuscripts in { exptit:printTitleID($place) }</h1>
							<span class="w3-tag w3-gray">{ $config:appUrl || "/" || $place }</span>
							<div class="w3-container w3-padding">
								<iframe
									allowfullscreen="true"
									height="400"
									src="https://peripleo.pelagios.org/embed/{
										encode-for-uri(concat("http://betamasaheft.eu/places/", $place))
									}"
									style="border:none;"
									width="100%" />
								<div id="entitymap" style="width: 100%; height: 400px; margin-top:100px" />
								<script>{ 'var placeid = "' || $place || '"' }</script>
								<script src="resources/geo/geojsonentitymap.js" type="text/javascript" />
							</div>
							{ apprest:EntityRelsTable($file, "places") }
						</div>
						{
							let $allrepositories :=
								for $repo in
									(
										$apprest:collection-rootIn//t:settlement[@ref eq $place],
										$apprest:collection-rootIn//t:region[@ref eq $place],
										$apprest:collection-rootIn//t:country[@ref eq $place],
										$apprest:collection-rootIn//t:settlement[@ref eq $sameAs],
										$apprest:collection-rootIn//t:region[@ref eq $sameAs],
										$apprest:collection-rootIn//t:country[@ref eq $sameAs]
									)
								return $repo/ancestor::t:TEI/@xml:id
							let $repositoriesIDS := config:distinct-values($allrepositories)
							let $selected := if (count($repositoriesIDS) ge 1) then
								$apprest:collection-rootMS//t:repository[@ref eq $repositoriesIDS]
							else (
							)
							let $allmssinregion := if (count($selected) ge 1) then (
								for $s in $selected
								return $s/ancestor::t:TEI
							) else
								0
							let $stringquery := '$apprest:collection-rootMS//t:repository[@ref eq ("' ||
								string-join($repositoriesIDS, '","') ||
								'")]/ancestor::t:TEI'
							let $hits := map {"hits": $allmssinregion, "collection": "manuscripts", "query": $stringquery}
							return if ($hits("hits") = 0) then (
								<div class="w3-threequarter" id="content">
									<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
										<div class="w3-bar">
											<div class="w3-bar-item" id="hit-count">
												{
													"There are no manuscripts in " ||
														exptit:printTitleID($place) ||
														" or we simply do not have enough information to tell you, try another search please."
												}
											</div>
										</div>
									</div>
								</div>
							) else
								<div class="w3-threequarter" id="content">
									<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
										<div class="w3-bar">
											<div class="w3-bar-item" id="hit-count">
												{ "There are " }
												<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
												{ " manuscripts in " || exptit:printTitleID($place) }
											</div>
											<div id="optionsList">
												<a
													class="w3-button w3-bar-item w3-red"
													href="{ replace(substring-after(request:get-uri(), "BetMas"), "list", "listChart") }?{
														request:get-query-string()
													}"
													role="button"
													target="_blank"
												>Charts</a>
												<a
													class="w3-button w3-bar-item w3-gray"
													href="javascript:void(0);"
													onclick="javascript:introJs().addHints();"
												>hints</a>
												{ apptable:nextID("manuscripts") }
											</div>
											{
												if (count($parameters) gt 1) then
													list:paramsList($parameters)
												else (
												)
											}
										</div>
									</div>
									<div class="w3-threequarter">
										<div class="w3-row w3-left">
											{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21) }
										</div>
										<div class="w3-row">{ apptable:table($hits, $start, $per-page) }</div>
										<div class="w3-row w3-left">
											{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 9, 21) }
										</div>
									</div>
									<div class="w3-quarter w3-white w3-hide-small w3-hide-medium" id="search filters">
										{ apprest:searchFilter-rest($place, $hits) }
										<div class="w3-container">
											<a
												class="w3-button w3-large w3-red w3-margin-left"
												href="{ $config:appUrl }/manuscripts/list"
											>Back to full list</a>
										</div>
									</div>
								</div>
						}
						<div class="w3-container w3-margin">
							<div
								class="w3-panel w3-card-4 w3-margin-top w3-padding"
							>The information below is about the place record, for the manuscript catalogue records, please see the specific information provided with each record.</div>
							{ apprest:authors($file, "places") }
						</div>
					</div>
					{ nav:footerNew() }
					<script src="resources/js/w3.js" type="text/javascript" />
					<script src="resources/js/introText.js" type="application/javascript" />
					<script src="resources/js/printgroupbutton.js" type="text/javascript" />
					<script src="resources/js/printgroup.js" type="text/javascript" />
					<script src="resources/js/toogle.js" type="text/javascript" />
					<script src="resources/js/titles.js" type="text/javascript" />
					<script src="resources/js/clavisid.js" type="text/javascript" />
					<script src="resources/js/lookup.js" type="text/javascript" />
					<script src="resources/js/NewBiblio.js" type="text/javascript" />
					<script src="resources/js/allattestations.js" type="text/javascript" />
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:getregionchart($request as map(*)) {
	let $place as xs:string* := $request?parameters?place
	return (: the file for that institution :) let $repos := $config:data-rootIn || "/"
		let $log := log:add-log-message("/manuscripts/region/listChart", sm:id()//sm:real/sm:username/string(), "list")
		let $Cmap := map {"type": "reporegion", "name": $place, "path": $repos}

		let $file := $apprest:collection-rootPlIn//id($place)[self::t:TEI]
		return if ($file or starts-with($place, "wd:")) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ $list:app-meta }
					{ scriptlinks:scriptStyle() }
					<script src="https://www.gstatic.com/charts/loader.js" type="text/javascript" />
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					{
						let $allrepositories :=
							for $repo in
								(
									$apprest:collection-rootIn//t:settlement[@ref eq $place],
									$apprest:collection-rootIn//t:region[@ref eq $place],
									$apprest:collection-rootIn//t:country[@ref eq $place]
								)
							return $repo/ancestor::t:TEI/@xml:id
						let $repositoriesIDS := config:distinct-values($allrepositories)
						let $allmssinregion := $apprest:collection-rootMS//t:repository[@ref eq $repositoriesIDS]/ancestor::t:TEI
						let $hits := map {"hits": $allmssinregion}
						return <div class="w3-container w3-margin w3-padding-64">
							<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
								<div class="w3-bar">
									<div class="w3-bar-item" id="hit-count">
										{ "There are " }
										<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
										{ " manuscripts in " || exptit:printTitleID($place) }
									</div>
									<div id="optionsList">
										<a
											class="w3-bar-item w3-button w3-red"
											href="{ replace(substring-after(request:get-uri(), "BetMas"), "listChart", "list") }?{
												request:get-query-string()
											}"
											target="_blank"
										>List</a>
									</div>
									{
										if ($file) then
											<a
												class="w3-bar-item w3-button w3-red"
												href="{ $config:appUrl }/places/{ $place }/main"
												target="_blank"
											>Place record</a>
										else (
										)
									}
								</div>
							</div>
							<div class="w3-container w3-margin w3-padding">{ charts:chart($hits("hits")) }</div>
						</div>
					}
					{ nav:footerNew() }
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:getcatalogues($request as map(*)) {
	(
		log:add-log-message("/catalogues/list", sm:id()//sm:real/sm:username/string(), "list"),
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
				<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				{ $list:app-meta }
				{ scriptlinks:scriptStyle() }
			</head>
			<body id="body">
				{ nav:barNew() }
				{ nav:modalsNew() }
				{
					let $cats := $apprest:collection-rootMS//t:listBibl[@type eq "catalogue"]
					let $dist := config:distinct-values($cats//t:ptr/@target)
					return <div class="w3-container w3-margin w3-padding-64">
						<div class="w3-container">
							<h2><span class="w3-tag w3-gray">{ count($dist) }</span> available catalogues</h2>
							<table class="w3-table w3-hoverable" max-width="100%">
								<tbody>
									{
										for $catalogue in $dist
										let $itemID := replace($catalogue, ":", "_")
										let $zoTag := substring-after($catalogue, "bm:")
										let $count := count($cats//t:ptr[@target eq $catalogue])
										let $xml-url := concat(
											"https://api.zotero.org/groups/358366/items?&amp;tag=",
											$catalogue,
											"&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies"
										)
										let $val := string($catalogue)
										let $entry := $list:bibliography//b:entry[@id = $val]

										let $data := if (count($entry) ge 1) then
											let $c := $entry
											return <span n="{ count($c/preceding-sibling::t:item) + 1 }">{ $c/*:reference/node() }</span>
										else
											<span n="new">
												{
													let $request := <http:request href="{ xs:anyURI($xml-url) }" method="GET" />
													let $response := http:send-request($request)[2]
													return $response//div[@class eq "csl-bib-body"]/div/node()
												}
											</span>
										let $sorting := $data//text()[1]
										order by $catalogue
										return <tr>
											<td>
												<a
													class="lead"
													href="{ $config:appUrl }/newSearch.html?searchType=text&amp;mode=any&amp;biblref={
														$catalogue
													}"
												>{ $data }</a>
											</td>
											<td><span class="w3-badge">{ $count }</span></td>
										</tr>
									}
								</tbody>
							</table>
						</div>
						<div
							class="w3-panel w3-red w3-card-4"
						>More catalogues will be processed. A list of the catalogues to be processed and of the work in progress can be seen <a
								href="{ $config:appUrl }/availableImages.html"
							>here</a>
						</div>
					</div>
				}
				{ nav:footerNew() }
			</body>
		</html>
	)
};

declare function list:getcataloguelist($request as map(*)) {
	let $catalogueID as xs:string* := $request?parameters?catalogueID
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $min-hits as xs:integer* := $request?parameters?min-hits
	let $max-pages as xs:integer* := $request?parameters?max-pages
	let $date-range as xs:string* := $request?parameters?date-range
	let $numberOfParts as xs:string* := $request?parameters?numberOfParts
	let $keyword as xs:string* := $request?parameters?keyword
	let $language as xs:string* := $request?parameters?language
	let $height as xs:string* := $request?parameters?height
	let $width as xs:string* := $request?parameters?width
	let $depth as xs:string* := $request?parameters?depth
	let $columnsNum as xs:string* := $request?parameters?columnsNum
	let $tmargin as xs:string* := $request?parameters?tmargin
	let $bmargin as xs:string* := $request?parameters?bmargin
	let $rmargin as xs:string* := $request?parameters?rmargin
	let $lmargin as xs:string* := $request?parameters?lmargin
	let $intercolumn as xs:string* := $request?parameters?intercolumn
	let $folia as xs:string* := $request?parameters?folia
	let $qn as xs:string* := $request?parameters?qn
	let $qcn as xs:string* := $request?parameters?qcn
	let $wL as xs:string* := $request?parameters?wL
	let $script as xs:string* := $request?parameters?script
	let $scribe as xs:string* := $request?parameters?scribe
	let $donor as xs:string* := $request?parameters?donor
	let $patron as xs:string* := $request?parameters?patron
	let $owner as xs:string* := $request?parameters?owner
	let $binder as xs:string* := $request?parameters?binder
	let $parchmentMaker as xs:string* := $request?parameters?parchmentMaker
	let $objectType as xs:string* := $request?parameters?objectType
	let $material as xs:string* := $request?parameters?material
	let $bmaterial as xs:string* := $request?parameters?bmaterial
	let $contents as xs:string* := $request?parameters?contents
	let $origPlace as xs:string* := $request?parameters?origPlace
	let $prms as xs:string* := $request?parameters?prms
	return (: the file for that institution :) let $log := log:add-log-message(
			"/catalogues/" || $catalogueID || "/list",
			sm:id()//sm:real/sm:username/string(),
			"list"
		)
		let $catalogues :=
			for $catalogue in
				config:distinct-values($apprest:collection-rootMS//t:listBibl[@type eq "catalogue"]//t:ptr/@target)
			return $catalogue
		let $prefixedcatID := "bm:" || $catalogueID
		let $Cmap := map {"type": "catalogue", "name": $catalogueID, "path": $catalogues}
		let $parameters := map {
			"key": $keyword,
			"lang": $language,
			"date": $date-range,
			"numberOfParts": $numberOfParts,
			"height": $height,
			"width": $width,
			"depth": $depth,
			"columnsNum": $columnsNum,
			"tmargin": $tmargin,
			"bmargin": $bmargin,
			"rmargin": $rmargin,
			"lmargin": $lmargin,
			"intercolumn": $intercolumn,
			"folia": $folia,
			"qn": $qn,
			"qcn": $qcn,
			"wL": $wL,
			"script": $script,
			"scribe": $scribe,
			"donor": $donor,
			"patron": $patron,
			"owner": $owner,
			"binder": $binder,
			"parchmentMaker": $parchmentMaker,
			"objectType": $objectType,
			"material": $material,
			"bmaterial": $bmaterial,
			"contents": $contents,
			"origPlace": $origPlace
		}
		return if ($prefixedcatID = $catalogues) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ scriptlinks:listScriptStyle() }
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					<div class="w3-container w3-margin w3-padding-64">
						<h1>
							{
								let $itemID := replace($prefixedcatID, ":", "_")
								let $xml-url := concat(
									"https://api.zotero.org/groups/358366/items?&amp;tag=",
									$prefixedcatID,
									"&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies"
								)
								let $data := if ($list:catalogues//t:item[@xml:id = $itemID]) then
									<span n="{ count($list:catalogues//t:item[@xml:id = $itemID]/preceding-sibling::t:item) + 1 }">
										{ $list:catalogues//t:item[@xml:id = $itemID]/node() }
									</span>
								else
									<span n="new">
										{
											let $request := <http:request href="{ xs:anyURI($xml-url) }" method="GET" />
											return http:send-request($request)[2]
										}
									</span>
								return $data
							}
						</h1>
						{
							let $hits := apprest:listrest("catalogue", $catalogueID, $parameters, $prms)
							return <div class="w3-container">
								<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
									<div class="w3-bar">
										<div class="w3-bar-item" id="hit-count">
											{ "This catalogue has been quoted in " }
											<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
											{ " manuscript records." }
										</div>
										<div id="optionsList">
											<a
												class="w3-button w3-bar-item w3-red"
												href="{ replace(substring-after(request:get-uri(), "BetMas"), "list", "listChart") }?{
													request:get-query-string()
												}"
												role="button"
												target="_blank"
											>Charts</a>
											{ apptable:nextID("manuscripts") }
										</div>
									</div>
									{
										if (count($parameters) gt 1) then
											list:paramsList($parameters)
										else (
										)
									}
								</div>
								<div class="w3-quarter w3-padding">
									{ apprest:searchFilter-rest($catalogueID, $hits) }
									<div class="w3-quarter w3-margin w3-padding">
										<a
											class="w3-button w3-red w3-margin-left"
											href="{ $config:appUrl }/manuscripts/list"
										>Back to full list</a>
									</div>
								</div>
								<div class="w3-threequarter w3-padding">
									<div class="w3-row w3-left">
										{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21) }
									</div>
									<div class="w3-row">{ apptable:table($hits, $start, $per-page) }</div>
									<div class="w3-row w3-left">
										{ apprest:paginate-rest($hits, $parameters, $start, $per-page, 5, 21) }
									</div>
								</div>
							</div>
						}
					</div>
					{ nav:footerNew() }
					<script src="resources/js/w3.js" type="text/javascript" />
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:getcataloguelistChart($request as map(*)) {
	let $catalogueID as xs:string* := $request?parameters?catalogueID
	let $start as xs:integer* := $request?parameters?start
	let $per-page as xs:integer* := $request?parameters?per-page
	let $min-hits as xs:integer* := $request?parameters?min-hits
	let $max-pages as xs:integer* := $request?parameters?max-pages
	let $date-range as xs:string* := $request?parameters?date-range
	let $numberOfParts as xs:string* := $request?parameters?numberOfParts
	let $keyword as xs:string* := $request?parameters?keyword
	let $language as xs:string* := $request?parameters?language
	let $height as xs:string* := $request?parameters?height
	let $width as xs:string* := $request?parameters?width
	let $depth as xs:string* := $request?parameters?depth
	let $columnsNum as xs:string* := $request?parameters?columnsNum
	let $tmargin as xs:string* := $request?parameters?tmargin
	let $bmargin as xs:string* := $request?parameters?bmargin
	let $rmargin as xs:string* := $request?parameters?rmargin
	let $lmargin as xs:string* := $request?parameters?lmargin
	let $intercolumn as xs:string* := $request?parameters?intercolumn
	let $folia as xs:string* := $request?parameters?folia
	let $qn as xs:string* := $request?parameters?qn
	let $qcn as xs:string* := $request?parameters?qcn
	let $wL as xs:string* := $request?parameters?wL
	let $script as xs:string* := $request?parameters?script
	let $scribe as xs:string* := $request?parameters?scribe
	let $donor as xs:string* := $request?parameters?donor
	let $patron as xs:string* := $request?parameters?patron
	let $owner as xs:string* := $request?parameters?owner
	let $binder as xs:string* := $request?parameters?binder
	let $parchmentMaker as xs:string* := $request?parameters?parchmentMaker
	let $objectType as xs:string* := $request?parameters?objectType
	let $material as xs:string* := $request?parameters?material
	let $bmaterial as xs:string* := $request?parameters?bmaterial
	let $contents as xs:string* := $request?parameters?contents
	let $origPlace as xs:string* := $request?parameters?origPlace
	let $prms as xs:string* := $request?parameters?prms
	return (: the file for that institution :) let $log := log:add-log-message(
			"/catalogues/" || $catalogueID || "/list",
			sm:id()//sm:real/sm:username/string(),
			"list"
		)
		let $catalogues :=
			for $catalogue in
				config:distinct-values($apprest:collection-rootMS//t:listBibl[@type eq "catalogue"]//t:ptr/@target)
			return $catalogue
		let $prefixedcatID := "bm:" || $catalogueID
		let $Cmap := map {"type": "catalogue", "name": $catalogueID, "path": $catalogues}
		let $parameters := map {
			"key": $keyword,
			"lang": $language,
			"date": $date-range,
			"numberOfParts": $numberOfParts,
			"height": $height,
			"width": $width,
			"depth": $depth,
			"columnsNum": $columnsNum,
			"tmargin": $tmargin,
			"bmargin": $bmargin,
			"rmargin": $rmargin,
			"lmargin": $lmargin,
			"intercolumn": $intercolumn,
			"folia": $folia,
			"qn": $qn,
			"qcn": $qcn,
			"wL": $wL,
			"script": $script,
			"scribe": $scribe,
			"donor": $donor,
			"patron": $patron,
			"owner": $owner,
			"binder": $binder,
			"parchmentMaker": $parchmentMaker,
			"objectType": $objectType,
			"material": $material,
			"bmaterial": $bmaterial,
			"contents": $contents,
			"origPlace": $origPlace
		}
		return if ($prefixedcatID = $catalogues) then (
			<html xmlns="http://www.w3.org/1999/xhtml">
				<head>
					<title
						property="dcterms:title og:title schema:name"
					>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
					<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />
					<meta content="width=device-width, initial-scale=1.0" name="viewport" />
					{ $list:app-meta }
					{ scriptlinks:scriptStyle() }
					<script src="https://www.gstatic.com/charts/loader.js" type="text/javascript" />
				</head>
				<body id="body">
					{ nav:barNew() }
					{ nav:modalsNew() }
					<div class="w3-container w3-margin w3-padding-64">
						<h1>
							{
								let $itemID := replace($prefixedcatID, ":", "_")
								let $xml-url := concat(
									"https://api.zotero.org/groups/358366/items?&amp;tag=",
									$prefixedcatID,
									"&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies"
								)
								let $data := if ($list:catalogues//t:item[@xml:id = $itemID]) then
									<span n="{ count($list:catalogues//t:item[@xml:id = $itemID]/preceding-sibling::t:item) + 1 }">
										{ $list:catalogues//t:item[@xml:id = $itemID]/node() }
									</span>
								else
									<span n="new">
										{
											let $request := <http:request href="{ xs:anyURI($xml-url) }" method="GET" />
											return http:send-request($request)[2]
										}
									</span>
								return $data
							}
						</h1>
						{
							let $hits := apprest:listrest("catalogue", $catalogueID, $parameters, $prms)
							return <div class="w3-container w3-margin w3-padding-64">
								<div class="w3-panel w3-margin-bottom w3-card-4" id="listTopInfo">
									<div class="w3-bar">
										<div class="w3-bar-item" id="hit-count">
											{ "This catalogue has been quoted in " }
											<span class="w3-tag w3-gray">{ count($hits("hits")) }</span>
											{ " manuscript records." }
										</div>
										<div id="optionsList">
											<a
												class="w3-bar-item w3-button w3-red"
												href="{ replace(substring-after(request:get-uri(), "BetMas"), "listChart", "list") }?{
													request:get-query-string()
												}"
												target="_blank"
											>List</a>
										</div>
									</div>
									{
										if (count($parameters) gt 1) then
											list:paramsList($parameters)
										else (
										)
									}
								</div>
								<div class="w3-container w3-margin w3-padding">{ charts:chart($hits("hits")) }</div>
							</div>
						}
					</div>
					{ nav:footerNew() }
					<script src="resources/js/w3.js" type="text/javascript" />
				</body>
			</html>
		) else (
			roaster:response(400, "text/html", error:error($Cmap))
		)
};

declare function list:paramsList($parameters as map(*)) {
	<div class="w3-panel w3-card-4 w3-padding w3-margin-bottom">
		{
			map:for-each(
				$parameters,
				function ($key, $value) {
					if ($value = "") then (
					) else if ($key = "date") then (
						if ($value = "0,2000") then (
						) else
							<span class="w3-tag w3-small w3-gray">
								{
									"with a date (anywhere in the description) between " ||
										substring-before($value, ",") ||
										" and " ||
										substring-after($value, ",")
								}
							</span>
					) else if ($key = "wL") then (
						if ($value = "1,100") then (
						) else
							<span class="w3-tag w3-small w3-gray">
								{ "between " || substring-before($value, ",") || " and " || substring-after($value, ",") }
							</span>
					) else if ($key = "folia") then (
						if ($value = "1,1000") then (
						) else
							<span class="w3-tag w3-small w3-gray">
								{ "between " || substring-before($value, ",") || " and " || substring-after($value, ",") || " leaves" }
							</span>
					) else if ($key = "qn") then (
						if ($value = "1,100") then (
						) else
							<span class="w3-tag w3-small w3-gray">
								{
									"between " ||
										substring-before($value, ",") ||
										" and " ||
										substring-after($value, ",") ||
										" quires in the manuscript"
								}
							</span>
					) else if ($key = "qcn") then (
						if ($value = "1,40") then (
						) else
							<span class="w3-tag w3-small w3-gray">
								{
									"between " ||
										substring-before($value, ",") ||
										" and " ||
										substring-after($value, ",") ||
										" leaves in at least one quire in the manuscript"
								}
							</span>
					) else
						<span class="w3-tag w3-small w3-gray">{ $key || ": ", <span class="w3-badge">{ $value }</span> }</span>
				}
			)
		}
	</div>
};
