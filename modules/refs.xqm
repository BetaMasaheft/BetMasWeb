xquery version "3.1" encoding "UTF-8";

(:~
 : Canonical BMurl for pointer equality probes.
 :
 : Stored ref/corresp values are BMurl strings; range fields (persref, …)
 : want a single `@ref eq $key`. Bare xml:id callers canonicalize once —
 : do not probe bare+URI with general comparison (measured tax).
 :)
module namespace refs = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/refs";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

(:~
 : One lookup key: keep http(s) as-is (including BMurl); otherwise prefix BMurl.
 :)
declare function refs:canonical($id as xs:string) as xs:string {
	let $given := normalize-space($id)
	return if ($given = "") then
		""
	else if (matches($given, "^https?://")) then
		$given
	else
		$config:BMurl || $given
};

declare function refs:persName($col as node()*, $id as xs:string) as element(t:persName)* {
	$col//t:persName[@ref eq refs:canonical($id)]
};

declare function refs:placeName($col as node()*, $id as xs:string) as element(t:placeName)* {
	$col//t:placeName[@ref eq refs:canonical($id)]
};

declare function refs:title($col as node()*, $id as xs:string) as element(t:title)* {
	$col//t:title[@ref eq refs:canonical($id)]
};
