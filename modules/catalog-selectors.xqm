xquery version "3.1" encoding "UTF-8";

(:~
 : Pure TEI label selectors shared by expansion and the catalog facade.
 : Keep data access and caching out of this module so both callers apply
 : exactly the same label precedence rules.
 :)
module namespace selectors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-selectors";

declare namespace t = "http://www.tei-c.org/ns/1.0";

declare function selectors:normalize($nodes as node()*) as xs:string {
	normalize-space(string-join($nodes/string()))
};

declare function selectors:place-name($resource as node()) {
	let $place := $resource//t:place
	let $normalized := $place/t:placeName[@corresp = "#n1"][@type = "normalized"]
	let $english := $place/t:placeName[@corresp = "#n1"][@xml:lang = "en"]
	let $main := $place/t:placeName[@type = "main"]
	return if ($main) then
		string-join($main/text())
	else if ($normalized) then
		normalize-space(string-join($normalized/text(), " "))
	else if ($english) then
		normalize-space(string-join($english/text(), " "))
	else if ($place/t:placeName[@xml:id]) then
		normalize-space($place/t:placeName[@xml:id = "n1"]/text())
	else if ($place/t:placeName[text()][1]) then
		normalize-space($place/t:placeName[text()][1]/text())
	else
		$resource//t:titleStmt/t:title[text()]/text()
};

declare function selectors:person-name($resource as node()) {
	let $person := $resource//t:person
	let $group := $resource//t:personGrp
	let $main := $person/t:persName[@type = "main"]
	let $two-names := $person/t:persName[@xml:id = "n1"][t:forename or t:surname]
	let $gez := $person/t:persName[@corresp = "#n1"][@xml:lang = "gez"]
	let $english-normalized := $person/t:persName[@corresp = "#n1"][@xml:lang = "en"][@type = "normalized"]
	let $english := $person/t:persName[@corresp = "#n1"][@xml:lang = "en"]
	let $other := $person/t:persName[@corresp = "#n1"][@xml:lang[not(. = ("en", "gez"))]]
	let $group-names := $group/t:persName
	let $group-gez := $group/t:persName[@corresp = "#n1"][@xml:lang = "gez"]
	let $group-english := $group/t:persName[@corresp = "#n1"][@xml:lang = "en"][@type = "normalized"]
	return if ($two-names) then
		let $name := ($gez, $english-normalized, $other[1], $person/t:persName[@xml:id = "n1"], $person/t:persName[1])[1]
		return string-join(($name/t:forename/text(), $name/t:surname/text()), " ")
	else if ($group-names) then
		if ($group-gez) then
			$group-gez/text()
		else if ($group/t:persName[t:orgName]) then
			$group/t:persName[@xml:id = "n1"]/t:orgName/text()
		else if ($group-english) then
			$group-english
		else if ($group/t:persName[@xml:id]) then
			string-join($group/t:persName[@xml:id = "n1"]/text())
		else
			$group/t:persName[1]//text()
	else if ($main) then
		string-join($main/text())
	else if ($gez) then
		string-join($gez//text())
	else if ($english-normalized) then
		string-join($english-normalized//text())
	else if ($english) then
		string-join($english//text())
	else if ($other) then
		string-join($other[1]/text())
	else if ($person/t:persName[@xml:id]) then
		string-join($person/t:persName[@xml:id = "n1"]//text())
	else
		string-join($person/t:persName[1][text()]//text())
};

declare function selectors:work-title($resource as node()) {
	let $titles := $resource//t:titleStmt
	let $main := $titles/t:title[@type = "main"][@corresp = "#t1"][text()]
	let $amharic-arabic := $titles/t:title[@corresp = "#t1"][@xml:lang = ("am", "ar")]
	let $gez := $titles/t:title[@corresp = "#t1"][@xml:lang = "gez"]
	let $english := $titles/t:title[@corresp = "#t1"][@xml:lang = "en"]
	return if ($main) then
		selectors:normalize($main[1])
	else if ($amharic-arabic) then
		selectors:normalize($amharic-arabic[1])
	else if ($gez) then
		selectors:normalize($gez[1])
	else if ($english) then
		selectors:normalize($english[1])
	else if ($titles/t:title[@xml:id]) then
		selectors:normalize($titles/t:title[@xml:id = "t1"])
	else
		selectors:normalize($titles/t:title[1])
};

declare function selectors:manuscript-label(
	$resource as node(),
	$repository-name as xs:string?,
	$repository-place as xs:string?
) as xs:string {
	if ($resource//t:objectDesc[@form = "Inscription"]) then
		string($resource//t:msIdentifier/t:idno)
	else if ($resource//t:repository/text() = "Lost") then
		"Lost. " || string($resource//t:msIdentifier/t:idno)
	else if ($resource//t:repository/@ref and $resource//t:msDesc/t:msIdentifier/t:idno/text()) then
		normalize-space(
			($repository-place, "No location record")[1] ||
				", " ||
				($repository-name, "No Institution record")[1] ||
				", " ||
				string($resource//t:msDesc/t:msIdentifier/t:idno[1])
		)
	else
		"no repository data for " || string($resource/ancestor-or-self::t:TEI/@xml:id)
};
