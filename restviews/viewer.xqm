xquery version "3.1" encoding "UTF-8";

module namespace viewer = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/iiifviewer";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace marc = "http://www.loc.gov/MARC21/slim";

import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "xmldb:exist:///db/apps/BetMasWeb/modules/item.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace iiifut = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/iiif-util" at "xmldb:exist:///db/apps/BetMasWeb/modules/iiif-util.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

(:~
 : templates:apply lookup function for this module, referenced by name
 : (viewer:lookup#2) at each of this module's templates:apply call sites
 : instead of each writing its own copy - see
 : config:template-lookup-resolve for why the function-lookup() probe
 : still has to be written locally per module rather than shared in
 : config.xqm too.
 :)
declare function viewer:lookup($functionName as xs:string, $arity as xs:integer) as function(*)? {
	config:template-lookup-resolve(
		"viewer.xqm",
		$functionName,
		$arity,
		try { function-lookup(xs:QName($functionName), $arity) } catch * { () }
	)
};

declare function viewer:allmirador($request as map(*)) {
	(
		log:add-log-message("/manuscripts/viewer", sm:id()//sm:real/sm:username/string(), "viewer"),
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
				<script src="{ config:appBase() }/resources/js/analytics.js" type="text/javascript" />
				<link href="{ config:appBase() }/resources/images/minilogo.ico" rel="shortcut icon" />
				<title
					xmlns="http://www.w3.org/1999/xhtml"
					property="dcterms:title og:title schema:name"
				>Mirador Manuscript viewer</title>
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				<link href="{ config:appBase() }/resources/mirador/css/mirador-combined.css" rel="stylesheet" type="text/css" />
				<script src="{ config:appBase() }/resources/mirador/mirador.js" />
			</head>
			<body id="body">
				<div class="w3-container w3-padding-64 w3-margin" id="content">
					<div id="viewer" />
					<script type="text/javascript">
						{ 'var data = [{collectionUri: "' || $config:appUrl || '/api/iiif/collections"}]' }
					</script>
					<script src="{ config:appBase() }/resources/js/miradorcoll.js" type="text/javascript" />
				</div>
			</body>
		</html>
	)
};

declare function viewer:allinRepo($request as map(*)) {
	let $repoid as xs:string := $request?parameters?repoid
	return (
		log:add-log-message("/manuscripts/" || $repoid || "/viewer", sm:id()//sm:real/sm:username/string(), "viewer"),
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
				<script src="{ config:appBase() }/resources/js/analytics.js" type="text/javascript" />
				<link href="{ config:appBase() }/resources/images/favicon.ico" rel="shortcut icon" />
				<title
					xmlns="http://www.w3.org/1999/xhtml"
					property="dcterms:title og:title schema:name"
				>Mirador Manuscript viewer</title>
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				<link href="{ config:appBase() }/resources/mirador/css/mirador-combined.css" rel="stylesheet" type="text/css" />
				<script src="{ config:appBase() }/resources/mirador/mirador.js" />
			</head>
			<body id="body">
				<div class="w3-margin w3-container w3-padding-64" id="content">
					<div id="viewer" />
					<script type="text/javascript">
						{ 'var data = [{collectionUri: "' || $config:appUrl || "/api/iiif/collection/" || $repoid || '"}]' }
					</script>
					<script src="{ config:appBase() }/resources/js/miradorcoll.js" type="text/javascript" />
				</div>
			</body>
		</html>
	)
};

declare function viewer:mirador($request as map(*)) {
	let $collection as xs:string := $request?parameters?collection
	let $id as xs:string := $request?parameters?id
	let $FirstCanv as xs:string* := $request?parameters?FirstCanv
	let $c := switch2:collectionVar($collection)
	let $coll := $config:data-root || "/" || $collection
	let $this := $c/id($id)
	let $title := item2:printTitle($id)
	let $countsets := count($this//t:idno[@facs])
	return if ($countsets = 1) then (
		let $manifest := viewer:manifest($this, $id, $this//t:msIdentifier/t:idno)

		let $location := viewer:location($this)
		let $m := $this//t:msIdentifier/t:idno

		let $firstcanvas := viewer:canvas($m[1])
		let $Cmap := map {"type": "collection", "name": $collection, "path": $c}
		let $Imap := map {"type": "item", "name": $id, "path": $collection}
		return if (xdb:collection-available($coll)) then (
			(: check that it is one of our collections :)
			if ($collection = "institutions") then (
				(: controller should handle this by redirecting /institutions/ID/main to /manuscripts/ID/list which is then taken care of by list.xql :)
			) else (: check that the item exists :) if (item2:getTEIbyID($id)) then (
				log:add-log-message(
					"/" || $collection || "/" || $id || "/viewer",
					sm:id()//sm:real/sm:username/string(),
					"viewer"
				),
				<html xmlns="http://www.w3.org/1999/xhtml">
					<head>
						<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
						<script src="{ config:appBase() }/resources/js/analytics.js" type="text/javascript" />
						{ scriptlinks:app-title($title) }
						<link href="{ config:appBase() }/resources/images/favicon.ico" rel="shortcut icon" />
						<meta content="width=device-width, initial-scale=1.0" name="viewport" />
						{ scriptlinks:app-meta($this) }
						{ scriptlinks:scriptStyle() }
						<link
							href="{ config:appBase() }/resources/mirador/css/mirador-combined.css"
							rel="stylesheet"
							type="text/css" />
						<script src="{ config:appBase() }/resources/mirador/mirador.js" />
					</head>
					<body id="body">
						{ nav:barNew() }
						{ nav:modalsNew() }
						<div class="w3-container w3-padding-48" id="content">
							{
								(:
								 : RestViewOptions/RestItemHeader routed through
								 : templates:apply instead of called directly - see
								 : item2:RestViewOptionsTemplate/RestItemHeaderTemplate.
								 :)
								templates:apply(
									(
										<div data-template="item2:RestViewOptionsTemplate" />,
										<div data-template="item2:RestItemHeaderTemplate" />
									),
									viewer:lookup#2,
									map {"this": $this, "collection": $collection},
									config:template-apply-config()
								)
							}
							<div class="w3-container">
								<div allowfullscreen="allowfullscreen" class="w3-margin-top" id="viewer" />
								<script type="text/javascript">
									{
										'var data = [{manifestUri: "' ||
											$manifest ||
											'", location: "' ||
											$location[1] ||
											'"}]
var loadedM =  "' ||
											$manifest ||
											'"
var canvasid = "' ||
											(
												if ($FirstCanv = "") then
													$firstcanvas
												else
													$FirstCanv
											) ||
											'"
'
									}
								</script>
								<script src="{ config:appBase() }/resources/js/mirador.js" type="text/javascript" />
							</div>
							<div class="w3-panel w3-gray w3-card-2">
								<p>
									<a href="{ $manifest }" target="_blank">
										<img src="{ config:appBase() }/resources/images/iiif.png" width="20px" />
										{ $manifest }
									</a>
								</p>
							</div>
							{ item2:authors($this, $collection) }
						</div>
						{ nav:footerNew() }
					</body>
				</html>
			) else (
				error:error($Imap)
			)
		) else (
			error:error($Cmap)
		)
	) (: if there are more  facs, then print a multiple view mirador :) else (
		let $facs := $this//t:idno[@facs][@n]
		let $countsets := count($facs)
		let $locations :=
			for $m in $facs
			let $manifest := viewer:manifest($this, $id, $m)

			let $location := viewer:location($this)
			return '{"manifestUri": "' || $manifest || '", "location": "' || $location[1] || '"}'
		let $manifests :=
			for $i in 1 to $countsets
			let $m := ($facs)[$i]
			let $manifest := viewer:manifest($this, $id, $m)
			let $n := $m/@n
			let $index := count($m/preceding::t:idno[@facs][@n]) + 1
			let $firstcanvas := viewer:canvas($m[1])
			return '{  "loadedManifest": "' ||
				$manifest ||
				'",
                                    "canvasID": "' ||
				(
					if ($FirstCanv = "") then
						$firstcanvas
					else
						$FirstCanv
				) ||
				'",
                                    "slotAddress": "row1.column' ||
				string($index) ||
				'",
                                    "viewType": "ImageView" }'

		let $Cmap := map {"type": "collection", "name": $collection, "path": $c}
		let $Imap := map {"type": "item", "name": $id, "path": $collection}
		return if (xdb:collection-available($coll)) then (
			(: check that it is one of our collections :)
			if ($collection = "institutions") then (
				(: controller should handle this by redirecting /institutions/ID/main to /manuscripts/ID/list which is then taken care of by list.xql :)
			) else (: check that the item exists :) if (item2:getTEIbyID($id)) then (
				log:add-log-message(
					"/" || $collection || "/" || $id || "/viewer",
					sm:id()//sm:real/sm:username/string(),
					"viewer"
				),
				<html xmlns="http://www.w3.org/1999/xhtml">
					<head>
						<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
						<script src="{ config:appBase() }/resources/js/analytics.js" type="text/javascript" />
						{ scriptlinks:app-title($title) }
						<link href="{ config:appBase() }/resources/images/favicon.ico" rel="shortcut icon" />
						<meta content="width=device-width, initial-scale=1.0" name="viewport" />
						{ scriptlinks:app-meta($this) }
						{ scriptlinks:scriptStyle() }
						<link
							href="{ config:appBase() }/resources/mirador/css/mirador-combined.css"
							rel="stylesheet"
							type="text/css" />
						<script src="{ config:appBase() }/resources/mirador/mirador.js" />
					</head>
					<body id="body">
						{ nav:barNew() }
						{ nav:modalsNew() }
						<div class="w3-container w3-padding-48" id="content">
							{
								(:
								 : RestViewOptions/RestItemHeader routed through
								 : templates:apply instead of called directly - see
								 : item2:RestViewOptionsTemplate/RestItemHeaderTemplate.
								 :)
								templates:apply(
									(
										<div data-template="item2:RestViewOptionsTemplate" />,
										<div data-template="item2:RestItemHeaderTemplate" />
									),
									viewer:lookup#2,
									map {"this": $this, "collection": $collection},
									config:template-apply-config()
								)
							}
							<div class="w3-container">
								<div allowfullscreen="allowfullscreen" class="w3-margin-top" id="viewer" />
								<script type="text/javascript">
									{
										'
var countlayout = "1x' ||
											$countsets ||
											'"
var data = [' ||
											string-join($locations, ", ") ||
											"]
var windowobjs =  [" ||
											string-join($manifests, ", ") ||
											"]
"
									}
								</script>
								<script src="{ config:appBase() }/resources/js/miradormultiple.js" type="text/javascript" />
							</div>
							<div class="w3-panel w3-gray w3-card-2">
								{
									for $m in $this/t:idno[@facs][@n]
									let $manifest := viewer:manifest($this, $id, $m)
									return <p>
										<a href="{ $manifest }" target="_blank">
											<img src="{ config:appBase() }/resources/images/iiif.png" width="20px" />
											{ $manifest }
										</a>
									</p>
								}
							</div>
							{ item2:authors($this, $collection) }
						</div>
						{ nav:footerNew() }
					</body>
				</html>
			) else (
				error:error($Imap)
			)
		) else (
			error:error($Cmap)
		)
	)
};

declare function viewer:canvas($m) {
	let $id := string($m/ancestor::t:TEI/@xml:id)
	let $facsUrl := iiifut:facs-switch($m[1])
	return iiifut:calculate-canvas($facsUrl, "1", $id, $config:appUrl)
};

(: for cases in which there is a facsimile with a @facs linked from the idno/@facs :)
declare function viewer:facsSwitch($idnofacs) {
	if (starts-with($idnofacs/@facs, "#")) then (
		let $facsimileID := substring-after($idnofacs/@facs, "#")
		return $idnofacs/ancestor::t:TEI//t:facsimile[@xml:id = $facsimileID]/@facs
	) else
		$idnofacs/@facs
};

declare function viewer:manifest($this, $id, $m) {
	let $alt := if ($m/parent::t:altIdentifier) then (
		"?alt=" || string($m/parent::t:altIdentifier/@xml:id)
	) else if ($m/parent::t:altIdentifier) then (
		"?alt=alt"
	) else (
	)
	return (: BNF
                                                https://gallica.bnf.fr/ark:/12148/btv1b10087587w
                                                https://gallica.bnf.fr/iiif/ark:/12148/btv1b10087587w/manifest.json
                                                :) if (contains($this//t:repository/@ref, "INS0303BNF")) then (
		replace(viewer:facsSwitch($m), "ark:", "iiif/ark:") || "/manifest.json",
		console:log((replace(viewer:facsSwitch($m), "ark:", "iiif/ark:") || "/manifest.json"))
	) (: tuebingen :) else if (contains(viewer:facsSwitch($m), "http://idb")) then
		viewer:facsSwitch($m)
	else (: vatican :) if (contains(viewer:facsSwitch($m), "http://digi")) then
		replace(viewer:facsSwitch($m), "http:", "https:")
	else if (contains(viewer:facsSwitch($m), "https:")) then
		viewer:facsSwitch($m)
	(: Ethio-SPaRe, EMIP, Laurenziana, and all the others :)
	else
		$config:appUrl || "/api/iiif/" || $id || "/manifest" || $alt
};

declare function viewer:location($this) {
	(: ES :)
	if ($this//t:collection = "Ethio-SPaRe" or $this//t:collection = "EMIP") then
		$this//t:collection[1]
	(: BNF :)
	else if (contains($this//t:repository/@ref, "INS0303BNF")) then
		"BnF"
	(: Laurenziana :)
	else if (contains($this//t:repository/@ref, "INS0339BML")) then
		"Biblioteca Medicea Laurenziana"
	(: vatican :)
	else if (contains($this//t:repository/@ref, "INS0003BAV")) then
		"Biblioteca Apostolica Vaticana"
	else
		string-join($this//t:idno, ", ")
};

declare function viewer:allchojnacki($request as map(*)) {
	(
		log:add-log-message("/chojnacki/viewer", sm:id()//sm:real/sm:username/string(), "viewer"),
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
				<script src="{ config:appBase() }/resources/js/analytics.js" type="text/javascript" />
				<link href="{ config:appBase() }/resources/images/minilogo.ico" rel="shortcut icon" />
				<title
					xmlns="http://www.w3.org/1999/xhtml"
					property="dcterms:title og:title schema:name"
				>Mirador Chojnacki images viewer</title>
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				<link href="{ config:appBase() }/resources/mirador/css/mirador-combined.css" rel="stylesheet" type="text/css" />
				<script src="{ config:appBase() }/resources/mirador/mirador.js" />
			</head>
			<body id="body">
				<div class="w3-container w3-padding-64 w3-margin" id="content">
					<div id="viewer" />
					<script type="text/javascript">
						{
							let $manifs :=
								for $ch in collection($config:data-rootCh)//marc:record
								let $segnatura := $ch//marc:datafield[@tag = "852"]/marc:subfield[@code = "h"]/text()
								return '{"manifestUri": "https://digi.vatlib.it/iiif/STP_' ||
									string-join($segnatura) ||
									'/manifest.json", "location" : "DigiVatLib"}'

							let $chmanif := string-join($manifs, ",")
							return "var data = [" || $chmanif || "]"
						}
					</script>
					<script src="{ config:appBase() }/resources/js/miradorcoll.js" type="text/javascript" />
				</div>
			</body>
		</html>
	)
};
