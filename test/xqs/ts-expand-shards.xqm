xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for expand shard listing (expanded#40).
 :)
module namespace tsexpshards = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-shards";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace expandShards = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/expandShards" at "../../modules/expand-shards.xqm";
import module namespace router = "http://e-editiones.org/roaster/router";
import module namespace rutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/rutil" at "../../modules/roaster-util.xqm";

declare variable $tsexpshards:root := "/db/apps/BetMasData/_shardListFx";

declare variable $tsexpshards:del-data := "/db/apps/BetMasData/_delFx";

declare variable $tsexpshards:del-expanded := "/db/apps/expanded/_delFx";

declare %private function tsexpshards:remove-if-exists($col as xs:string) {
	if (xmldb:collection-available($col)) then
		try { xmldb:remove($col) } catch * { () }
	else (
	)
};

declare %private function tsexpshards:mkdirs($parent as xs:string, $rel as xs:string) as xs:string {
	fold-left(
		tokenize($rel, "/"),
		$parent,
		function ($acc, $name) {
			if (xmldb:collection-available($acc || "/" || $name)) then
				$acc || "/" || $name
			else
				xmldb:create-collection($acc, $name)
		}
	)
};

declare %private function tsexpshards:seed() {
	let $_rm := tsexpshards:remove-if-exists($tsexpshards:root)
	let $_root := xmldb:create-collection("/db/apps/BetMasData", "_shardListFx")
	for $rel in
		(
			"works/1-1000",
			"works/new",
			"persons/alpha",
			"persons/new",
			"places/Africa",
			"institutions/Ethiopia",
			"manuscripts/Pistoia",
			"manuscripts/OtherRepo",
			"manuscripts/build",
			"manuscripts/EMML/1-1000",
			"manuscripts/EMML/1001-2000",
			"narratives/story",
			"narratives/new",
			"studies/article",
			"authority-files/IHA",
			"authority-files/new",
			"corpora/one"
		)
	return tsexpshards:mkdirs($tsexpshards:root, $rel)
};

declare %test:tearDown function tsexpshards:tearDown() {
	tsexpshards:remove-if-exists($tsexpshards:root),
	tsexpshards:remove-if-exists($tsexpshards:del-data),
	tsexpshards:remove-if-exists($tsexpshards:del-expanded)
};

declare %private function tsexpshards:paths($mode as xs:string, $collection as xs:string?) as xs:string* {
	let $_ := tsexpshards:seed()
	return expandShards:paths($mode, $collection, $tsexpshards:root)
};

declare %test:assertTrue function tsexpshards:hybrid-splits-emml-and-skips-build() {
	let $shards := tsexpshards:paths("hybrid", ())
	return $shards = "manuscripts/Pistoia" and
		$shards = "manuscripts/EMML/1-1000" and
		$shards = "manuscripts/EMML/1001-2000" and
		$shards = "manuscripts/OtherRepo" and
		not($shards = "manuscripts/EMML") and
		not($shards = "manuscripts/build") and
		$shards = "works/1-1000" and
		$shards = "works/new" and
		$shards = "narratives" and
		not($shards = "narratives/story") and
		not($shards = "narratives/new") and
		$shards = "corpora" and
		$shards = "authority-files" and
		not($shards = "authority-files/new") and
		not($shards = "authority-files/IHA")
};

declare %test:assertTrue function tsexpshards:l1-appends-reservation-shards() {
	let $shards := tsexpshards:paths("l1", ())
	return $shards = "narratives/story" and
		$shards = "narratives/new" and
		$shards = "authority-files/IHA" and
		not($shards = "authority-files/new") and
		$shards = "works/new" and
		$shards = "manuscripts/Pistoia" and
		not($shards = "manuscripts/build") and
		not($shards = "narratives") and
		$shards = "corpora"
};

declare %test:assertTrue function tsexpshards:matrix-emits-corpus-roots() {
	let $shards := tsexpshards:paths("matrix", ())
	return $shards = "works" and
		$shards = "manuscripts" and
		$shards = "corpora" and
		not($shards = "works/1-1000") and
		not($shards = "manuscripts/Pistoia") and
		not($shards = "works/new")
};

declare %test:assertTrue function tsexpshards:filter-emml-expands-to-l2() {
	let $shards := tsexpshards:paths("hybrid", "manuscripts/EMML")
	return $shards = "manuscripts/EMML/1-1000" and
		$shards = "manuscripts/EMML/1001-2000" and
		not($shards = "manuscripts/EMML") and
		not($shards = "manuscripts/Pistoia")
};

(: CI used to special-case the exact string manuscripts/EMML. :)
declare %test:assertTrue function tsexpshards:filter-emml-accepts-dot-slash-and-trailing-slash() {
	let $shards := tsexpshards:paths("hybrid", "./manuscripts/EMML/")
	return $shards = "manuscripts/EMML/1-1000" and
		$shards = "manuscripts/EMML/1001-2000" and
		not($shards = "manuscripts/EMML")
};

declare %test:assertEquals("corpora") function tsexpshards:filter-accepts-absolute-betmasdata-uri() {
	tsexpshards:paths("hybrid", "/db/apps/BetMasData/corpora")
};

declare %test:assertError("expandShards:BAD_MODE") function tsexpshards:paths-refuse-unknown-mode() {
	expandShards:paths("nope", (), $tsexpshards:root)
};

declare %test:assertError("expandShards:BAD_SHARD") function tsexpshards:paths-refuse-authority-files-new() {
	expandShards:paths("hybrid", "authority-files/new", $tsexpshards:root)
};

declare %test:assertError("expandShards:MISSING") function tsexpshards:paths-refuse-missing-filter() {
	tsexpshards:paths("hybrid", "manuscripts/NoSuchLibrary")
};

declare %test:assertEquals(403) function tsexpshards:respond-forbidden-when-not-allowed() {
	expandShards:respond(map {"parameters": map {"mode": "hybrid"}}, false())($router:RESPONSE_CODE)
};

declare %test:assertEquals(400) function tsexpshards:respond-bad-mode-is-400() {
	expandShards:respond(map {"parameters": map {"mode": "nope"}}, true())($router:RESPONSE_CODE)
};

declare %private function tsexpshards:respond($request as map(*)) as map(*) {
	let $_ := tsexpshards:seed()
	return expandShards:respond($request, true(), $tsexpshards:root)
};

declare %test:assertEquals(404) function tsexpshards:respond-missing-collection-is-404() {
	tsexpshards:respond(map {"parameters": map {"mode": "hybrid", "collection": "manuscripts/NoSuchLibrary"}})(
		$router:RESPONSE_CODE
	)
};

(: Empty parameters default to hybrid against the fixture, not the live corpus. :)
declare %test:assertTrue function tsexpshards:respond-defaults-to-hybrid() {
	let $res := tsexpshards:respond(map {})
	let $shards := rutil:body($res)?shards
	return $res($router:RESPONSE_CODE) = 200 and
		rutil:body($res)?mode = "hybrid" and
		$shards instance of array(*) and
		$shards?* = "manuscripts/Pistoia" and
		not($shards?* = "manuscripts/build")
};

declare %test:assertTrue function tsexpshards:respond-shards-is-a-json-array() {
	let $shards := rutil:body(tsexpshards:respond(map {"parameters": map {"mode": "matrix"}}))?shards
	return $shards instance of array(*) and $shards?* = "works" and not($shards?* = "works/1-1000")
};

declare %test:assertTrue function tsexpshards:respond-refuses-authority-files-new() {
	let $res := expandShards:respond(map {"parameters": map {"collection": "authority-files/new"}}, true())
	return $res($router:RESPONSE_CODE) = 400 and contains(rutil:body($res)?error, "authority-files/new")
};

declare %private function tsexpshards:seed-deletions() {
	let $_ := (
		tsexpshards:remove-if-exists($tsexpshards:del-data), tsexpshards:remove-if-exists($tsexpshards:del-expanded)
	)
	let $_data := xmldb:create-collection("/db/apps/BetMasData", "_delFx")
	let $_exp := xmldb:create-collection("/db/apps/expanded", "_delFx")
	let $_src :=
		for $rel in ("manuscripts/Berlin", "manuscripts/EMML/1-1000", "narratives/story", "works/1-1000")
		return tsexpshards:mkdirs($tsexpshards:del-data, $rel)
	return for $rel in
			(
				"manuscripts/Berlin",
				"manuscripts/Gone",
				"manuscripts/EMML/1-1000",
				"manuscripts/EMML/9001-9001",
				"narratives/story",
				"narratives/oldstory",
				"works/1-1000",
				"works/new",
				"authority-files/ArtThemes",
				"authority-files/new"
			)
		return tsexpshards:mkdirs($tsexpshards:del-expanded, $rel)
};

declare %private function tsexpshards:removed($mode as xs:string) as xs:string* {
	let $_ := tsexpshards:seed-deletions()
	return expandShards:removed($mode, $tsexpshards:del-data, $tsexpshards:del-expanded)
};

(:
 : Hybrid reports shard paths the image expanded has and this BetMasData does not.
 : A child of a corpus that still exists (narratives/oldstory) is assemble's job.
 : */new stays, including when the corpus itself is gone.
 :)
declare %test:assertTrue function tsexpshards:hybrid-removed-is-shard-grain() {
	let $gone := tsexpshards:removed("hybrid")
	return $gone = "manuscripts/Gone" and
		$gone = "manuscripts/EMML/9001-9001" and
		$gone = "authority-files/ArtThemes" and
		not($gone = "manuscripts/Berlin") and
		not($gone = "narratives/oldstory") and
		not($gone = "works/new") and
		not($gone = "authority-files/new") and
		not($gone = "authority-files")
};

declare %test:assertTrue function tsexpshards:l1-removed-includes-light-corpus-children() {
	let $gone := tsexpshards:removed("l1")
	return $gone = "narratives/oldstory" and not($gone = "narratives/story") and not($gone = "works/new")
};

declare %test:assertTrue function tsexpshards:matrix-removed-keeps-a-corpus-that-still-exists() {
	let $gone := tsexpshards:removed("matrix")
	return $gone = "authority-files/ArtThemes" and not($gone = "works/1-1000") and not($gone = "authority-files/new")
};

declare %test:assertError("expandShards:BAD_MODE") function tsexpshards:removed-refuse-unknown-mode() {
	expandShards:removed("nope", $tsexpshards:del-data, $tsexpshards:del-expanded)
};

declare %test:assertError("expandShards:MISSING") function tsexpshards:removed-refuse-missing-data-root() {
	expandShards:removed("hybrid", "/db/apps/BetMasData/_delFxMissing", $tsexpshards:del-expanded)
};

declare %test:assertEquals(403) function tsexpshards:deletions-forbidden-when-not-allowed() {
	expandShards:deletions(
		map {"parameters": map {"mode": "hybrid"}},
		false(),
		$tsexpshards:del-data,
		$tsexpshards:del-expanded
	)($router:RESPONSE_CODE)
};

declare %test:assertTrue function tsexpshards:deletions-returns-removed-array() {
	let $_ := tsexpshards:seed-deletions()
	let $res := expandShards:deletions(map {}, true(), $tsexpshards:del-data, $tsexpshards:del-expanded)
	let $removed := rutil:body($res)?removed
	return $res($router:RESPONSE_CODE) = 200 and
		rutil:body($res)?mode = "hybrid" and
		$removed instance of array(*) and
		$removed?* = "manuscripts/Gone" and
		not($removed?* = "works/new")
};
