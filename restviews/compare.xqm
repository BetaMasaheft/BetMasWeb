xquery version "3.1" encoding "UTF-8";

(:~
 : template like RESTXQ module to generate the comparison page
 :
 : @author Pietro Liuzzo
 :)

module namespace compare = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/compare";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

declare variable $compare:meta := (
	<meta
		xmlns="http://www.w3.org/1999/xhtml"
		content="{ $config:repo-descriptor/repo:description/text() }"
		name="description" />,
	for $genauthor in $config:repo-descriptor/repo:author
	return <meta xmlns="http://www.w3.org/1999/xhtml" content="{ $genauthor/text() }" name="creator" />
);

declare function compare:compare($request as map(*)) {
	let $workid as xs:string* := $request?parameters?workid
	let $fullurl := ("?workid=" || $workid)
	let $log := log:add-log-message($fullurl, sm:id()//sm:real/sm:username/string(), "compare")
	let $w := collection($config:data-root)/id($workid)

	let $Cmap := map {"type": "item", "name": $workid, "path": base-uri($w)}

	return if (exists($w) or $workid = "") then (
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
				<script src="resources/js/analytics.js" type="text/javascript" />
				<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
				<link href="resources/images/favicon.ico" rel="shortcut icon" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				{ $compare:meta }
				<meta
					xmlns="http://www.w3.org/1999/xhtml"
					content="Comparison of Manuscripts of { $workid }"
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
						<form
							action=""
							class="w3-container"
							data-hint="enter here the id of the work you would like to compare. Alternatively, if you go to the clavis list view you can select explicitly which mss you want to compare from the results of your search. From a literary work view you can click the compare tab to feed this view with the list of manuscripts containing that work."
						>
							<input
								class="w3-input w3-border"
								data-value="works"
								id="GoTo"
								list="gotohits"
								name="workid"
								placeholder="choose work to compare manuscripts" />
							<datalist id="gotohits" />
							<div class="w3-bar">
								<button class="w3-bar-item w3-button w3-red" type="submit"> Compare
                </button>
								<a
									class="w3-bar-item w3-button w3-gray"
									href="javascript:void(0);"
									onclick="javascript:introJs().addHints();"
								>show hints</a>
								<a
									class="w3-bar-item w3-button w3-gray"
									href="/compareSelected"
								> Select specific mss
                </a>
							</div>
						</form>
						<div class="msscomp w3-container">{ apprest:compareMssFromForm($workid) }</div>
					</div>
				</div>
				{ nav:footerNew() }
				<script src="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js" type="text/javascript" />
				<script src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js" type="text/javascript" />
				<script src="resources/js/introText.js" type="application/javascript" />
				<script src="resources/js/titles.js" type="text/javascript" />
				<script src="resources/js/slickoptions.js" type="text/javascript" />
				<script src="resources/js/coloronhover.js" type="application/javascript" />
				<script src="resources/js/lookup.js" type="text/javascript" />
			</body>
		</html>
	) else (
		roaster:response(400, "text/html", error:error($Cmap))
	)
};

declare function compare:compareSelected($request as map(*)) {
	let $mss as xs:string* := $request?parameters?mss
	let $list := $mss
	let $fullurl := ("?mss=" || $mss)
	let $Cmap := map {"type": "item", "name": $list, "path": $fullurl}

	return (
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
				<link href="resources/images/favicon.ico" rel="shortcut icon" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				{ $compare:meta }
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
				<div class="w3-container w3-margin w3-padding-64" id="content">
					<div class="w3-container">
						<form
							action=""
							class="w3-container"
							data-hint="enter here the ids of specific mss of a certain work you would like to compare."
						>
							<input
								class="w3-input w3-border"
								data-value="manuscripts"
								id="GoTo"
								list="gotohits"
								name="mss"
								placeholder="choose mss to compare" />
							<datalist id="gotohits" />
							<div class="w3-bar">
								<button class="w3-bar-item w3-button w3-red" type="submit"> Compare
                </button>
								<a
									class="w3-bar-item w3-button w3-gray"
									href="javascript:void(0);"
									onclick="javascript:introJs().addHints();"
								>show hints</a>
								<a class="w3-bar-item w3-button w3-gray" href="/compare">Compare all</a>
							</div>
						</form>
						<div class="msscomp w3-container">{ apprest:compareMssFromlist($list) }</div>
					</div>
				</div>
				{ nav:footerNew() }
				<script src="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js" type="text/javascript" />
				<script src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js" type="text/javascript" />
				<script src="resources/js/introText.js" type="application/javascript" />
				<script src="resources/js/titles.js" type="text/javascript" />
				<script src="resources/js/slickoptions.js" type="text/javascript" />
				<script src="resources/js/coloronhover.js" type="application/javascript" />
				<script src="resources/js/lookup.js" type="text/javascript" />
			</body>
		</html>
	)
};
