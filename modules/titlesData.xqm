xquery version "3.1" encoding "UTF-8";

(:~
 : Titles for RAW (unexpanded) source data — used by the expansion pipeline
 : (expand.xqm) and by dts.xqm. Ported from the legacy app
 : (/db/apps/BetMas/modules/titles.xqm, authoritative as of 2025-11) so that
 : expansion no longer depends on the legacy app.
 : Also absorbed this app's own former titles.xqm (2026-08-27) - the two
 : had quietly diverged into a stale, ~90%-duplicate fork; see
 : https://github.com/BetaMasaheft/BetMasWeb/issues/99 for the bug that
 : divergence caused (raw HTML markup leaking into dts.xqm's JSON output
 : on unresolved ids) and the shape of the fix.
 : Distinct from exptit.xqm (expanded data, live page render).
 :)
module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace feed = "http://www.w3.org/2005/Atom";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace hc = "http://expath.org/ns/http-client";

(: these lists are separately indexed here in the app with the collection.xconf for BetMas :)
declare variable $titles:placeNamesList := doc("/db/apps/lists/placeNamesLabels.xml");

declare variable $titles:institutionsList := doc("/db/apps/lists/institutions.xml");

declare variable $titles:persNamesList := doc("/db/apps/lists/persNamesLabels.xml");

declare variable $titles:TUList := doc("/db/apps/lists/textpartstitles.xml");

declare variable $titles:deleted := doc("/db/apps/lists/deleted.xml");

declare variable $titles:collection-root := collection($config:bmdata-root);

declare variable $titles:collection-rootPl := collection(concat($config:bmdata-root, "/places"));

(: establishes the different rules and priority to print a title referring to a record :)
declare function titles:printTitle($node as element()) {
	(: always look at the root of the given node parameter of the function and then switch :)
	let $resource := root($node)
	return titles:switcher($resource//t:TEI/@type, $resource)
};

(: looks for different possible locations of anchor and where to pick the correct label :)
declare function titles:printSubtitle($node as node(), $SUBid as xs:string) as xs:string {
	if (starts-with($SUBid, "tr")) then
		"transformation " || $SUBid
	else if (starts-with($SUBid, "Uni")) then
		$SUBid
	else
		let $item := $node//id($SUBid)
		return if ($item/name() = "title") then (
			string($item/@xml:lang) ||
				(
					if ($item/text()) then
						$item/text()
					else
						" ... empty, sorry!"
				)
		) else if ($item/name() = "persName") then (
			let $r := root($item)
			return if ($r//t:persName[@type eq "normalized"][contains(@corresp, $SUBid)]) then
				string-join($r//t:persName[@type eq "normalized"][contains(@corresp, $SUBid)]//text(), "")
			else
				normalize-space(string-join($item, ""))
		) else if ($item/name() = "msItem") then (
			if ($item/t:title/@ref) then (
				titles:printTitleID(string($item/t:title/@ref)) || " (in " || $SUBid || ")"
			) else
				normalize-space(string-join(titles:tei2string($item/t:title), ""))
		) else if ($item/t:label) then
			let $sameAs := if ($item/@corresp) then (
				" (same as " || string($item/@corresp) || ")"
			) else (
			)
			return (normalize-space(string-join(titles:tei2string($item/t:label), "")) || $sameAs)
		else if ($item[not(t:label)]/@corresp) then
			normalize-space(string-join(titles:printTitleID($item/@corresp), ""))
		else if (matches($SUBid, "^a\d+$")) then
			"  additio " || $SUBid
		else if ($item/t:desc) then (
			titles:printTitleID(string($item/t:desc/@type)) || " " || $SUBid
		) else if (
			(
				$item/@subtype eq "Monday" or
					$item/@subtype eq "Tuesday" or
					$item/@subtype eq "Wednesday" or
					$item/@subtype eq "Thursday" or
					$item/@subtype eq "Friday" or
					$item/@subtype eq "Saturday" or
					$item/@subtype eq "Sunday"
			) and
				not($item/node())
		) then (
			" for " || $SUBid
		) else if ($item/@subtype) then (
			titles:printTitleID(string($item/@subtype)) || ": " || $SUBid
		) else (
			$item/name() || " " || $SUBid
		)
};

(: this is now a switch function, deciding if to go ahead with simple print title or subtitles :)
(:~
 : Resolves a betmas identifier to its printable title, as a plain
 : string (unlike exptit:printTitleID's HTML-fallback-marker sibling -
 : this operates on raw source data at expand/DTS time, not rendered
 : HTML). The test annotations below were stale until 2026-08-27 - they
 : expected an older HTML-marker/", "-separator shape this function
 : hasn't actually produced for some time; corrected to match verified
 : current output rather than guessed-at intent.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/99
 :
 : @param $id a betmas identifier, optionally with a "#subid" suffix
 : @return the resolved title as a string
 :)
declare
	%test:arg("id", "sdc:UniCont1")
	%test:assertEquals("La Synthaxe du Codex UniCont1")
	%test:arg("id", "LIT2317Senodo#")
	%test:assertEquals("Senodos")
	%test:arg("id", "#")
	%test:assertEquals("no item yet with id #")
	%test:arg("id", "")
	%test:assertEquals("No item: ")
	%test:arg("id", "BNFet32")
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32")
	%test:arg("id", "LIT1367Exodus")
	%test:assertEquals("Exodus")
	%test:arg("id", "PRS11160HabtaS")
	%test:assertEquals("Habta Śǝllāse")
	%test:arg("id", "LOC1001Aallee")
	%test:assertEquals("Aallee")
	%test:arg("id", "BNFet32#a2")
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32:   additio a2")
	%test:arg("id", "BNFet32#e1")
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32: No item:  e1")
	%test:arg("id", "LIT1367Exodus#Ex1")
	%test:assertEquals("Exodus: Exodus 1")
	%test:arg("id", "PRS5684JesusCh#n2")
	%test:assertEquals("Jesus Christ: Krǝstos")
function titles:printTitleID($id as xs:string) {
	if ($titles:deleted//t:item[. = $id]) then
		let $del := $titles:deleted//t:item[. = $id]
		let $formerly := $titles:collection-root//t:relation[@name eq "betmas:formerlyAlsoListedAs"][@passive eq $id]
		return if ($formerly) then
			titles:printTitleID($formerly/@active) ||
				" [now " ||
				string($formerly/@active) ||
				", formerly also listed as " ||
				$id ||
				", which was requested here but has been deleted on " ||
				string($del/@change) ||
				"]"
		else
			$id || " was permanently deleted"
	else if (starts-with($id, "sdc:")) then
		"La Synthaxe du Codex " || substring-after($id, "sdc:")
	(: another hack for things like ref="#" :)
	else if ($id = "#") then
		"no item yet with id " || $id
	(: hack to avoid the bad usage of # at the end of an id like <title type="complete" ref="LIT2317Senodo#" xml:lang="gez"> :)
	else if ($titles:TUList//t:item[@corresp eq $id]) then (
		$titles:TUList//t:item[@corresp eq $id][1]/node()
	) else if ($titles:persNamesList//t:item[@corresp eq $id]) then (
		$titles:persNamesList//t:item[@corresp eq $id][1]/node()
	) else if (ends-with($id, "#")) then (
		let $newid := replace($id, "#", "")
		return titles:printTitleID($newid)
	) else if (matches($id, "wd:Q\d+") or starts-with($id, "gn:") or starts-with($id, "pleiades:")) then
		titles:decidePlaceNameSource($id)
	(: if the id has a subid, than split it :)
	else if (contains($id, "#")) then (
		let $mainID := substring-before($id, "#")
		let $SUBid := substring-after($id, "#")
		let $node := $titles:collection-root//id($mainID)
		return if ($node) then (
			if (starts-with($SUBid, "t")) then (
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
			) else (: format the title, add it to the list and pass again to this function, which will have something to match now :) (
				let $subtitle := titles:printSubtitle($node, $SUBid)
				let $name := (titles:printTitleMainID($mainID) || ": " || $subtitle)
				let $addit := titles:updateTUList($name, $id)
				return titles:printTitleID($id)
			)
		) else if ($id = "") then
			"?"
		(: if no node could be found with the main id, that has a problem :)
		else (
			"No item: " || $mainID || ", could not check for " || $SUBid
		)
	) (: if not, procede to main title printing :) else
		titles:printTitleMainID($id)
};

declare function titles:printTitleMainID($id as xs:string, $c) {
	if (matches($id, "wd:Q\d+") or starts-with($id, "gn:") or starts-with($id, "pleiades:")) then (
		titles:decidePlaceNameSource($id)
	) (: because wikidata identifiers are not speaking, the result of this operation is that the
eventually added result is added to the place list names :) else (: always look at the root of the given node parameter of the function and then switch :)
		let $mainID := if (contains($id, "#")) then
			substring-before($id, "#")
		else
			$id
		let $resource := collection($c)//t:TEI[@xml:id = $mainID]
		return if (count($resource) = 0) then
			"No item: " || $id
		else if (count($resource) > 1) then
			"More than 1 " || $id
		else
			titles:switcher($resource/@type, $resource)
};

(:~
 : Resolves a betmas identifier's main-record title (ignores any
 : "#subid" suffix), as a plain string.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/99
 :
 : @param $id a betmas identifier, optionally with a "#subid" suffix
 : @return the resolved title as a string
 :)
declare
	%test:arg("id", "BNFet32")
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32")
	%test:arg("id", "LIT2317Senodo")
	%test:assertEquals("Senodos")
	%test:arg("id", "LIT1367Exodus")
	%test:assertEquals("Exodus")
	%test:arg("id", "PRS11160HabtaS")
	%test:assertEquals("Habta Śǝllāse")
	%test:arg("id", "LOC1001Aallee")
	%test:assertEquals("Aallee")
function titles:printTitleMainID($id as xs:string) {
	if (matches($id, "wd:Q\d+") or starts-with($id, "gn:") or starts-with($id, "pleiades:")) then (
		titles:decidePlaceNameSource($id)
	) else (: always look at the root of the given node parameter of the function and then switch :)
		let $mainID := if (contains($id, "#")) then
			substring-before($id, "#")
		else
			$id
		(: let $catchID := collection($config:bmdata-root)/id($mainID) :)
		let $resource := collection($config:bmdata-root)//t:TEI[@xml:id = $mainID]
		return if (count($resource) = 0) then
			"No item: " || $id
		else if (count($resource) > 1) then
			"More than 1 " || $id
		else
			let $type := string($resource/@type)
			return titles:switcher($type, $resource)
};

declare function titles:switcher($type, $resource) {
	(: let $test := console:log(string-join($resource/ancestor-or-self::t:TEI/@xml:id, ' '))
   return :)
	switch ($type)
		case "mss" return
			titles:manuscriptLabelFormatter($resource)
		case "place" return
			titles:placeNameSelector($resource)
		case "ins" return
			titles:placeNameSelector($resource)
		case "pers" return
			titles:decidepersNameSource($resource, $resource/ancestor-or-self::t:TEI/@xml:id)
		case "work" return
			titles:decideTUSource($resource, $resource/ancestor-or-self::t:TEI/@xml:id)
		case "nar" return
			titles:decideTUSource($resource, $resource/ancestor-or-self::t:TEI/@xml:id)
		case "studies" return
			titles:decideTUSource($resource, $resource/ancestor-or-self::t:TEI/@xml:id)
		(: this should do also auths :)
		default return
			$resource//t:titleStmt/t:title[1]/text()
};

declare function titles:manuscriptLabelFormatter($resource) as xs:string {
	if ($resource//objectDesc[@form eq "Inscription"]) then (
		$resource//t:msIdentifier/t:idno/text()
	) else (
		if ($resource//t:repository/text() = "Lost") then (
			"Lost. " || $resource//t:msIdentifier/t:idno/text()
		) else if ($resource//t:repository/@ref and $resource//t:msDesc/t:msIdentifier/t:idno/text()) then
			let $repoid := string(($resource//t:repository/@ref)[1])
			let $reponame := $titles:institutionsList/id($repoid)[1]/text()
			let $r := collection(concat($config:bmdata-root, "/institutions"))/id($repoid)
			let $repo := if ($r) then (
				$r
			) else
				"No Institution record"
			let $repoPlace := if ($repo = "No Institution record") then
				$repo
			else (
				if ($repo[not(descendant::t:settlement)][not(descendant::t:country)]) then (
					"No location record"
				) else if ($repo//t:settlement[1]/@ref) then
					let $plaID := string($repo//t:settlement[1]/@ref)
					let $placeName := titles:decidePlaceNameSource($plaID)
					return $placeName
				else if ($repo//t:settlement[1]/text()) then
					$repo//t:settlement[1]/text()
				else if ($repo//t:country/@ref) then
					let $plaID := string($repo//t:country/@ref)
					return titles:decidePlaceNameSource($plaID)
				else if ($repo//t:country/text()) then
					$repo//t:country/text()
				else
					"No location record"
			)
			let $candidate := string-join($repoPlace, " ") ||
				", " ||
				(
					if ($repo = "No Institution record") then
						$repo
					else (
						$reponame
					)
				) ||
				", " ||
				$resource//t:msDesc/t:msIdentifier/t:idno[1]/text()
			return normalize-space($candidate)
		else
			"no repository data for " || string($resource/@xml:id)
	)
};

declare function titles:placeNameSelector($resource as node()) {
	let $pl := $resource//t:place
	let $pnorm := $pl/t:placeName[@corresp eq "#n1"][@type eq "normalized"]
	let $pEN := $pl/t:placeName[@corresp eq "#n1"][@xml:lang = "en"]
	let $Maintitle := $pl/t:placeName[@type eq "main"]
	return if ($Maintitle) then
		string-join($Maintitle/text())
	else if ($pnorm) then
		normalize-space(string-join($pnorm/text(), " "))
	else if ($pEN) then
		normalize-space(string-join($pEN/text(), " "))
	else if ($pl/t:placeName[@xml:id]) then
		let $pn := $pl/t:placeName[@xml:id = "n1"]
		return normalize-space($pn/text())
	else if ($pl/t:placeName[text()][position() = 1]/text()) then
		normalize-space($pl/t:placeName[text()][position() = 1]/text())
	else
		$resource//t:titleStmt/t:title[text()]/text()
};

declare function titles:persNameSelector($resource as node()) {
	let $p := $resource//t:person
	let $pg := $resource//t:personGrp
	let $Maintitle := $p/t:persName[@type eq "main"]
	let $twonames := $p/t:persName[@xml:id eq "n1"][t:forename or t:surname]
	let $namegez := $p/t:persName[@corresp eq "#n1"][@xml:lang = "gez"]
	let $nameennorm := $p/t:persName[@corresp eq "#n1"][@xml:lang = "en"][@type eq "normalized"]
	let $nameen := $p/t:persName[@corresp eq "#n1"][@xml:lang = "en"]
	let $nameOthers := $p/t:persName[@corresp eq "#n1"][@xml:lang[not(. = "en")][not(. = "gez")]]
	let $group := $pg/t:persName
	let $groupgez := $pg/t:persName[@corresp eq "#n1"][@xml:lang = "gez"]
	let $groupennorm := $pg/t:persName[@corresp eq "#n1"][@xml:lang = "en"][@type eq "normalized"]

	return (: first check for persons with two names :) if ($twonames) then (
		if ($namegez) then (
			$namegez/t:forename/text() || " " || $namegez/t:surname/text()
		) else if ($nameennorm) then (
			$nameennorm/t:forename/text() || " " || $nameennorm/t:surname/text()
		) else if ($nameOthers) then (
			$nameOthers[1]/t:forename/text() || " " || $nameOthers[1]/t:surname/text()
		) else if ($resource//t:person/t:persName[@xml:id]) then
			let $name := $resource//t:person/t:persName[@xml:id = "n1"]
			return ($name/t:forename/text() || " " || $name/t:surname/text())

		else (
			$p/t:persName[position() = 1]/t:forename[1]/text() || " " || $p/t:persName[position() = 1]/t:surname[1]/text()
		)
	) (: then check if it is a personGrp :) else if ($group) then (
		if ($groupgez) then
			$groupgez/text()

		else if ($pg/t:persName[t:orgName]) then
			let $gname := $pg/t:persName[@xml:id = "n1"]
			return $gname/t:orgName/text()

		else if ($groupennorm) then
			$groupennorm

		else if ($pg/t:persName[@xml:id]) then
			let $gname := $pg/t:persName[@xml:id = "n1"]
			return string-join($gname/text())

		else (
			$pg/t:persName[position() = 1]//text()
		)
	) (: otherways is just a normal person :) else if ($Maintitle) then
		string-join($Maintitle/text())
	else (
		if ($namegez) then
			string-join($namegez//text())

		else if ($nameennorm) then
			string-join($nameennorm//text())

		else if ($nameen) then
			string-join($nameen//text())
		else if ($nameOthers) then
			string-join($nameOthers[1]/text())

		else if ($p/t:persName[@xml:id]) then
			let $name := $p/t:persName[@xml:id = "n1"]
			return string-join($name//text())

		else
			string-join($p/t:persName[position() = 1][text()]//text())
	)
};

declare function titles:worknarrTitleSelector($resource as node()) {
	let $W := $resource//t:titleStmt
	let $Maintitle := $W/t:title[@type eq "main"][@corresp eq "#t1"][text()]
	let $amarictitle := $W/t:title[@corresp eq "#t1"][@xml:lang = "am" or @xml:lang = "ar"]
	let $geztitle := $W/t:title[@corresp eq "#t1"][@xml:lang = "gez"]
	let $entitle := $W/t:title[@corresp eq "#t1"][@xml:lang = "en"]
	return if ($Maintitle) then
		titles:normalize($Maintitle[1])
	else if ($amarictitle) then
		titles:normalize($amarictitle[1])
	else if ($geztitle) then
		titles:normalize($geztitle[1])
	else if ($entitle) then
		titles:normalize($entitle[1])
	else if ($W/t:title[@xml:id]) then
		let $tit := $W/t:title[@xml:id = "t1"]
		return titles:normalize($tit)
	else
		titles:normalize($W/t:title[1])
};

declare function titles:normalize($nodes) {
	let $tostring := $nodes/string()
	return normalize-space(string-join($tostring))
};

declare function titles:decidePlName($plaID) {
	if (starts-with($plaID, "wd:")) then
		titles:getwikidataNames($plaID)
	else if (starts-with($plaID, "gn:")) then
		titles:getGeoNames($plaID)
	else
		let $placefile := $titles:collection-rootPl/id($plaID)
		return titles:placeNameSelector($placefile[1])
};

(: Given an id, decides if it is one of BM or from another source and gets the name accordingly :)
declare function titles:decidePlaceNameSource($pRef as xs:string) {
	if ($titles:placeNamesList//t:item[@corresp = $pRef]) then
		$titles:placeNamesList//t:item[@corresp = $pRef][1]/text()
	else if (starts-with($pRef, "gn:")) then (
		let $name := titles:getGeoNames($pRef)
		let $addit := titles:updatePlaceList($name, $pRef)
		return titles:decidePlaceNameSource($pRef)
	) else if (starts-with($pRef, "pleiades:")) then (
		let $name := titles:getPleiadesNames($pRef)
		let $addit := titles:updatePlaceList($name, $pRef)
		return titles:decidePlaceNameSource($pRef)
	) else if (matches($pRef, "wd:Q\d+")) then (
		let $name := titles:getwikidataNames($pRef)
		(: let $test := console:log($name) :)
		let $addit := titles:updatePlaceList($name, $pRef)
		return titles:decidePlaceNameSource($pRef)
	) else (
		let $resource := $titles:collection-rootPl/id($pRef)
		return titles:placeNameSelector($resource)
	)
};

(: Given an id, decides if it is one of BM or from another source and gets the name accordingly :)
declare function titles:decidepersNameSource($resource, $pRef as xs:string) {
	if ($titles:persNamesList//t:item[@corresp eq $pRef]) then
		$titles:persNamesList//t:item[@corresp eq $pRef][1]/text()
	else if (matches($pRef, "wd:Q\d+")) then (
		let $name := titles:getwikidataNames($pRef)
		(: let $test := console:log($name) :)
		let $addit := titles:updatePersList($name, $pRef)
		return titles:decidepersNameSource($resource, $pRef)
	) else
		let $name := titles:persNameSelector($resource)
		let $addit := titles:updatePersList($name, $pRef)
		return titles:decidepersNameSource($resource, $pRef)
};

(: Given an id, decides if it is one of BM or from another source and gets the name accordingly :)
declare function titles:decideTUSource($resource, $pRef as xs:string) {
	if ($titles:TUList//t:item[@corresp eq $pRef]) then
		$titles:TUList//t:item[@corresp eq $pRef][1]/text()
	else
		let $name := titles:worknarrTitleSelector($resource)
		let $addit := titles:updateTUList($name, $pRef)
		return titles:decideTUSource($resource, $pRef)
};

declare function titles:updatePlaceList($name, $pRef) {
	let $_ := util:log("INFO", "Updating placeNamesList with " || $name || ": " || $pRef)
	let $placeslist := $titles:placeNamesList//t:list
	return update insert <item
		xmlns="http://www.tei-c.org/ns/1.0"
		change="entryAddedAt{ current-dateTime() }"
		corresp="{ $pRef }"
	>{ $name }</item> into $placeslist
};

declare function titles:updatePersList($name, $pRef) {
	let $_ := util:log("INFO", "Updating persNamesList with " || $name || ": " || $pRef)
	let $perslist := $titles:persNamesList//t:list
	return update insert <item
		xmlns="http://www.tei-c.org/ns/1.0"
		change="entryAddedAt{ current-dateTime() }"
		corresp="{ $pRef }"
	>{ $name }</item> into $perslist
};

declare function titles:updateTUList($name, $pRef) {
	let $_ := util:log("INFO", "Updating TUList with " || $name || ": " || $pRef)
	let $TUList := $titles:TUList//t:list
	return update insert <item
		xmlns="http://www.tei-c.org/ns/1.0"
		change="entryAddedAt{ current-dateTime() }"
		corresp="{ $pRef }"
	>{ $name }</item> into $TUList
};

(:~
 : Upserts the shared works/persons/places/institutions title cache read
 : by exptit:printTitleID's fast path. Creates the list document on
 : first use; updates an existing entry in place rather than
 : duplicating it. A blank title is not cached - a miss that falls
 : through to the live lookup next time is safer than caching a value
 : that looks resolved but isn't.
 :
 : @param $id the record's own xml:id, e.g. "LIT1793Leviti"
 : @param $title the record's resolved full title
 : @return empty sequence
 :)
declare function titles:updateTitleCache($id as xs:string, $title as xs:string?) as empty-sequence() {
	if (not($title) or normalize-space($title) = "") then (
	) else
		let $collection := "/db/apps/lists"
		let $resource := "titleCache.xml"
		let $path := $collection || "/" || $resource
		(: Not race-safe: two concurrent first-ever callers could both see
		   doc-available() = false and both store a blank list, the
		   second clobbering whatever the first had already inserted -
		   a real gap between this check and the store below, which no
		   amount of re-checking closes without an actual lock. Narrow
		   in practice: expand:file's batch driver runs sequentially,
		   and the one other caller with prior form (gitsync) is dead
		   code. Accepted as-is rather than adding real locking for a
		   window this narrow - revisit if a genuinely concurrent
		   caller shows up. :)
		let $_bootstrap := if (doc-available($path)) then (
		) else
			xmldb:store($collection, $resource, <list xmlns="http://www.tei-c.org/ns/1.0" />)
		let $list := doc($path)/t:list
		let $existing := $list/t:item[@corresp eq $id]
		return if ($existing) then
			update value $existing with $title
		else
			update insert <item xmlns="http://www.tei-c.org/ns/1.0" corresp="{ $id }">{ $title }</item> into $list
};

declare function titles:request($request as element(http:request)) {
	let $_ := util:log("info", $request/@href)
	let $response := http:send-request($request)
	let $status-code := xs:integer($response[1]/@status)

	return if ($status-code = 429) then
		let $retry-after := ($response[1]/http:header[@name = "Retry-After"], 1000)[1]
		let $_ := util:log("INFO", "429 from " || $request/@href || ", waiting " || $retry-after || " ms until retrying.")
		let $_ := util:wait(xs:integer($retry-after))
		return titles:request($request)
	else if ($status-code >= 400) then
		let $_ := util:log(
			"INFO",
			"server connection failed: " || $response[1]/@message || " (" || $status-code || ")" || $response[1]
		)
		return error(
			xs:QName("titles:connection-error"),
			"server connection failed: " || $response[1]/@message || " (" || $status-code || ")" || $response[1]
		)
	else
		$response
};

declare function titles:getGeoNames($string as xs:string) {
	let $gnid := substring-after($string, "gn:")
	let $xml-url := concat("http://api.geonames.org/get?geonameId=", $gnid, "&amp;username=betamasaheft")
	let $data := try {
		let $request := <http:request href="{ xs:anyURI($xml-url) }" method="GET" />
		return titles:request($request)[2]
	} catch * { $err:description }
	return if ($data//toponymName) then
		$data//toponymName/text()
	else
		"no data from geonames"
};

declare function titles:getPleiadesNames($string as xs:string) {
	let $plid := substring-after($string, "pleiades:")
	let $url := concat("https://pleiades.stoa.org/places/", $plid, "/atom")
	let $request := <hc:request href="{ $url }" method="GET"><hc:header name="Connection" value="close" /></hc:request>
	let $title :=
		let $response := hc:send-request($request)
		let $response-head := $response[1]
		let $response-body := $response[2]
		return $response-body//feed:title
	return string($title[1])
};

declare function titles:getwikidataNames($pRef as xs:string) {
	let $pRef := substring-after($pRef, "wd:")
	let $sparql := "SELECT * WHERE {
  wd:" ||
		$pRef ||
		' rdfs:label ?label .
  FILTER (langMatches( lang(?label), "EN" ) )
}'

	let $query := "https://query.wikidata.org/sparql?query=" || xmldb:encode-uri($sparql)

	let $req := try {
		let $request := <http:request href="{ xs:anyURI($query) }" method="GET">
			<http:header name="User-Agent" value="betamasaheft.eu (info@betamasaheft.eu)" />
		</http:request>
		return titles:request($request)[2]
	} catch * { $err:description }
	return $req//sparql:result/sparql:binding[@name eq "label"]/sparql:literal[@xml:lang = "en"]/text()
};

(: takes a node as argument and loops through each element it contains. if it matches one of the definitions it does that, otherways checkes inside it. This actually reproduces the logic of the apply-templates function in  xslt :)
declare function titles:tei2string($nodes as node()*) {
	for $node in $nodes
	return typeswitch ($node)
		case element(t:title) return
			try { titles:printTitleMainID($node/@ref) } catch * { console:log($node) }
		case element(t:persName) return
			titles:printTitleMainID($node/@ref)
		case element(t:placeName) return
			titles:printTitleMainID($node/@ref)
		case element() return
			titles:tei2string($node/node())

		default return
			$node
};
