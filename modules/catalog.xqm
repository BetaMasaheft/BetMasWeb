xquery version "3.1" encoding "UTF-8";

(:~
 : Catalog facade. Production arities choose a per-consumer backend from
 : services.xml (CATALOG_BACKEND_<CONSUMER>); test arities select one
 : explicitly. Unknown or missing values fail safe to "legacy".
 :)
module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace selectors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-selectors" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-selectors.xqm";

declare variable $catalog:expanded := collection($config:data-root);

declare variable $catalog:raw := collection($config:bmdata-root);

declare variable $catalog:titles := doc("/db/apps/lists/titleCache.xml");

declare variable $catalog:textparts := doc("/db/apps/lists/textpartstitles.xml");

declare variable $catalog:persons := doc("/db/apps/lists/persNamesLabels.xml");

declare variable $catalog:institutions := doc("/db/apps/lists/institutions.xml");

declare variable $catalog:deleted := doc("/db/apps/lists/deleted.xml");

declare variable $catalog:bibliography := doc("/db/apps/lists/bibliography.xml");

declare function catalog:backend($consumer as xs:string) as xs:string {
	let $name := "CATALOG_BACKEND_" || upper-case(replace($consumer, "[^A-Za-z0-9]", "_"))
	let $configured := lower-case(config:service-url($name, "legacy"))
	return if ($configured = ("legacy", "catalog")) then
		$configured
	else
		"legacy"
};

declare %private function catalog:by-corresp($nodes as element()*, $value as xs:string) as element()* {
	filter($nodes, function ($node) { string($node/@corresp) = $value })
};

declare %private function catalog:raw-label($id as xs:string) {
	let $main-id := substring-before($id || "#", "#")
	let $artifact := if (doc-available("/db/apps/catalogs/labels.xml")) then
		catalog:by-corresp(doc("/db/apps/catalogs/labels.xml")//t:item, $id)[1]
	else (
	)
	let $expanded-resource := ($catalog:expanded/id($main-id))[1]
	return if ($artifact) then
		$artifact/node()
	else
		filter($expanded-resource//t:title, function ($title) { string($title/@type) = "full" })[1]/text()
};

declare %private function catalog:subtitle($node as node(), $sub-id as xs:string) as xs:string {
	if (starts-with($sub-id, "tr")) then
		"transformation " || $sub-id
	else if (starts-with($sub-id, "Uni")) then
		$sub-id
	else
		let $item := $node//id($sub-id)
		return if ($item/name() = "title") then
			string($item/@xml:lang) ||
				(
					if ($item/text()) then
						$item/text()
					else
						" ... empty, sorry!"
				)
		else if ($item/name() = "persName") then
			let $normalized := root($item)//t:persName[@type = "normalized"][contains(@corresp, $sub-id)]
			return if ($normalized) then
				string-join($normalized//text(), "")
			else
				normalize-space(string-join($item, ""))
		else if ($item/name() = "msItem") then
			if ($item/t:title/@ref) then
				catalog:label(string($item/t:title/@ref)) || " (in " || $sub-id || ")"
			else
				normalize-space(string-join($item/t:title/text(), ""))
		else if ($item/t:label) then
			normalize-space(string-join($item/t:label/text(), "")) ||
				(
					if ($item/@corresp) then
						" (same as " || string($item/@corresp) || ")"
					else
						""
				)
		else if ($item[not(t:label)]/@corresp) then
			normalize-space(string-join(catalog:label(string($item/@corresp)), ""))
		else if ($item/t:desc) then
			catalog:label(string($item/t:desc/@type)) || " " || $sub-id
		else if (
			$item/@subtype = ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday") and
				not($item/node())
		) then
			" for " || $sub-id
		else if ($item/@subtype) then
			catalog:label(string($item/@subtype)) || ": " || $sub-id
		else
			$item/name() || " " || $sub-id
};

declare %private function catalog:resolve-label($id as xs:string, $backend as xs:string) {
	let $cache-hit := $catalog:titles//t:item[@corresp = $id][1]
	let $deleted := $catalog:deleted//t:item[. = $id][1]
	return if ($deleted) then
		let $formerly := filter(
			$catalog:expanded//t:relation,
			function ($relation) {
				string($relation/@name) = "betmas:formerlyAlsoListedAs" and string($relation/@passive) = $id
			}
		)
		let $active := (
			for $relation in $formerly
			let $candidate := normalize-space($relation/@active)
			where $candidate ne normalize-space($id)
			return $candidate
		)[1]
		return if ($active) then
			catalog:resolve-label($active, $backend) ||
				" [now " ||
				$active ||
				", formerly also listed as " ||
				$id ||
				", which was requested here but has been deleted on " ||
				string($deleted/@change) ||
				"]"
		else if ($formerly) then
			string(filter($catalog:expanded/id($id)//t:title, function ($title) { string($title/@type) = "full" })/text()) ||
				" [deleted on " ||
				string($deleted/@change) ||
				"; formerlyAlsoListedAs is self-referential or empty]"
		else
			$id || " was permanently deleted"
	else if (starts-with($id, "sdc:")) then
		"La Synthaxe du Codex " || substring-after($id, "sdc:")
	else if ($id = "#") then
		<span class="w3-tag w3-red">{ "no item yet with id " || $id }</span>
	else if ($cache-hit) then
		$cache-hit/node()
	else if ($catalog:textparts//t:item[@corresp = $id]) then
		$catalog:textparts//t:item[@corresp = $id][1]/node()
	else if ($catalog:persons//t:item[@corresp = $id]) then
		$catalog:persons//t:item[@corresp = $id][1]/node()
	else if (ends-with($id, "#")) then
		catalog:resolve-label(substring($id, 1, string-length($id) - 1), $backend)
	else if (matches($id, "wd:Q\d+") or starts-with($id, "gn:") or starts-with($id, "pleiades:")) then
		doc("/db/apps/lists/placeNamesLabels.xml")//t:item[@corresp = $id][1]/text()
	else if ($id = "") then
		<span class="w3-tag w3-red">no id</span>
	else if (contains($id, "#")) then
		let $main-id := replace(substring-before($id, "#"), "^" || $config:BMurl, "")
		let $sub-id := substring-after($id, "#")
		let $persistent-node := ($catalog:expanded/id($main-id))[1]
		let $node := if ($persistent-node) then
			parse-xml(serialize($persistent-node))
		else (
		)
		return if (not($node)) then
			<span class="w3-tag w3-red">{ "No item: " || $main-id || ", could not check for " || $sub-id }</span>
		else if (starts-with($sub-id, "t")) then
			let $subtitles := $node//t:title[contains(@corresp, $sub-id)]
			return (
				$subtitles[@type = "main"]/text(),
				$subtitles[@type = "normalized"]/text(),
				$node//t:title[@xml:id = $sub-id]/text()
			)[1]
		else
			normalize-space(catalog:resolve-label($main-id, $backend) || ": " || catalog:subtitle($node, $sub-id))
	else if ($backend = "catalog") then
		catalog:raw-label(replace($id, "(\.[A-Za-z0-9\-]+)", ""))
	else
		filter(
			$catalog:expanded/id(replace($id, "(\.[A-Za-z0-9\-]+)", ""))//t:title,
			function ($title) { string($title/@type) = "full" }
		)/text()
};

declare function catalog:label($id as xs:string) {
	catalog:label($id, catalog:backend("label"))
};

declare function catalog:label($id as xs:string, $backend as xs:string) {
	catalog:resolve-label($id, $backend)
};

declare function catalog:labels($ids as xs:string*) {
	catalog:labels($ids, catalog:backend("labels"))
};

declare function catalog:labels($ids as xs:string*, $backend as xs:string) {
	$ids!catalog:label(., $backend)
};

declare function catalog:institutions() as element(t:item)* {
	catalog:institutions(catalog:backend("institutions"))
};

declare function catalog:institutions($backend as xs:string) as element(t:item)* {
	if ($backend = "catalog" and doc-available("/db/apps/catalogs/institutions.xml")) then
		doc("/db/apps/catalogs/institutions.xml")//t:item
	else if ($backend = "catalog") then
		for $institution in $catalog:raw/t:TEI[@type = "ins"]
		let $id := string($institution/@xml:id)
		let $label := normalize-space(string(selectors:place-name(parse-xml(serialize($institution)))))
		order by $label
		return <item xmlns="http://www.tei-c.org/ns/1.0" xml:id="{ $id }">{ $label }</item>
	else
		$catalog:institutions//t:item
};

declare function catalog:textparts($id as xs:string) as element(t:item)* {
	catalog:textparts($id, catalog:backend("textparts"))
};

declare function catalog:textparts($id as xs:string, $backend as xs:string) as element(t:item)* {
	if ($backend = "catalog" and doc-available("/db/apps/catalogs/textparts.xml")) then
		doc("/db/apps/catalogs/textparts.xml")//t:item[starts-with(@corresp, $id)]
	else
		$catalog:textparts//t:item[starts-with(@corresp, $id)]
};

declare function catalog:bibl($bm as xs:string) as element(b:entry)? {
	catalog:bibl($bm, catalog:backend("bibl"))
};

declare function catalog:bibl($bm as xs:string, $backend as xs:string) as element(b:entry)? {
	let $id := if (starts-with($bm, "bm:")) then
		$bm
	else
		"bm:" || $bm
	let $source := if ($backend = "catalog" and doc-available("/db/apps/catalogs/bibliography.xml")) then
		doc("/db/apps/catalogs/bibliography.xml")
	else
		$catalog:bibliography
	return ($source//b:entry[@id = ($id, replace($id, ":", "_"))])[1]
};

declare function catalog:retired($id as xs:string) as xs:boolean {
	catalog:retired($id, catalog:backend("retired"))
};

declare function catalog:retired($id as xs:string, $backend as xs:string) as xs:boolean {
	if ($backend = "catalog" and doc-available("/db/apps/catalogs/retired-ids.xml")) then
		exists(doc("/db/apps/catalogs/retired-ids.xml")//*[@xml:id = $id or @id = $id])
	else
		exists($catalog:deleted//t:item[. = $id])
};
