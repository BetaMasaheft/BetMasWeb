xquery version "3.1" encoding "UTF-8";

(:~
 : module for the different item views, decides what kind of item it is, in which way to display it
 :
 : @author Pietro Liuzzo
 :)
module namespace listIds = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/listIds";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";

declare function listIds:getlist($request as map(*)) {
	<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
			<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
			<script src="resources/js/analytics.js" type="text/javascript" />
			<link href="resources/images/favicon.ico" rel="shortcut icon" />
			<meta content="width=device-width, initial-scale=1.0" name="viewport" />
			<title>list of ids</title>
			{ scriptlinks:scriptStyle() }
		</head>
		<body id="body">
			{ nav:barNew() }
			{ nav:modalsNew() }
			<p
				class="w3-large"
			>Please note that this list excludes the IslHornAfr manuscripts and EMML manuscripts. The ids of the first group are all made of the IHA sigla followed by a progressive number. The ids of the EMML manuscripts are made of the sigla EMML follwed by a progressive number.</p>
			{
				let $allrepos := collection($config:data-rootMS)//t:repository[matches(@ref, "INS")]
				let $repos := $allrepos[not(ends-with(@ref, "IHA"))][not(@ref eq "INS0004HMML")]
				for $repo in $repos
				let $ref := $repo/@ref
				group by $ref
				let $rID := string($ref)
				let $tit := try { exptit:printTitleID($rID) } catch * { "no title" }
				order by $tit
				return <div class="w3-container">
					<h1>{ $tit } ({ $rID })</h1>
					{
						for $rep in $repo
						let $collection := if ($rep/following-sibling::t:collection) then
							$rep/following-sibling::t:collection[1]/text()
						else
							"no specific collection"
						group by $collection
						order by $collection
						return <div class="w3-row">
							<h2>{ $collection }</h2>
							<div class="w3-container">
								{
									let $ids :=
										for $reC in $rep

										let $root := root($reC)
										let $id := string($root/t:TEI/@xml:id)
										return $id
									for $i in $ids
									order by $i
									return <div class="w3-row"><b>{ $i }</b></div>
								}
							</div>
						</div>
					}
				</div>
			}
		</body>
	</html>
};
