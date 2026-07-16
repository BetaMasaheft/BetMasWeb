xquery version "3.1" encoding "UTF-8";

(:~
 : template like RESTXQ module to generate the comparison page
 :
 : @author Pietro Liuzzo
 :)

module namespace LitFlowRest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/LitFlowRest";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace LitFlow = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/LitFlow" at "xmldb:exist:///db/apps/BetMasWeb/modules/LitFlow.xqm";

declare function LitFlowRest:compareSelected($request as map(*)) {
	let $subj as xs:string* := $request?parameters?subj
	let $list :=
		for $s in $subj
		return $s
	let $fullurl := "?" ||
		(
			let $ss :=
				for $s in $subj
				return ("subj=" || $s)
			return string-join($ss, "&amp;")
		)
	let $Cmap := map {"type": "item", "name": $list, "path": $fullurl}

	return (
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
				<script src="resources/js/analytics.js" type="text/javascript" />
				<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
				<link href="resources/images/favicon.ico" rel="shortcut icon" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				<meta
					xmlns="http://www.w3.org/1999/xhtml"
					content="Comparison of Manuscripts { $list }"
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
						<div class="w3-col" style="width:15%">
							<form
								action=""
								class="w3-container"
								data-hint="Select the subject keywords to see the Flow Chart break down by period."
							>
								<label>Subject Keywords</label>
								<select class="w3-select w3-border" id="inputGroupSelect01" multiple="multiple" name="subj">
									<option selected='Selected'>Choose...</option>
									{
										let $subject := doc("/db/apps/lists/canonicaltaxonomy.xml")//t:category/t:category
										for $k in $subject
										order by $k/@xml:id
										return <option value="{ data($k/@xml:id) }">{ data($k/t:catDesc) }</option>
									}
								</select>
								<div class="w3-bar">
									<button
										class="w3-bar-item w3-button w3-red"
										type="submit"
									>
                    Load literature flow
                </button>
									<a
										class="w3-button w3-bar-item w3-gray"
										href="javascript:void(0);"
										onclick="javascript:introJs().addHints();"
									>hints</a>
								</div>
							</form>
						</div>
						<div class="w3-rest">
							{
								if ($subj = "") then
									<p class="lead">Please select values from the list.</p>
								else (
									try { LitFlow:Sankey($list, "works") } catch * { $err:description },
									try { LitFlow:Sankey($list, "mss") } catch * { $err:description }
								)
							}
						</div>
					</div>
				</div>
				{ nav:footerNew() }
				<script src="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js" type="text/javascript" />
				<script src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js" type="text/javascript" />
				<script src="resources/js/titles.js" type="text/javascript" />
				<script src="resources/js/slickoptions.js" type="text/javascript" />
				<script src="resources/js/coloronhover.js" type="application/javascript" />
				<script src="resources/js/lookup.js" type="text/javascript" />
			</body>
		</html>
	)
};
