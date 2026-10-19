xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for viewItem:textfragment, the text tab's TEI → HTML step.
 :
 : It renders the edition, except for very large fragments: Transkribus
 : transcriptions over 120 folia get a notice only, long texts (over 35
 : textparts and 2000 words) only their first 35 textparts.
 :
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/161
 :)
module namespace tsvitextfrag = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-textfragment";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare %private function tsvitextfrag:edition($parts as xs:integer, $wordsPerPart as xs:integer) as element(t:div) {
	<div xmlns="http://www.tei-c.org/ns/1.0" type="edition" xml:id="tsed">
		{
			for $i in 1 to $parts
			return <div n="{ $i }" type="textpart" xml:id="tspart{ $i }">
				<ab>{ string-join((1 to $wordsPerPart)!("ቃል" || .), "፡") }</ab>
			</div>
		}
	</div>
};

(: Whitespace-normalized, as a browser displays it. :)
declare %private function tsvitextfrag:render($frag as element()) as xs:string {
	normalize-space(serialize(viewItem:textfragment($frag)))
};

declare %test:assertTrue function tsvitextfrag:short-text-is-rendered() {
	contains(tsvitextfrag:render(tsvitextfrag:edition(2, 5)), "ቃል3")
};

declare %test:assertFalse function tsvitextfrag:short-text-is-not-truncated() {
	contains(tsvitextfrag:render(tsvitextfrag:edition(2, 5)), "too long to show")
};

declare %test:assertTrue function tsvitextfrag:long-text-shows-notice() {
	contains(tsvitextfrag:render(tsvitextfrag:edition(40, 60)), "Only the first 35 of 40 sections")
};

declare %test:assertTrue function tsvitextfrag:long-text-renders-first-35-parts-only() {
	let $html := tsvitextfrag:render(tsvitextfrag:edition(40, 60))
	return contains($html, 'id="tspart35"') and not(contains($html, 'id="tspart36"'))
};

(:~
 : Many sections but few words: still rendered in full.
 :)
declare %test:assertFalse function tsvitextfrag:many-short-parts-are-not-truncated() {
	contains(tsvitextfrag:render(tsvitextfrag:edition(40, 2)), "too long to show")
};

declare %test:assertTrue function tsvitextfrag:large-transkribus-shows-notice-only() {
	let $frag := <div xmlns="http://www.tei-c.org/ns/1.0" subtype="transkribus" type="edition">
		{
			for $i in 1 to 121
			return <div n="{ $i }" subtype="folio"><ab>folio{ $i }</ab></div>
		}
	</div>
	let $html := tsvitextfrag:render($frag)
	return contains($html, "121 folia") and not(contains($html, "folio1<"))
};
