xquery version "3.1" encoding "UTF-8";

(:~
 : Frozen `legacy` backend of the catalog contract: a faithful port of
 : exptit:printTitleID as it stood at ba64d7d, before Phase 2 moved label
 : resolution behind the facade. It exists so the parity oracle compares two
 : genuinely different implementations, and so that consumers configured with
 : `legacy` keep their pre-Phase-2 output, including the branch order, the
 : effectively-dead dotted-id guard, and the HTML fallback markers.
 :
 : Do not "improve" anything here. Fixes belong in the `catalog` backend,
 : where the oracle can show what they change.
 :
 : The one deliberate deviation is external place labels: they resolve through
 : catalog-places.xqm, which caches instead of writing placeNamesLabels.xml on
 : the serving path (Phase 2 deliverable D).
 :)
module namespace legacy = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-legacy";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace selectors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-selectors" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-selectors.xqm";
import module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-places" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-places.xqm";

declare variable $legacy:col := collection($config:data-root);

declare variable $legacy:titleCache := doc("/db/apps/lists/titleCache.xml");

declare variable $legacy:TUList := doc("/db/apps/lists/textpartstitles.xml");

declare variable $legacy:persNamesList := doc("/db/apps/lists/persNamesLabels.xml");

declare variable $legacy:deleted := doc("/db/apps/lists/deleted.xml");

(:~
 : Self-loop-safe successor id, as titles:distinctSuccessor. Inlined to keep
 : this module free of the raw-data title module.
 :)
declare %private function legacy:successor($formerly as element()*, $id as xs:string) as xs:string? {
	($formerly[normalize-space(@active) ne normalize-space($id)]/normalize-space(@active))[1]
};

declare function legacy:subtitle($node as node(), $sub-id as xs:string) as xs:string {
	selectors:subtitle(
		$node,
		$sub-id,
		map {
			"label": legacy:label#1,
			"text": function ($nodes as node()*) { $nodes/text() },
			"additio": false()
		}
	)
};

declare function legacy:label($id as xs:string) {
	let $cacheHit := $legacy:titleCache//t:item[@corresp eq $id][1]
	return if ($legacy:deleted//t:item[. = $id]) then
		let $del := $legacy:deleted//t:item[. = $id]
		let $formerly := $legacy:col//t:relation[@name eq "betmas:formerlyAlsoListedAs"][@passive eq $id]
		let $active := legacy:successor($formerly, $id)
		return if ($active) then
			legacy:label($active) ||
				" [now " ||
				$active ||
				", formerly also listed as " ||
				$id ||
				", which was requested here but has been deleted on " ||
				string($del/@change) ||
				"]"
		else if (exists($formerly)) then
			string($legacy:col/id($id)//t:title[@type = "full"]/text()) ||
				" [deleted on " ||
				string($del/@change) ||
				"; formerlyAlsoListedAs is self-referential or empty]"
		else
			$id || " was permanently deleted"
	else if (starts-with($id, "sdc:")) then
		"La Synthaxe du Codex " || substring-after($id, "sdc:")
	else if ($id = "#") then
		<span class="w3-tag w3-red">{ "no item yet with id " || $id }</span>
	else if (exists($cacheHit)) then
		$cacheHit/node()
	else if ($legacy:TUList//t:item[@corresp eq $id]) then
		$legacy:TUList//t:item[@corresp eq $id][1]/node()
	else if ($legacy:persNamesList//t:item[@corresp eq $id]) then
		$legacy:persNamesList//t:item[@corresp eq $id][1]/node()
	else if (ends-with($id, "#")) then
		legacy:label(replace($id, "#", ""))
	else if (places:external($id)) then
		places:label($id)
	else if ($id = "") then
		<span class="w3-tag w3-red">{ "no id" }</span>
	else if (contains($id, "#")) then
		let $mainIDstart := substring-before($id, "#")
		let $mainID := if (starts-with($mainIDstart, $config:BMurl)) then
			substring-after($mainIDstart, $config:BMurl)
		else
			$mainIDstart
		let $SUBid := substring-after($id, "#")
		let $node := $legacy:col//id($mainID)
		return if ($node) then
			if (starts-with($SUBid, "t")) then
				let $subtitles := $node//t:title[contains(@corresp, $SUBid)]
				let $subtitlemain := $subtitles[@type eq "main"]/text()
				let $subtitlenorm := $subtitles[@type eq "normalized"]/text()
				let $tit := $node//t:title[@xml:id = $SUBid]
				return if ($subtitlemain) then
					$subtitlemain
				else if ($subtitlenorm) then
					$subtitlenorm
				else
					$tit/text()
			else
				normalize-space(legacy:label($mainID) || ": " || legacy:subtitle($node[1], $SUBid))
		else
			<span class="w3-tag w3-red">{ "No item: " || $mainID || ", could not check for " || $SUBid }</span>
	(: Retained verbatim: the pattern has no character class, so it only ever
	   matches the literal string "A-Za-z0-9.-" and this branch is dead. The
	   `catalog` backend strips dotted suffixes unconditionally instead. :)
	else if (not(starts-with($id, "http")) and matches($id, "(A-Za-z0-9\.\-)")) then
		$legacy:col/id(replace($id, "(\.[A-Za-z0-9\-]+)", ""))//t:title[@type = "full"]/text()
	else
		$legacy:col/id($id)//t:title[@type = "full"]/text()
};
