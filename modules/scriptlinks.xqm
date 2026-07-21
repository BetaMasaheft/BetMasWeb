xquery version "3.1" encoding "UTF-8";

(:~
 : module used by the restXQ modules functions
 : used by the main views for items
 :
 : @author Pietro Liuzzo
 :)

module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

(:~
 : embedded metadata for Zotero mapping (schema.org and dcterms properties as RDFa)
 :)
declare function scriptlinks:app-meta($biblio as node()) {
	let $col := $biblio//t:idno[@type = "collection"]/text()
	let $LM := $biblio//t:date[@type eq "lastModified"]/text()
	let $url := $biblio//t:idno[@type eq "url"]
	let $DOI := $biblio//t:idno[@type eq "DOI"]
	return (
		<meta
			xmlns="http://www.w3.org/1999/xhtml"
			content="{ $config:repo-descriptor/repo:description/text() }"
			name="description" />,
		for $author in config:distinct-values(($biblio//t:respStmt/t:name/text() | $biblio//t:editor/text()))
		return <meta
			xmlns="http://www.w3.org/1999/xhtml"
			content="{ $author }"
			property="dcterms:creator schema:creator" />,
		<meta
			xmlns="http://www.w3.org/1999/xhtml"
			content="{
				switch ($col)
					case "manuscripts" return
						"Catalogue of Ethiopian Manuscripts"
					case "works" return
						"Clavis of Ethiopian Literature"
					case "narratives" return
						"Clavis of Ethiopian Literature"
					case "places" return
						"Gazetteer of Places"
					case "institutions" return
						"Gazetteer of Places"
					case "persons" return
						"A Prosopography of Ethiopia"
					default return
						"catalogue"
			}"
			property="dcterms:type schema:genre" />,
		<meta xmlns="http://www.w3.org/1999/xhtml" content="{ $config:appUrl }/{ $col }" property="schema:isPartOf" />,
		<meta
			xmlns="http://www.w3.org/1999/xhtml"
			content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"
			property="og:site_name" />,
		<meta xmlns="http://www.w3.org/1999/xhtml" content="en" property="dcterms:language schema:inLanguage" />,
		<meta
			xmlns="http://www.w3.org/1999/xhtml"
			content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."
			property="dcterms:rights" />,
		<meta
			xmlns="http://www.w3.org/1999/xhtml"
			content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"
			property="dcterms:publisher schema:publisher" />,
		<meta xmlns="http://www.w3.org/1999/xhtml" content="{ $LM }" property="dcterms:date schema:dateModified" />,
		<meta xmlns="http://www.w3.org/1999/xhtml" content="{ $url }" property="dcterms:identifier schema:url" />,
		<meta xmlns="http://www.w3.org/1999/xhtml" content="{ $DOI }" property="dcterms:identifier dcterms:URI" />
	)
};

(:~
 : html page title
 :)
declare function scriptlinks:app-title($title) as element()* {
	<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name">{ $title }</title>
};

(:~
 : html page js calls
 :)
declare function scriptlinks:footerjsSelector() as element()* {
	if (contains(request:get-uri(), "analytic")) then (
		<script xmlns="http://www.w3.org/1999/xhtml" src="resources/js/datatable.js" type="text/javascript" />,
		<script xmlns="http://www.w3.org/1999/xhtml" src="resources/js/visgraphspec.js" type="text/javascript" />
	) else (
	)
};

(:~
 : html page script and styles to be included
 :)
declare function scriptlinks:scriptStyle() {
	(
		(: App base for client-side JS: lets scripts build URLs under the app
		   base on any deployment instead of hardcoding a host or assuming the
		   app is served at the origin root. :)
		<script type="text/javascript">{ 'var BM_APP_URL = "' || $config:appUrl || '";' }</script>,
		<link href="{ $config:appUrl }/resources/images/minilogo.ico" rel="shortcut icon" />,
		<link
			href="{ $config:appUrl }/resources/font-awesome-4.7.0/css/font-awesome.min.css"
			rel="stylesheet"
			type="text/css" />,
		<link
			href="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/css/keyboard-basic.min.css"
			rel="stylesheet"
			type="text/css" />,
		(: introjs :)
		<link href="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css" rel="stylesheet" type="text/css" />,
		<link href="{ $config:appUrl }/resources/css/style.css" rel="stylesheet" type="text/css" />,
		(: Alpheios :)
		<link
			href="https://cdn.jsdelivr.net/npm/alpheios-components@latest/dist/style/style-components.min.css"
			rel="stylesheet" />,
		(: d3 :)
		<link href="{ $config:appUrl }/resources/css/d3.css" rel="stylesheet" type="text/css" />,
		<link href="{ $config:appUrl }/resources/css/w3.css" rel="stylesheet" />,
		(: w3 :)
		<link href="{ $config:appUrl }/resources/css/w3local.css" rel="stylesheet" />,
		<script src="https://code.jquery.com/jquery-1.11.1.min.js" type="text/javascript" />
	)
};

declare function scriptlinks:listScriptStyle() {
	(
		<link
			xmlns="http://www.w3.org/1999/xhtml"
			href="{ $config:appUrl }/resources/font-awesome-4.7.0/css/font-awesome.min.css"
			rel="stylesheet"
			type="text/css" />,
		<link
			xmlns="http://www.w3.org/1999/xhtml"
			href="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/css/keyboard-basic.min.css"
			rel="stylesheet"
			type="text/css" />,
		<link
			xmlns="http://www.w3.org/1999/xhtml"
			href="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css"
			rel="stylesheet"
			type="text/css" />,
		<link
			xmlns="http://www.w3.org/1999/xhtml"
			href="$shared/resources/css/bootstrap-3.0.3.min.css"
			rel="stylesheet"
			type="text/css" />,
		<link
			xmlns="http://www.w3.org/1999/xhtml"
			href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css"
			rel="stylesheet" />,
		<link
			xmlns="http://www.w3.org/1999/xhtml"
			href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/css/bootstrap-slider.min.css"
			rel="stylesheet"
			type="text/css" />,
		<link
			xmlns="http://www.w3.org/1999/xhtml"
			href="https://cdn.jsdelivr.net/npm/alpheios-components@rc/dist/style/style-components.min.css"
			rel="stylesheet" />,
		<link xmlns="http://www.w3.org/1999/xhtml" href="{ $config:appUrl }/resources/css/w3.css" rel="stylesheet" />,
		<link xmlns="http://www.w3.org/1999/xhtml" href="{ $config:appUrl }/resources/css/w3local.css" rel="stylesheet" />,
		<script
			xmlns="http://www.w3.org/1999/xhtml"
			src="https://code.jquery.com/jquery-1.11.1.min.js"
			type="text/javascript" />,
		<script
			xmlns="http://www.w3.org/1999/xhtml"
			src="$shared/resources/scripts/bootstrap-3.0.3.min.js"
			type="text/javascript" />,
		<script
			xmlns="http://www.w3.org/1999/xhtml"
			src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"
			type="text/javascript" />,
		<script
			xmlns="http://www.w3.org/1999/xhtml"
			src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/bootstrap-slider.min.js"
			type="text/javascript" />
	)
};

(:~
 : html page script and styles to be included specific for item
 :)
declare function scriptlinks:ItemScriptStyle() {
	<link
		xmlns="http://www.w3.org/1999/xhtml"
		href="{ $config:appUrl }/resources/css/mapbox.css"
		rel="stylesheet"
		type="text/css" />,
	<link
		xmlns="http://www.w3.org/1999/xhtml"
		href="{ $config:appUrl }/resources/css/leaflet.css"
		rel="stylesheet"
		type="text/css" />,
	<link
		xmlns="http://www.w3.org/1999/xhtml"
		href="{ $config:appUrl }/resources/css/leaflet.fullscreen.css"
		rel="stylesheet"
		type="text/css" />,
	<link
		xmlns="http://www.w3.org/1999/xhtml"
		href="{ $config:appUrl }/resources/css/leaflet-search.css"
		rel="stylesheet"
		type="text/css" />,
	<link
		xmlns="http://www.w3.org/1999/xhtml"
		href="https://unpkg.com/vis-timeline/styles/vis-timeline-graph2d.min.css"
		rel="stylesheet"
		type="text/css" />,
	<script
		xmlns="http://www.w3.org/1999/xhtml"
		src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.js"
		type="text/javascript" />,
	<script xmlns="http://www.w3.org/1999/xhtml" src="resources/js/mapbox.js" type="text/javascript" />,
	<script xmlns="http://www.w3.org/1999/xhtml" src="resources/js/Leaflet.fullscreen.min.js" type="text/javascript" />,
	<script
		xmlns="http://www.w3.org/1999/xhtml"
		src="resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"
		type="text/javascript" />,
	<script xmlns="http://www.w3.org/1999/xhtml" src="https://www.gstatic.com/charts/loader.js" type="text/javascript" />,
	<script
		xmlns="http://www.w3.org/1999/xhtml"
		src="resources/openseadragon/openseadragon.min.js"
		type="text/javascript" />,
	<script
		xmlns="http://www.w3.org/1999/xhtml"
		src="https://unpkg.com/vis-timeline/standalone/umd/vis-timeline-graph2d.min.js"
		type="text/javascript" />,
	<script
		xmlns="http://www.w3.org/1999/xhtml"
		src="https://unpkg.com/vis-network@7.10.2/peer/umd/vis-network.min.js"
		type="text/javascript" />
};

(:~
 : html page script and styles to be included specific for item
 :)
declare function scriptlinks:ItemFooterScript() {
	<script src="resources/js/explain.js" type="text/javascript" />,
	<script src="resources/js/dateConversions.js" type="text/javascript" />,
	<script src="resources/js/w3.js" type="application/javascript" />,
	<script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" type="text/javascript" />,
	<script
		src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.js"
		type="text/javascript" />,
	<script
		src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.mousewheel.min.js"
		type="text/javascript" />,
	<script
		src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.extension-typing.min.js"
		type="text/javascript" />,
	<script
		src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.extension-altkeyspopup.min.js"
		type="text/javascript" />,
	<script
		src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/bootstrap-slider.min.js"
		type="text/javascript" />,
	<script src="resources/js/diacriticskeyboard.js" type="text/javascript" />,
	<script src="resources/js/analytics.js" type="text/javascript" />,
	<script src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js" type="text/javascript" />,
	<script src="resources/alpheios/alpheiosStart.js" type="text/javascript" />,
	<script src="resources/js/introText.js" type="application/javascript" />,
	<script src="resources/js/versions.js" type="text/javascript" />,
	<script src="resources/js/quotations.js" type="text/javascript" />,
	<script src="resources/js/samerole.js" type="text/javascript" />,
	<script src="resources/js/allattestations.js" type="text/javascript" />,
	<script src="resources/js/ugarit.js" type="text/javascript" />,
	<script src="resources/js/highlight.js" type="text/javascript" />,
	<script src="resources/js/titles.js" type="text/javascript" />,
	<script src="resources/js/PointsHere.js" type="text/javascript" />,
	<script src="resources/js/resp.js" type="text/javascript" />,
	<script src="resources/js/relatedItems.js" type="text/javascript" />,
	<script src="resources/js/citations.js" type="text/javascript" />,
	<script src="resources/js/hypothesis.js" type="text/javascript" />,
	<script defer="defer" src="https://unpkg.com/website-carbon-badges@1.1.3/b.min.js" />
};

(:~
 : be kind to the logged user
 :)
declare function scriptlinks:greetings-rest() {
	<a href="">Hi { sm:id()//sm:real/sm:username/string() }!</a>
};
