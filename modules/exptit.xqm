xquery version "3.1" encoding "UTF-8";

(: titles.xqm uses existing lists maintained on upload of the source data. it will update the lists when needed.
only the gitsync.xqm and the expanded.xqm modules, which deal with the data as entered in the db, should use titles.xqm
the expanded TEI will include those titles and names.
The views do not need to use this, and should instead get the information straight from the context of the expanded file, without checking lists or other files again :)

module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog.xqm";
import module namespace selectors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-selectors" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-selectors.xqm";
import module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-places" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog-places.xqm";
import module namespace cache = "http://exist-db.org/xquery/cache";

declare variable $exptit:col := collection($config:data-root);

declare variable $exptit:placeNamesList := doc("/db/apps/lists/placeNamesLabels.xml");

declare variable $exptit:institutionsList := doc("/db/apps/lists/institutions.xml");

declare variable $exptit:persNamesList := doc("/db/apps/lists/persNamesLabels.xml");

declare variable $exptit:TUList := doc("/db/apps/lists/textpartstitles.xml");

declare variable $exptit:deleted := doc("/db/apps/lists/deleted.xml");

declare variable $exptit:prefixDef := doc("/db/apps/lists/listPrefixDef.xml");

(:~
 : Shared works/persons/places/institutions title cache, written by
 : expand:file per document. Empty sequence until the cache document
 : exists (doc() on a missing db resource returns empty, not an error).
 :)
declare variable $exptit:titleCache := doc("/db/apps/lists/titleCache.xml");

(:~
 : Resolves a title for a node or a raw identifier of unknown shape -
 : an element (goes to its root's full title), a URI, or a bare id.
 : Callers can pass attribute nodes (e.g. from config:distinct-values
 : over a @ref sequence, which does not atomize its input here) as
 : well as plain strings, so every non-element branch returns
 : string($titleMe) rather than the raw item - an attribute node
 : surfacing unchanged into element content elsewhere would be
 : silently reattached as an attribute instead of serializing as text.
 : Every branch also falls back to the original identifier when
 : nothing resolves, rather than returning empty - a live-corpus smoke
 : test found the BMurl-prefixed branch missing this, leaving up to
 : ~14% of some dropdown options blank instead of showing the id.
 :
 : @param $titleMe an element, or an identifier (string or attribute)
 : @return the resolved title as a string, or node content for elements
 :)
declare function exptit:printTitle($titleMe) {
	if (count($titleMe) = 0 or $titleMe = "") then (
	) else
		(: titleable could a node or a string, and the string could be anything... :)
		typeswitch ($titleMe)
			case element() (: could be TEI or any other node, just go back to the top :) return
				let $resource := root($titleMe)
				return (: this is added by expanded.xql exptit relies on that :) $resource//t:title[@type = "full"]/text()

			default return
				(: the string could be really just anything, but in the expanded data, it will often be a URI, maybe prefixed with the official betmas URI. :)
				if (starts-with($titleMe, $config:BMurl)) then
					(: check if it is a local URI :)
					let $id := substring-after($titleMe, $config:BMurl)
					let $title := exptit:printTitleID($id)
					return if (string-length(string-join($title)) ge 1) then
						$title
					else
						string($titleMe)
				else if (contains($titleMe, "betmas:")) then
					(: it is a prefixed http thing, replace and treat it accordingly :)
					let $id := substring-after($titleMe, "betmas:")
					let $title := exptit:printTitleID($id)
					return if (string-length(string-join($title)) ge 1) then
						$title
					else
						string($titleMe)
				else if (starts-with($titleMe, "http")) then
					(: it is a URI, but not ours, best guess is just return it as is :)
					string($titleMe)
				(: perhaps it is just an identifier.... try to get the full title and if you do not find it, return what was submitted :)
				else
					let $title := exptit:printTitleID($titleMe)
					return if (string-length(string-join($title)) ge 1) then
						$title
					else
						string($titleMe)
};

(:~
 : Resolves a betmas identifier to its printable title. Checks a series
 : of special cases and caches (deleted items, sdc: refs, the shared
 : title cache written by expand:file, subtitle fragments after "#",
 : external wd:/gn:/pleiades: place refs) before falling back to a
 : live id() lookup against the expanded collection.
 :
 : @param $id a betmas identifier, optionally with a "#subid" suffix
 : @return the resolved title, or an HTML fallback marker if nothing
 : could be resolved
 :)
declare
	%test:arg("id", "sdc:UniCont1")
	%test:assertEquals("La Synthaxe du Codex UniCont1")
	%test:arg("id", "#")
	%test:assertEquals('&lt;span class="w3-tag w3-red"&gt;no item yet with id #&lt;/span&gt;')
	%test:arg("id", "")
	%test:assertEquals('&lt;span class="w3-tag w3-red"&gt;no id&lt;/span&gt;')
	%test:arg("id", "LIT2317Senodo#")
	%test:assertEquals("Senodos")
	%test:arg("id", "BNFet32")
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32")
	%test:arg("id", "LIT1367Exodus")
	%test:assertEquals("Exodus")
	%test:arg("id", "PRS11160HabtaS")
	%test:assertEquals("Habta Śǝllāse")
	%test:arg("id", "LOC1001Aallee")
	%test:assertEquals("Aallee")
(:
The following tests are also failing on the old system.
%test:arg('id', 'BNFet32#a2') %test:assertEquals('Paris, Bibliothèque nationale de France, BnF Éthiopien 32, Donation Note a2')
%test:arg('id', 'BNFet32#e1') %test:assertEquals('Paris, Bibliothèque nationale de France, BnF Éthiopien 32, no id e1')
%test:arg('id', 'LIT1367Exodus#Ex1') %test:assertEquals('Exodus, Exodus 1')
%test:arg('id', 'PRS5684JesusCh#n2') %test:assertEquals('Jesus Christ, Krǝstos')
 :)
function exptit:printTitleID($id as xs:string) {
	catalog:label($id, catalog:backend("exptit"))
};

declare function exptit:updateTUList($name, $pRef) {
	let $ref := if (contains($pRef, ".eu/")) then
		substring-after($pRef, ".eu/")
	else
		string($pRef)
	let $ensure-cache := cache:create("catalog-textpart-labels", map {"maximumSize": 10000, "expireAfterWrite": 86400})
	return cache:put("catalog-textpart-labels", $ref, $name)
};

(:~
 : Anchor label for an expanded-data node. The rule itself lives in
 : catalog-selectors.xqm and is shared with titlesData and the catalog
 : facade; only the id resolver differs.
 :)
declare function exptit:printSubtitle($node as node(), $SUBid as xs:string) as xs:string {
	selectors:subtitle(
		$node,
		$SUBid,
		map {
			"label": exptit:printTitleID#1,
			"text": function ($nodes as node()*) { $nodes/text() },
			"additio": false()
		}
	)
};

(:~
 : External and listed place labels resolve through the catalog contract, so
 : Web and API agree; see catalog-places.xqm. Kept as thin wrappers for the
 : existing call sites.
 :)
declare function exptit:decidePlaceNameSource($pRef as xs:string) {
	places:label($pRef)
};

declare function exptit:updatePlaceList($name, $pRef) {
	places:remember(string($pRef), $name)
};

declare function exptit:getGeoNames($string as xs:string) {
	places:geonames($string)
};

declare function exptit:getPleiadesNames($string as xs:string) {
	places:pleiades($string)
};

declare function exptit:getwikidataNames($pRef as xs:string) {
	places:wikidata($pRef)
};
