xquery version "3.1" encoding "UTF-8";

(:~
 : refs:canonical + helpers — single BMurl key, value eq (parity with stored refs).
 :)
module namespace tsrefs = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-refs";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace refs = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/refs" at "../../modules/refs.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "../../modules/apprest.xqm";

declare
	%test:name("refs:canonical bare becomes BMurl") %test:assertEquals("https://betamasaheft.eu/PRS4805Grebaut")
function tsrefs:canonical-bare() {
	refs:canonical("PRS4805Grebaut")
};

declare
	%test:name("refs:canonical keeps BMurl") %test:assertEquals("https://betamasaheft.eu/PRS4805Grebaut")
function tsrefs:canonical-uri() {
	refs:canonical("https://betamasaheft.eu/PRS4805Grebaut")
};

declare
	%test:name("refs:persName(bare) equals eq on canonical uri") %test:assertTrue
function tsrefs:persName-bare-vs-eq-uri() {
	let $col := collection("/db/apps/expanded")
	let $uri := $config:BMurl || "PRS4805Grebaut"
	let $new := refs:persName($col, "PRS4805Grebaut")
	let $old := $col//t:persName[@ref eq $uri]
	return count($new) gt 0 and count($new) = count($old) and (every $n in $new satisfies $n = $old)
};

declare
	%test:name("refs:persName(bare) equals former ends-with count") %test:assertTrue
function tsrefs:persName-vs-ends-with-count() {
	let $col := collection("/db/apps/expanded")
	let $bare := "PRS4805Grebaut"
	return count(refs:persName($col, $bare)) = count($col//t:persName[ends-with(@ref, $bare)])
};

declare
	%test:name("RestPersRole mss shape: canonical eq matches direct eq") %test:assertTrue
function tsrefs:restpersrole-mss-shape() {
	let $col := collection("/db/apps/expanded")
	let $msid := "BNFet102"
	let $refid := $config:BMurl || "PRS4805Grebaut"
	let $new := refs:persName($col, $refid)[@role][ancestor::t:TEI/@xml:id != $msid]
	let $old := $col//t:persName[@ref eq $refid][@role][ancestor::t:TEI/@xml:id != $msid]
	return count($new) = count($old) and (every $n in $new satisfies $n = $old)
};

declare
	%test:name("WhatPointsHere(uri) equals inline eq probes") %test:assertTrue
function tsrefs:whatpointshere-uri-parity() {
	let $col := collection("/db/apps/expanded")
	let $id := $config:BMurl || "PRS4805Grebaut"
	let $new := apprest:WhatPointsHere($id, $col)
	let $old := (
		$col//t:witness[@corresp eq $id],
		$col//t:placeName[@ref eq $id],
		$col//t:persName[@ref eq $id],
		$col//t:ref[@corresp eq $id],
		$col//t:title[@ref eq $id],
		$col//t:settlement[@ref eq $id],
		$col//t:region[@ref eq $id],
		$col//t:country[@ref eq $id],
		$col//t:relation[@active eq $id],
		$col//t:relation[@passive eq $id],
		$col//t:locus[@corresp eq $id]
	)
	return count($new) = count($old) and (every $n in $new satisfies $n = $old)
};

declare
	%test:name("WhatPointsHere(bare) equals WhatPointsHere(uri)") %test:assertTrue
function tsrefs:whatpointshere-bare-equals-uri() {
	let $col := collection("/db/apps/expanded")
	let $bare := "PRS4805Grebaut"
	let $uri := $config:BMurl || $bare
	let $a := apprest:WhatPointsHere($bare, $col)
	let $b := apprest:WhatPointsHere($uri, $col)
	return count($a) = count($b) and (every $n in $a satisfies $n = $b)
};
