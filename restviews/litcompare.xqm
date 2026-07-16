xquery version "3.1" encoding "UTF-8";

(:~
 : template like RESTXQ module to generate the comparison page
 :
 : @author Pietro Liuzzo
 :)

module namespace litcomp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/litcomp";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/locus" at "xmldb:exist:///db/apps/BetMasWeb/modules/locus.xqm";

declare variable $litcomp:meta := (
	<meta
		xmlns="http://www.w3.org/1999/xhtml"
		content="{ $config:repo-descriptor/repo:description/text() }"
		name="description" />,
	for $genauthor in $config:repo-descriptor/repo:author
	return <meta xmlns="http://www.w3.org/1999/xhtml" content="{ $genauthor/text() }" name="creator" />
);

declare function litcomp:litcomp($request as map(*)) {
	let $worksid as xs:string* := $request?parameters?worksid
	let $type as xs:string* := $request?parameters?type
	let $fullurl := ("?worksid=" || $worksid)
	let $log := log:add-log-message($fullurl, sm:id()//sm:real/sm:username/string(), "litcomp")
	let $w := if (contains($worksid, ",")) then
		for $work in tokenize($worksid, ",")
		return $apprest:collection-rootW/id($work)
	else
		$apprest:collection-rootW/id($worksid)
	let $baseuris :=
		for $bu in $w
		return base-uri($bu)
	let $Cmap := map {"type": "item", "name": $worksid, "path": string-join($baseuris)}
	let $worktitles :=
		for $work in $w/@xml:id
		return exptit:printTitleID($work)
	let $query := switch ($type)
		case "mightFormPart" return
			$apprest:collection-rootW//t:relation[@name eq "ecrm:CLP46i_may_form_part_of"][@passive eq $worksid]
		case "contains" return
			$apprest:collection-rootW//t:relation[@name eq "saws:contains"][@active eq $worksid]
		default return
			$apprest:collection-rootW//t:relation[@name eq "saws:formsPartOf"][@passive eq $worksid]
	return if (exists($w) or $worksid = "") then (
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
				<script src="resources/js/analytics.js" type="text/javascript" />
				<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
				<link href="resources/images/favicon.ico" rel="shortcut icon" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				{ $litcomp:meta }
				<meta
					xmlns="http://www.w3.org/1999/xhtml"
					content="GeoBrowser view of Manuscripts of { $worksid }"
					property="dcterms:type schema:genre" />
				<meta
					xmlns="http://www.w3.org/1999/xhtml"
					content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"
					property="og:site_name" />
				<meta xmlns="http://www.w3.org/1999/xhtml" content="en" property="dcterms:language schema:inLanguage" />
				<meta
					xmlns="http://www.w3.org/1999/xhtml"
					content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."
					property="dcterms:rights" />
				<meta
					xmlns="http://www.w3.org/1999/xhtml"
					content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"
					property="dcterms:publisher schema:publisher" />
				<link
					href="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css"
					rel="stylesheet"
					type="text/css" />
				<link href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.css" rel="stylesheet" type="text/css" />
				<link href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick-theme.css" rel="stylesheet" type="text/css" />
				{ scriptlinks:scriptStyle() }
				<script src="https://www.gstatic.com/charts/loader.js" type="text/javascript" />
			</head>
			<body id="body">
				{ nav:barNew() }
				{ nav:modalsNew() }
				<div class="w3-container w3-padding-64 w3-margin" id="content">
					<div class="w3-container">
						<form action="" class="w3-container" data-hint="enter here the id of the work you would like to analyze.">
							<select class="w3-select w3-border" name="type">
								<option
									selected="selected"
									value="formsPart"
								>Textual Units which form part of the selected one(s)</option>
								<option value="mightFormPart">Textual Units which might form part of the selected one(s)</option>
								<option value="contains">Textual Units contained by the selected one(s)</option>
							</select>
							<input class="w3-input w3-border" data-value="works" id="GoTo" list="gotohits" name="worksid">
								{
									if (count($worksid) gt 0) then
										attribute value { $worksid }
									else
										attribute placeholder { "choose work to produce map of manuscripts" }
								}
							</input>
							<datalist id="gotohits" />
							<div class="w3-bar">
								<button class="w3-bar-item w3-button w3-red" type="submit"> Show table
                </button>
								<a
									class="w3-bar-item w3-button w3-gray"
									href="javascript:void(0);"
									onclick="javascript:introJs().addHints();"
								>show hints</a>
							</div>
						</form>
						<div class="w3-container" style="overflow-y:auto;">
							{
								if ($worksid = "") then
									<div
										class="w3-panel w3-red"
									>enter the Identifier of a Textual Unit and select the type of relation</div>
								else
									<table class="w3-table w3-striped">
										<thead>
											<tr>
												<th>ID</th>
												<th>english titles</th>
												<th>bibliography</th>
												<th>incipit</th>
												<th>manuscripts</th>
												<th>total manuscripts</th>
												<th>compare</th>
												<th>maps</th>
											</tr>
										</thead>
										<tbody>
											{
												for $miracle in $query
												let $bmid := if ($type = "contains") then
													string($miracle/@passive)
												else
													string($miracle/@active)
												let $link := "https://betamasaheft.eu/" || $bmid
												let $textlink := "https://betamasaheft.eu/works/" || $bmid || "/text"
												let $miraclefile := $apprest:collection-rootW/id($bmid)
												let $entitles := replace(string-join($miraclefile//t:title[@xml:lang = "en"], " | "), ",", "")
												let $bibl :=
													for $bib in $miraclefile//t:bibl
													return (
														<a href="https://betamasaheft.eu/bibliography?pointer={ $bib/t:ptr/@target }">
															{ string($bib/t:ptr/@target) }
														</a>,
														for $c in $bib/t:citedRange
														return $c/@unit || $c/text(),
														<br />
													)
												let $incipit := replace(
													string-join($miraclefile//t:div[@subtype eq "incipit"]/t:ab/text(), " "),
													",",
													""
												)
												let $incipitnote := replace(
													string-join(string:tei2string($miraclefile//t:div[@subtype eq "incipit"]/t:note), " "),
													",",
													""
												)
												let $mss := $apprest:collection-rootMS//t:title[@ref eq $bmid]

												return <tr>
													<td><a href="{ $link }">{ $bmid }</a></td>
													<td>{ normalize-space($entitles) }</td>
													<td>{ $bibl }</td>
													<td>{ normalize-space($incipit) }<a href="{ $textlink }">available text</a></td>
													<td>{ $incipitnote }</td>
													<td>
														{
															if (count($mss) gt 0) then
																<table>
																	<thead>
																		<tr>
																			<th>manuscript</th>
																			<th>placement</th>
																			<th>position</th>
																			<th>word count</th>
																			<th>total miracles in this MS</th>
																			<th>1/4</th>
																			<th>2/4</th>
																			<th>3/4</th>
																			<th>4/4</th>
																		</tr>
																	</thead>
																	<tbody>
																		{
																			for $m in $mss
																			let $root := string(root($m)/t:TEI/@xml:id)

																			let $msitem := $m/parent::t:msItem
																			let $placement := if ($m/preceding-sibling::t:locus) then (
																				locus:stringloc($m/preceding-sibling::t:locus)
																			) else
																				""
																			let $number := count($msitem/preceding-sibling::t:msItem) + 1
																			let $totalparts := count($msitem/parent::t:*/child::t:msItem)
																			let $position := $number || "/" || $totalparts
																			let $works :=
																				for $w in $msitem/ancestor::t:TEI//t:msItem/t:title/@ref
																				return $apprest:collection-rootW/id($w)//t:keywords
																			let $totalmiracles := count($works//t:term[@key eq "Miracle"])
																			return <tr>
																				<td>
																					<a href="https://betamasaheft.eu/{ $root }">{ exptit:printTitleID($root) }</a>
																				</td>
																				<td>{ $placement }</td>
																				<td>{ $position }</td>
																				<td><span class="WordCount" data-msID="{ $root }" data-wID="{ $bmid }" /></td>
																				<td>{ $totalmiracles }</td>
																				<td class="{ $bmid }firstquarter">
																					{
																						if ($number le ($totalparts div 4)) then
																							"x"
																						else
																							""
																					}
																				</td>
																				<td class="{ $bmid }secondquarter">
																					{
																						if (
																							($number le ($totalparts div 2)) and ($number gt ($totalparts div 4))
																						) then
																							"x"
																						else
																							""
																					}
																				</td>
																				<td class="{ $bmid }thirdquarter">
																					{
																						if (
																							($number gt ($totalparts div 2)) and
																								($number le (($totalparts div 4) + ($totalparts div 2)))
																						) then
																							"x"
																						else
																							""
																					}
																				</td>
																				<td class="{ $bmid }fourthquarter">
																					{
																						if ($number gt (($totalparts div 4) + ($totalparts div 2))) then
																							"x"
																						else
																							""
																					}
																				</td>
																			</tr>
																		}
																		<tr>
																			<td />
																			<td />
																			<td />
																			<td />
																			<td />
																			<td class="{ $bmid }percentfirstquarter" />
																			<td class="{ $bmid }percentsecondquarter" />
																			<td class="{ $bmid }percentthirdquarter" />
																			<td class="{ $bmid }percentfourthquarter" />
																		</tr>
																	</tbody>
																</table>
															else (
															)
														}
													</td>
													<td class="{ $bmid }totalMss">{ count($mss) }</td>
													<td>
														<a href="https://betamasaheft.eu/compare?workid={ $bmid }">Compare manuscript structure</a>
													</td>
													<td>
														<a href="https://betamasaheft.eu/workmap?worksid={ $bmid }">Map of Mss current location</a>
														<a href="https://betamasaheft.eu/workmap?worksid={ $bmid }">Map of Mss place of origin </a>
													</td>
												</tr>
											}
										</tbody>
									</table>
							}
						</div>
					</div>
				</div>
				{ nav:footerNew() }
				<script src="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js" type="text/javascript" />
				<script src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js" type="text/javascript" />
				<script src="resources/js/introText.js" type="application/javascript" />
				<script src="resources/js/NewBiblio.js" type="text/javascript" />
				<script src="resources/js/titles.js" type="text/javascript" />
				<script src="resources/js/slickoptions.js" type="text/javascript" />
				<script src="resources/js/coloronhover.js" type="application/javascript" />
				<script src="resources/js/lookup.js" type="text/javascript" />
				<script src="resources/js/percent.js" type="text/javascript" />
			</body>
		</html>
	) else (
		roaster:response(400, "text/html", error:error($Cmap))
	)
};
