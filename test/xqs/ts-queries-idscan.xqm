xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for the id-bearing scans in modules/queries.xqm: q:bmid and
 : q:clavis.
 :
 : Both answer "the records whose xml:id contains this fragment" with
 : contains(@xml:id, $q) over the whole expanded collection. That predicate
 : only discriminates while the fragment is specific. An absent, empty or
 : blank fragment is the degenerate case, because contains($x, ()) and
 : contains($x, "") are both true for every record: the query stops
 : selecting anything and returns the entire collection.
 :
 : The two failures are not symmetric:
 :
 : 1. q:bmid answered with the whole corpus. ?searchType=bmid&query= reaches
 : it, because neither guard in q:query fires - those require zero or
 : three request parameters, and that request carries two. In the
 : reference corpus it returned 58,167 records (every t:TEI in
 : /db/apps/expanded) in ~18s.
 : 2. q:clavis raised instead. It normalises with format-number($q, "0000")
 : before it inspects the fragment, so "" is not a numeric and the
 : request failed XPTY0004 (HTTP 400). Its own ($q = "") branch, written
 : to return the unfiltered work list, was therefore unreachable.
 :
 : Assertion style: each test returns the value it wants compared and lets
 : %test:assertEquals carry the expectation, so a red test reports what it
 : expected next to what it got. test/xqs/xqSuite.js surfaces both fields of
 : the XQSuite report; without that they are dropped and every failure reads
 : identically. The corpus size appears in @see notes rather than in raised
 : errors - the assertion already shows expected vs actual.
 :
 : These hit the real corpus, as the other query-level suites do: the
 : corpus is what makes a broad fragment broad, and no fixture would
 : reproduce the empty-parameter path.
 :
 : The bounded-response contract of the idlookup typeahead is deliberately
 : NOT mirrored here. bmid and clavis are paginated search-result pages
 : (q:results, 40 rows per page), not typeaheads, so truncating them would
 : hide records the user can legitimately page to. The guard tests below
 : therefore pin the empty/blank behaviour and the behaviour of real
 : fragments, and tsidscan:bmid-broad-fragment-is-not-capped pins that a
 : valid-but-short fragment is still returned in full.
 :)
module namespace tsidscan = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-idscan";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

(:~
 : An xml:id that exists in the corpus and is specific enough to match only
 : itself, so the guard tests cannot pass by rejecting everything.
 :
 : XQSuite evaluates an annotation as an XPath in the test's own context,
 : which cannot see this module's variables (XPST0003 on any annotation that
 : references one). Expectations are therefore spelled as literals in the
 : annotations, and the variables exist only to keep the bodies readable. A
 : fixture change must be applied in both places.
 :)
declare variable $tsidscan:KNOWN-TEI-ID := "LIT1367Exodus";

(:~
 : The hit sequence of a q:bmid/q:clavis response.
 :
 : The two searches disagree on shape, so this stays item()* rather than
 : pretending to one contract: q:bmid returns bare records, while q:clavis
 : wraps each record as map {"hit": ..., "type": ...}. Typing this
 : map(*) would make a q:bmid result a type error and mask the behaviour
 : under test.
 :
 : @param $response the map returned by q:bmid or q:clavis
 : @return the hit entries, in the shape that search produced
 :)
declare function tsidscan:tei($response as map(*)) as item()* {
	$response("tei")
};

(:~
 : The payloads of the clavis hits of one kind, e.g. the withdrawn records
 : or the live works. Only meaningful for q:clavis, which is the search that
 : labels its hits.
 :
 : @param $response the map returned by q:clavis
 : @param $type the "type" key to select on
 : @return the payload nodes of the matching hits
 :)
declare function tsidscan:hits-of-type($response as map(*), $type as xs:string) as node()* {
	for $hit in tsidscan:tei($response)
	return typeswitch ($hit)
		case map(*) return
			if (map:get($hit, "type") eq $type) then
				map:get($hit, "hit")
			else (
			)

		default return
			()
};

(:~
 : A specific fragment must still find its records, and must find only the
 : record it names. Without this the guards below would pass on a q:bmid
 : that rejects every input, or on one that matches far too much.
 :
 : @return the matched xml:id, to be compared against the fragment itself
 : @see tsidscan:bmid-empty-fragment-matches-nothing
 :)
declare %test:assertEquals("LIT1367Exodus") function tsidscan:bmid-finds-records-for-specific-fragment() as xs:string {
	string-join(tsidscan:tei(q:bmid($tsidscan:KNOWN-TEI-ID))/@xml:id/string(), " ")
};

(:~
 : An empty fragment must match nothing, because contains($x, "") is true
 : for every record. This is the reachable whole-corpus case:
 : ?searchType=bmid&query= lands here. The whole collection is 58,167
 : t:TEI in the reference corpus, so a regression shows an expected 0
 : against a five-digit actual.
 :
 : @return the number of records matched, expected to be zero
 : @see tsidscan:bmid-blank-fragment-matches-nothing
 :)
declare %test:assertEquals(0) function tsidscan:bmid-empty-fragment-matches-nothing() as xs:integer {
	count(tsidscan:tei(q:bmid("")))
};

(:~
 : A whitespace-only fragment is not a search either; normalize-space("")
 : is "", so it must behave exactly like the empty fragment.
 :
 : @return the number of records matched, expected to be zero
 : @see tsidscan:bmid-empty-fragment-matches-nothing
 :)
declare %test:assertEquals(0) function tsidscan:bmid-blank-fragment-matches-nothing() as xs:integer {
	count(tsidscan:tei(q:bmid("   ")))
};

(:~
 : A fragment arriving as an empty sequence, which is how the dispatcher's
 : xs:string* $query parameter represents an absent query. contains(@xml:id,
 : ()) is true for every record, so that shape must match nothing too.
 :
 : @return the number of records matched, expected to be zero
 : @see tsidscan:bmid-empty-fragment-matches-nothing
 :)
declare %test:assertEquals(0) function tsidscan:bmid-absent-fragment-matches-nothing() as xs:integer {
	count(tsidscan:tei(q:bmid(())))
};

(:~
 : q:clavis must answer a blank fragment with no hits instead of raising.
 : format-number("", "0000") raises XPTY0004, which is what made
 : ?searchType=clavis&query= an HTTP 400 rather than an empty result set.
 :
 : @return the number of records matched, expected to be zero
 : @see tsidscan:clavis-non-numeric-fragment-matches-nothing
 :)
declare %test:assertEquals(0) function tsidscan:clavis-blank-fragment-matches-nothing() as xs:integer {
	count(tsidscan:tei(q:clavis("")))
};

(:~
 : A fragment that is not a clavis number can match nothing, but must not
 : raise: format-number("abc", "0000") is XPTY0004 today.
 :
 : @return the number of records matched, expected to be zero
 : @see tsidscan:clavis-blank-fragment-matches-nothing
 :)
declare %test:assertEquals(0) function tsidscan:clavis-non-numeric-fragment-matches-nothing() as xs:integer {
	count(tsidscan:tei(q:clavis("abc")))
};

(:~
 : A real clavis fragment must still find its work. Without this the guards
 : above would pass on a q:clavis that rejects every input.
 :
 : The fragment is clavis 0050, which is xml:id LIT0050MMDZ on one work in
 : the reference corpus.
 :
 : @return the xml:id of the matched work
 : @see tsidscan:clavis-blank-fragment-matches-nothing
 :)
declare %test:assertEquals("LIT0050MMDZ") function tsidscan:clavis-numeric-fragment-finds-work() as xs:string {
	string-join(tsidscan:hits-of-type(q:clavis("0050"), "match")/@xml:id/string(), " ")
};

(:~
 : Withdrawn records must stay findable. deleted.xml exists precisely so
 : that a clavis number whose record was pulled still returns a hit, so
 : guarding the fragment must not take that path down with it. The
 : expectation is the item deleted.xml actually holds for clavis 0050 in
 : the reference corpus, so a re-import of the withdrawal list is visible
 : here rather than silently changing what the search returns.
 :
 : @return the withdrawn hits, compared against the deleted.xml item
 : @see tsidscan:clavis-numeric-fragment-finds-work
 :)
declare %test:assertEquals("ESamm005006") function tsidscan:clavis-withdrawn-records-remain-findable() as xs:string {
	string-join(tsidscan:hits-of-type(q:clavis("0050"), "deleted")/string(), " ")
};

(:~
 : Guards for a degenerate fragment must not become a general cap. A short
 : but valid fragment is a real search, and these are paginated result
 : pages rather than the idlookup typeahead, so a match count above that
 : typeahead's 100-hit ceiling is the correct behaviour. This pins the
 : decision so the ceiling is not copied over from restviews/idlookup.xqm
 : later.
 :
 : @return the number of records matched, expected to exceed 100
 : @see tsidscan:bmid-empty-fragment-matches-nothing
 :)
declare %test:assertXPath("$result gt 100") function tsidscan:bmid-broad-fragment-is-not-capped() as xs:integer {
	count(tsidscan:tei(q:bmid("1")))
};
