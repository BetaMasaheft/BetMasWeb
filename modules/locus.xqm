xquery version "3.1" encoding "UTF-8";

(:~
 : https://github.com/BetaMasaheft/Documentation/issues/920
 : https://github.com/BetaMasaheft/Documentation/issues/1162
 : https://github.com/BetaMasaheft/Documentation/issues/1314
 : https://github.com/BetaMasaheft/Documentation/issues/1426 --> function to normalize measure before indexing it
 : @author Pietro Liuzzo
 :)
module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/locus";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

import module namespace r = "http://joewiz.org/ns/xquery/roman-numerals" at "roman-numerals.xqm";
import module namespace functx = "http://www.functx.com";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

declare variable $locus:Regex := "^\d+(r|v)?([a-z])?(\d+)?";

declare variable $locus:RegexProt := "^[xlcvi]+";

(:
 : Full-match grammar for a valid Roman numeral in this module's supported
 : range (hundreds/tens/ones only - no D or M, matching $locus:RegexProt's
 : character class). Every group is individually optional, so this is only
 : ever used with fn:matches() (see locus:strict-roman-prefix): unlike
 : fn:analyze-string(), fn:matches() does not forbid a pattern that could
 : match a zero-length string.
 :)
declare variable $locus:RegexStrictRoman := "^(c{0,3})(xc|xl|l?x{0,3})(ix|iv|v?i{0,3})$";

(:
funzione per collegare riferimenti in locus al testo
target=1rv => &ref=1rv oppure (vedi sopra) a .1rv che poi verra rediretto a &ref=1rv
target=1rv 4rv => for each value: come sopra
from=1r to=3v => &start=1r&end=3v oppure (vedi sopra) a .1r-3v che poi verra rediretto a &start=1r&end=3v
 :)

(:~
 : Runs $measure past a battery of parsers for the various shapes seen in
 : <measure unit="leaf">, e.g. "iii+69+iv", "164 (I + 163)", "134 (1 + 133)",
 : "152 (V + 147)" (see https://github.com/BetaMasaheft/Documentation/issues/1314
 : for the fuller catalogue of shapes, including ones no parser here
 : attempts: "1-71 + 1(after 91)", "101a-116b", "153ff", "21-188", ...).
 :
 : Does not appear to be called anywhere in this app - none of the four
 : analyze-string() results are picked apart or combined into the
 : <measures> breakdown structure the surrounding comment describes, and
 : no caller was found for this function. Left as-is beyond fixing the
 : zero-length-matchable placeholder patterns (see
 : https://github.com/BetaMasaheft/BetMasWeb/issues/186 /
 : https://github.com/BetaMasaheft/BetMasWeb/issues/40 for that class of
 : bug) rather than finishing the unimplemented parsing.
 :
 : @param measure raw <measure unit="leaf"> text content
 : @return one s:analyze-string-result per parser, in parser order
 :)
declare %test:arg("measure", "i") %test:assertTrue function locus:analyzeMeasure($measure as xs:string*) {
	(: set different parsers for each possible structure and try each :)
	let $parsers := (
		"([ivx]?)(\+?)(\d{1,3})(\+?)([ivx]?)" (: matches: iii+69+iv, ii+69, 69+i, 69 :),
		"(\d{1,3}?)(\+?)(\d{1,3})(\+?)(\d{1,3}?)" (: matches: 3+69+1, 2+69, 69+1, 69 :),
		"(\d+)(\s*)(\()(\d+)(\s*\+\s*)(\d+)(\))" (: matches: 134 (1 + 133) :),
		"(\d+)(\s*)(\()([ivx]+)(\s*\+\s*)(\d+)(\))" (: matches: 152 (V + 147) :)
	)
	for $parser in $parsers
	let $analyse := analyze-string($measure, $parser)
	return $analyse
};

(: locus @corresp-- foliation :)

(:
normalize values of locus attributes
@target --> #1v #2r
@from and @to --> 1ra

format of the reference is
folio numer, verso or recto, letter for column.
\d[+]                [v|r]                  \w

but if folio is in protective quire,
then small roman numerals are used and v(erso)|r(ecto)
which need to be converted to the previous format
 :)
(:~
 : Longest leading substring of $folio that is a syntactically valid Roman
 : numeral (per $locus:RegexStrictRoman), found by shrinking the candidate
 : prefix with fn:matches() rather than extracting it with
 : fn:analyze-string() - see $locus:RegexStrictRoman for why.
 : @param folio a string beginning with one or more [xlcvi] characters, as
 : already guaranteed by $locus:RegexProt at the only call site
 : @return the longest valid-Roman-numeral prefix; a trailing recto/verso
 : indicator (e.g. the "(erso)" in "ivv(erso)") is deliberately left
 : unconsumed, matching the ambiguity noted on locus:folio
 :)
declare
	%test:arg("folio", "iii")
	%test:assertEquals("iii")
	%test:arg("folio", "ivv")
	%test:assertEquals("iv")
	%test:arg("folio", "iir")
	%test:assertEquals("ii")
	%test:arg("folio", "ivv(erso)")
	%test:assertEquals("iv")
	%test:arg("folio", "ir(ecto)")
	%test:assertEquals("i")
	%test:arg("folio", "x")
	%test:assertEquals("x")
	%test:arg("folio", "xi")
	%test:assertEquals("xi")
	%test:arg("folio", "xl")
	%test:assertEquals("xl")
function locus:strict-roman-prefix($folio as xs:string) as xs:string {
	(
		for $length in reverse(1 to string-length($folio))
		let $candidate := substring($folio, 1, $length)
		where matches($candidate, $locus:RegexStrictRoman)
		return $candidate
	)[1]
};

declare
	%test:arg("folio", "20")
	%test:assertEquals(20)
	%test:arg("folio", "1ra")
	%test:assertEquals(1)
	%test:arg("folio", "2v")
	%test:assertEquals(2)
	%test:arg("folio", "45ra5")
	%test:assertEquals(45)
	%test:arg("folio", "iii")
	%test:assertEquals(3)
	%test:arg("folio", "ivv")
	%test:assertEquals(4)
	%test:arg("folio", "iir")
	%test:assertEquals(2)
	%test:arg("folio", "ivv(erso)")
	%test:assertEquals(4)
	%test:arg("folio", "ir(ecto)")
	%test:assertEquals(1)
	%test:arg("folio", "v")
	%test:assertEquals(5)
	%test:arg("folio", "x")
	%test:assertEquals(10)
	%test:arg("folio", "l")
	%test:assertEquals(50)
	%test:arg("folio", "c")
	%test:assertEquals(100)
	%test:arg("folio", "xl")
	%test:assertEquals(40)
	%test:arg("folio", "xc")
	%test:assertEquals(90)
	%test:arg("folio", "xi")
	%test:assertEquals(11)
	%test:arg("folio", "xiv")
	%test:assertEquals(14)
	%test:arg("folio", "xix")
	%test:assertEquals(19)
	%test:arg("folio", "xci")
	%test:assertEquals(91)
	%test:arg("folio", "ccl")
	%test:assertEquals(250)
function locus:folio($folio as xs:string) as xs:integer {
	if (matches($folio, "^\d+$")) then
		xs:integer($folio)
	else if (matches($folio, $locus:Regex)) then
		replace($folio, "\d+$", "") => replace("[rvabcd]", "") => replace("#", "") => xs:integer()
	else if (matches($folio, $locus:RegexProt)) then
		(: the prefix should be only a VALID roman numeral, what will not be achieved is to match
an ambiguous syntax as iv where v could be verso or part of a valid 4 in roman numerals.
this vails also where iv(erso) is used, because it will match as 4 :) locus:roman-arabic(
			locus:strict-roman-prefix($folio)
		)
	else
		0
};

(: support better referencing potential for locus as in
https://github.com/BetaMasaheft/Documentation/issues/1162#issuecomment-608639384
proposal 2 or 3 :)

(: parse locus attributes for columns, recto and verso, folio numer :)

(: given one locus element get the sequence of folio references between @from and @to :)

(: given one locus element get the sequence of folio references listed in @target :)

(: given a series of locus elements, get the sequence of folio references
involved in all, ordered :)

(: if a value is in roman numerals, convert it to arabic :)
declare
	%test:arg("value", "i")
	%test:assertEquals("1")
	%test:arg("value", "iv")
	%test:assertEquals("4")
	%test:arg("value", "xxx")
	%test:assertEquals("30")
function locus:roman-arabic($value as xs:string*) {
	r:roman-numeral-to-integer(upper-case($value))
};

declare function locus:stringloc($node) {
	" (" ||
		(
			let $locs :=
				for $loc in $node/t:locus
				return string:tei2string($loc)
			return string-join($locs, " ")
		) ||
		")"
};

(:~
 : locuses in any node as string
 :)
declare function locus:placement($node) {
	if ($node/t:locus) then (
		locus:stringloc($node)
	) else
		""
};
