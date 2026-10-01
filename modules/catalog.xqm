xquery version "3.1" encoding "UTF-8";

(:~
 : Catalog facade. Production arities choose a per-consumer backend from
 : services.xml (CATALOG_BACKEND_<CONSUMER>); test arities select one
 : explicitly. Unknown or missing values fail safe to "legacy".
 :
 : `legacy` is the frozen pre-Phase-2 implementation in catalog-legacy.xqm.
 : `catalog` is this module's own resolution: a Phase 3 artifact when one is
 : present, otherwise a query over expanded TEI through the shared selectors.
 : Bibliography is the exception: EthioStudies first, then an allowlisted
 : lists fallback, else empty.
 : The two are separate code paths on purpose — the parity oracle compares
 : them, which only means anything if they can disagree.
 :)
module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";
declare namespace util = "http://exist-db.org/xquery/util";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace selectors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-selectors" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-selectors.xqm";
import module namespace legacy = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-legacy" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-legacy.xqm";
import module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-places" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-places.xqm";

declare variable $catalog:expanded := collection($config:data-root);

declare variable $catalog:raw := collection($config:bmdata-root);

declare variable $catalog:titles := doc("/db/apps/lists/titleCache.xml");

declare variable $catalog:textparts := doc("/db/apps/lists/textpartstitles.xml");

declare variable $catalog:persons := doc("/db/apps/lists/persNamesLabels.xml");

declare variable $catalog:institutions := doc("/db/apps/lists/institutions.xml");

declare variable $catalog:deleted := doc("/db/apps/lists/deleted.xml");

declare variable $catalog:bibliography := doc("/db/apps/lists/bibliography.xml");

declare variable $catalog:artifacts := "/db/apps/catalogs";

declare function catalog:backend($consumer as xs:string) as xs:string {
	let $name := "CATALOG_BACKEND_" || upper-case(replace($consumer, "[^A-Za-z0-9]", "_"))
	let $configured := lower-case(config:service-url($name, "legacy"))
	return if ($configured = ("legacy", "catalog")) then
		$configured
	else
		"legacy"
};

declare %private function catalog:manifest() as element(catalog-manifest)? {
	if (doc-available($catalog:artifacts || "/manifest.xml")) then
		doc($catalog:artifacts || "/manifest.xml")/catalog-manifest
	else (
	)
};

declare %private function catalog:expanded-sha() as xs:string? {
	let $path := $catalog:artifacts || "/expanded-sha.txt"
	let $sha := if (util:binary-doc-available($path)) then
		util:binary-to-string(util:binary-doc($path))
	else if (unparsed-text-available($path)) then
		unparsed-text($path)
	else (
	)
	return $sha!normalize-space(normalize-unicode(., "NFC"))
};

declare function catalog:sha-matches($want as xs:string, $have as xs:string?) as xs:boolean {
	empty($have) or $want = $have
};

declare %private function catalog:artifact-fresh($name as xs:string) as xs:boolean {
	let $manifest := catalog:manifest()
	let $artifact := $manifest/artifact[@name = $name]
	return if (empty($manifest) or empty($artifact) or empty($artifact/@expanded-sha)) then
		true()
	else
		let $expected := normalize-space(normalize-unicode(string($artifact/@expanded-sha), "NFC"))
		let $actual := catalog:expanded-sha()
		return catalog:sha-matches($expected, $actual)
};

declare %private function catalog:artifact($name as xs:string) as document-node()? {
	let $path := $catalog:artifacts || "/" || $name
	return if (doc-available($path) and catalog:artifact-fresh($name)) then
		doc($path)
	else (
	)
};

declare function catalog:artifact-available($name as xs:string) as xs:boolean {
	exists(catalog:artifact($name))
};

declare %private function catalog:full-title($id as xs:string) as xs:string? {
	($catalog:expanded/id($id)//t:title[@type = "full"]/text())[1]
};

declare %private function catalog:raw-label($id as xs:string) {
	let $artifact := (catalog:artifact("labels.xml")//t:item[@corresp = $id])[1]
	return if ($artifact) then
		$artifact/node()
	else
		catalog:full-title($id)
};

declare %private function catalog:subtitle($node as node(), $sub-id as xs:string) as xs:string {
	selectors:subtitle(
		$node,
		$sub-id,
		map {"label": catalog:resolve-label#1, "text": function ($nodes as node()*) { $nodes/text() }, "additio": false()}
	)
};

declare %private function catalog:deleted-label($id as xs:string, $deleted as element(t:item)) {
	let $formerly := $catalog:expanded//t:relation[@name = "betmas:formerlyAlsoListedAs"][@passive = $id]
	let $active := ($formerly[normalize-space(@active) ne normalize-space($id)]/normalize-space(@active))[1]
	return if ($active) then
		catalog:resolve-label($active) ||
			" [now " ||
			$active ||
			", formerly also listed as " ||
			$id ||
			", which was requested here but has been deleted on " ||
			string($deleted/@change) ||
			"]"
	else if ($formerly) then
		string(catalog:full-title($id)) ||
			" [deleted on " ||
			string($deleted/@change) ||
			"; formerlyAlsoListedAs is self-referential or empty]"
	else
		$id || " was permanently deleted"
};

declare %private function catalog:resolve-label($id as xs:string) {
	let $deleted := ($catalog:deleted//t:item[. = $id])[1]
	return if ($deleted) then
		catalog:deleted-label($id, $deleted)
	else if (starts-with($id, "sdc:")) then
		"La Synthaxe du Codex " || substring-after($id, "sdc:")
	else if ($id = "#") then
		<span class="w3-tag w3-red">{ "no item yet with id " || $id }</span>
	else if ($catalog:titles//t:item[@corresp = $id]) then
		($catalog:titles//t:item[@corresp = $id])[1]/node()
	else if ($catalog:textparts//t:item[@corresp = $id]) then
		($catalog:textparts//t:item[@corresp = $id])[1]/node()
	else if ($catalog:persons//t:item[@corresp = $id]) then
		($catalog:persons//t:item[@corresp = $id])[1]/node()
	else if (ends-with($id, "#")) then
		catalog:resolve-label(substring($id, 1, string-length($id) - 1))
	else if (places:external($id)) then
		let $artifact := (catalog:artifact("place-labels.xml")//t:item[@corresp = $id])[1]/text()
		return if (exists($artifact)) then
			$artifact
		else
			places:label($id)
	else if ($id = "") then
		<span class="w3-tag w3-red">{ "no id" }</span>
	else if (contains($id, "#")) then
		let $main-id := replace(substring-before($id, "#"), "^" || $config:BMurl, "")
		let $sub-id := substring-after($id, "#")
		let $node := ($catalog:expanded/id($main-id))[1]
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
			normalize-space(catalog:resolve-label($main-id) || ": " || catalog:subtitle($node, $sub-id))
	else
		(: Unlike the legacy chain, dotted citation suffixes such as
		   LIT1340EnochE.1.6-9 are stripped before the record lookup. :)
		catalog:raw-label(replace($id, "(\.[A-Za-z0-9\-]+)", ""))
};

declare function catalog:label($id as xs:string) {
	catalog:label($id, catalog:backend("label"))
};

declare function catalog:label($id as xs:string, $backend as xs:string) {
	if ($backend = "catalog") then
		catalog:resolve-label($id)
	else
		legacy:label($id)
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
	if ($backend != "catalog") then
		$catalog:institutions//t:item
	else if (catalog:artifact("institutions.xml")) then
		catalog:artifact("institutions.xml")//t:item
	else
		for $institution in $catalog:raw/t:TEI[@type = "ins"]
		let $id := string($institution/@xml:id)
		let $label := normalize-space(string(selectors:place-name($institution)))
		order by $label
		return <item xmlns="http://www.tei-c.org/ns/1.0" xml:id="{ $id }">{ $label }</item>
};

declare function catalog:textparts($id as xs:string) as element(t:item)* {
	catalog:textparts($id, catalog:backend("textparts"))
};

declare function catalog:textparts($id as xs:string, $backend as xs:string) as element(t:item)* {
	let $source := if ($backend = "catalog") then
		(catalog:artifact("textparts.xml"), $catalog:textparts)[1]
	else
		$catalog:textparts
	return $source//t:item[starts-with(@corresp, $id)]
};

(:~
 : Bibliography entry for the configured CATALOG_BACKEND_BIBL.
 :
 : @param $bm key with or without a bm: or bm_ prefix
 : @return the entry for that backend, or empty
 :)
declare function catalog:bibl($bm as xs:string) as element(b:entry)? {
	catalog:bibl($bm, catalog:backend("bibl"))
};

(:~
 : Normalize a bibliography key to the bm: form.
 :
 : @param $bm key with a bm: prefix, a bm_ prefix, or neither
 : @return the key starting with bm:
 :)
declare %private function catalog:bibl-normalize($bm as xs:string) as xs:string {
	if (starts-with($bm, "bm_")) then
		"bm:" || substring-after($bm, "bm_")
	else if (starts-with($bm, "bm:")) then
		$bm
	else
		"bm:" || $bm
};

(:~
 : Lists copy of a bibliography entry.
 :
 : Two single-value @id lookups, not @id = ($id, $alt). A general comparison
 : against a sequence full-scans bibliography.xml (~14s); one value uses the
 : range index (~10ms).
 :
 : @param $id key already in bm: form
 : @return the lists entry, or empty
 :)
declare %private function catalog:bibl-from-lists($id as xs:string) as element(b:entry)? {
	let $exact := ($catalog:bibliography//b:entry[@id = $id])[1]
	return if ($exact) then
		$exact
	else
		($catalog:bibliography//b:entry[@id = replace($id, ":", "_")])[1]
};

(:~
 : EthioStudies citation synthesized as a betmas.biblio entry.
 : b:citation is the full csl-entry text.
 :
 : @param $id key already in bm: form
 : @return the synthesized entry, or empty when citations.xml has no csl-entry
 :)
declare %private function catalog:bibl-from-ethio($id as xs:string) as element(b:entry)? {
	try {
		let $cit := (doc("/db/apps/EthioStudies/citations.xml")//*[@tag = $id])[1]
		let $div := ($cit//*:div[@class = "csl-entry"])[1]
		return if (empty($div)) then (
		) else
			<entry xmlns="betmas.biblio" id="{ $id }">
				<citation>{ normalize-space(string-join($div//text(), "")) }</citation>
				<reference>{ $div }</reference>
			</entry>
	} catch * { () }
};

(:~
 : Allowlist row for a bibliography key. Ignored when the bibl-exceptions
 : artifact pin does not match expanded-sha.txt.
 :
 : @param $id key already in bm: form
 : @return the exception entry, or empty
 :)
declare %private function catalog:bibl-exception($id as xs:string) as element()? {
	let $doc := catalog:artifact("bibl-exceptions.xml")
	return if (empty($doc)) then (
	) else
		($doc//*:entry[@bm = $id])[1]
};

(:~
 : Bibliography entry for an explicit backend.
 : catalog: EthioStudies, then a lists fallback only when the allowlist says
 : lists-fallback="true", otherwise empty.
 : any other value: lists only.
 :
 : @param $bm key with or without a bm: or bm_ prefix
 : @param $backend "catalog" or "legacy"
 : @return the entry, or empty
 :)
declare function catalog:bibl($bm as xs:string, $backend as xs:string) as element(b:entry)? {
	let $id := catalog:bibl-normalize($bm)
	return if ($backend != "catalog") then
		catalog:bibl-from-lists($id)
	else
		let $ethio := catalog:bibl-from-ethio($id)
		return if (exists($ethio)) then
			$ethio
		else
			let $ex := catalog:bibl-exception($id)
			return if (exists($ex) and $ex/@lists-fallback = "true") then
				catalog:bibl-from-lists($id)
			else (
			)
};

declare function catalog:retired($id as xs:string) as xs:boolean {
	catalog:retired($id, catalog:backend("retired"))
};

declare function catalog:retired($id as xs:string, $backend as xs:string) as xs:boolean {
	let $artifact := if ($backend = "catalog") then
		catalog:artifact("retired-ids.xml")
	else (
	)
	return if ($artifact) then
		exists($artifact//*[@xml:id = $id or @id = $id])
	else
		exists($catalog:deleted//t:item[. = $id])
};
