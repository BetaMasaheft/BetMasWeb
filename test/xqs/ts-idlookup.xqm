xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for /api/idlookup (restviews/idlookup.xqm).
 :
 : The endpoint matches with contains(@xml:id, $id) over the expanded
 : collection. Two unbounded behaviours are covered here:
 :
 : 1. ?id= absent or blank. contains("some-id", ()) is true for every node
 : and contains($x, "") likewise, so one request matched all ~192,000
 : id-bearing nodes and serialised them as a multi-megabyte payload.
 : 2. ?id= too broad. A needle as ordinary as "1" matches ~125,600 nodes
 : and returned a 3.7 MB JSON array of suggestions - useless to a
 : typeahead and expensive to build.
 :
 : Each test returns "ok" or a sentence naming what was wrong, and the
 : expectation lives in the %test:assertEquals("ok") annotation, so a
 : failure message reads as a diagnosis instead of a bare false.
 :
 : Comparisons go through string() deliberately: eXist's optimiser turns a
 : comparison against an empty sequence into a path step and raises
 : XPDY0002 on the missing key rather than letting the assertion speak.
 :
 : These tests hit the real corpus, as the other query-level suites do: the
 : matching corpus is what the bugs are about, and there is no fixture that
 : would exercise the broad and empty-parameter paths.
 :)
module namespace tsidlookup = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-idlookup";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace lookID = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lookID" at "../../restviews/idlookup.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "../../modules/exptit.xqm";

(:~
 : An xml:id that exists in the corpus and is specific enough to match
 : only itself, so the exact-lookup tests cannot pass by accident.
 :)
declare variable $tsidlookup:KNOWN-TEI-ID := "LOC5836Tabito";

(:~
 : A needle common enough in the real corpus that it matches far more
 : xml:id values than any caller would want rendered: "e" matches ~28,000,
 : comfortably above $lookID:MAX-HITS.
 :)
declare variable $tsidlookup:BROAD-NEEDLE := "e";

(:~
 : The ids the endpoint returned, or () when it answered with the
 : "No results" element instead of a hits map.
 :
 : @param $parameters the request parameters, e.g. map {"id": "..."}
 : @return the item sequence of the response, or () for no results
 :)
declare function tsidlookup:hits($parameters as map(*)) as map(*)* {
	let $response := lookID:IDSlookup(map {"parameters": $parameters})
	return typeswitch ($response)
		case map(*) return
			$response?items

		default return
			()
};

(:~
 : The whole response map, for the tests that assert on the envelope
 : rather than on the ids.
 :
 : @param $parameters the request parameters
 : @return the response map, or () when the endpoint reported no results
 :)
declare function tsidlookup:response($parameters as map(*)) as map(*)? {
	let $response := lookID:IDSlookup(map {"parameters": $parameters})
	return typeswitch ($response)
		case map(*) return
			$response

		default return
			()
};

(:~
 : Turns a boolean expectation into either a pass or a spoken diagnosis.
 :
 : XQSuite reports assertTrue as a bare false and assertEquals as
 : "assertEquals failed", and this eXist's xqsuite module exposes no
 : fail() function, so neither carries the numbers that explain a break.
 : Raising an error whose message is the sentence puts them in the report:
 : a red test then names the offending counts instead of asserting only
 : that something was untrue.
 :
 : @param $held whether the expectation held
 : @param $description what was being checked
 : @param $detail the values that broke it
 : @return true() when the expectation held, otherwise an error carrying
 : the description and the detail
 :)
declare function tsidlookup:otherwise($held as xs:boolean, $description as xs:string, $detail as xs:string*) {
	if ($held) then
		true()
	else
		error(xs:QName("err:FOER0000"), concat($description, ": ", string-join($detail, ", ")))
};

(:~
 : An absent ?id= must not match every id-bearing node in the corpus.
 :
 : @return true(), or how many nodes it matched
 : @see tsidlookup:blank-id-matches-nothing
 :)
declare %test:assertTrue function tsidlookup:missing-id-matches-nothing() {
	let $hits := tsidlookup:hits(map {})
	return tsidlookup:otherwise(not(exists($hits)), "absent ?id= matched the corpus", concat("hits=", count($hits)))
};

(:~
 : An empty ?id= must not match every id-bearing node, because
 : contains($x, "") is true for all of them.
 :
 : @return true(), or how many nodes it matched
 : @see tsidlookup:missing-id-matches-nothing
 :)
declare %test:assertTrue function tsidlookup:empty-id-matches-nothing() {
	let $hits := tsidlookup:hits(map {"id": ""})
	return tsidlookup:otherwise(not(exists($hits)), "empty ?id= matched the corpus", concat("hits=", count($hits)))
};

(:~
 : A whitespace-only ?id= is normalised away and must not match the corpus.
 :
 : @return true(), or how many nodes it matched
 : @see tsidlookup:empty-id-matches-nothing
 :)
declare %test:assertTrue function tsidlookup:blank-id-matches-nothing() {
	let $hits := tsidlookup:hits(map {"id": "   "})
	return tsidlookup:otherwise(not(exists($hits)), "blank ?id= matched the corpus", concat("hits=", count($hits)))
};

(:~
 : A known, specific xml:id must match itself, so the guards above cannot
 : be passing simply by rejecting everything.
 :
 : @return true(), or the ids that came back instead
 : @see tsidlookup:selective-needle-is-not-flagged-truncated
 :)
declare %test:assertTrue function tsidlookup:known-id-matches-itself() {
	let $ids := tsidlookup:hits(map {"id": $tsidlookup:KNOWN-TEI-ID})?id
	return tsidlookup:otherwise(
		string-join($ids, " ") eq $tsidlookup:KNOWN-TEI-ID,
		"known id did not match itself",
		concat("expected=", $tsidlookup:KNOWN-TEI-ID, " got=", string-join($ids, " "))
	)
};

(:~
 : A needle matching far more ids than the cap must return at most the
 : cap, so neither memory nor the payload is a function of corpus size.
 :
 : @return true(), or the number returned against the cap
 :)
declare %test:assertTrue function tsidlookup:broad-needle-is-capped() {
	let $response := tsidlookup:response(map {"id": $tsidlookup:BROAD-NEEDLE})
	let $shown := count($response?items)
	return tsidlookup:otherwise(
		$shown le $lookID:MAX-HITS,
		"broad ?id= returned more than the cap",
		concat("shown=", $shown, " cap=", $lookID:MAX-HITS)
	)
};

(:~
 : Capping is only honest if the caller can see that matches were dropped.
 : ?total has to stay the true count, ?returned the number actually sent,
 : and ?truncated has to say the list is partial - a silently shortened
 : list reads as "these are all the matches".
 :
 : @return true(), or the envelope fields that were wrong
 :)
declare %test:assertTrue function tsidlookup:cap-is-not-silent() {
	let $response := tsidlookup:response(map {"id": $tsidlookup:BROAD-NEEDLE})
	let $shown := count($response?items)
	let $reported := concat(
		"truncated=",
		string($response?truncated),
		" returned=",
		string($response?returned),
		" shown=",
		$shown,
		" total=",
		string($response?total)
	)
	return tsidlookup:otherwise(
		(string($response?truncated) eq "true") and
			(string($response?returned) eq string($shown)) and
			(exists($response?total) and xs:integer($response?total) gt $shown),
		"truncation was not reported",
		$reported
	)
};

(:~
 : ?total must be the real number of matches, recomputed here independently
 : of the endpoint, so a capped response cannot pass by reporting the cap
 : as if it were the whole corpus.
 :
 : @return true(), or the two counts side by side
 :)
declare %test:assertTrue function tsidlookup:total-is-the-true-count() {
	let $needle := $tsidlookup:BROAD-NEEDLE
	let $response := tsidlookup:response(map {"id": $needle})
	let $independent := count(
		(
			$exptit:col/t:TEI[contains(@xml:id, $needle)],
			$exptit:col//t:msPart[contains(@xml:id, $needle)],
			$exptit:col//t:msItem[contains(@xml:id, $needle)],
			$exptit:col//t:title[contains(@xml:id, $needle)],
			$exptit:col//t:div[contains(@xml:id, $needle)]
		)
	)
	return tsidlookup:otherwise(
		($independent gt $lookID:MAX-HITS) and (exists($response?total) and xs:integer($response?total) eq $independent),
		"?total is not the true match count",
		concat("reported=", string($response?total), " independent=", $independent, " cap=", $lookID:MAX-HITS)
	)
};

(:~
 : A selective id must come back whole and must not be flagged truncated.
 :
 : @return true(), or the envelope fields that were wrong
 : @see tsidlookup:known-id-matches-itself
 :)
declare %test:assertTrue function tsidlookup:selective-needle-is-not-flagged-truncated() {
	let $response := tsidlookup:response(map {"id": $tsidlookup:KNOWN-TEI-ID})
	let $reported := concat(
		"truncated=",
		string($response?truncated),
		" returned=",
		string($response?returned),
		" total=",
		string($response?total)
	)
	return tsidlookup:otherwise(
		(string($response?truncated) eq "false") and
			(string($response?returned) eq string($response?total)) and
			(exists($response?total) and xs:integer($response?total) eq 1),
		"a single match was flagged or counted wrongly",
		$reported
	)
};
