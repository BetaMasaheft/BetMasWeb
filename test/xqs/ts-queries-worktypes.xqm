xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for q:par-works-type-impl (modules/queries.xqm).
 :
 : work-types=work builds an [@type="work"] predicate. Documentary corpora
 : in expanded also carry @type="work" (after corpora#3) and were therefore
 : listed in works search with bogus Clavis ids (BetMasWeb#193). Prod never
 : included them; documentcorpora.html is their only intended surface.
 :
 : The -impl is pure (no request), same recipe as ts-queries-plainfields.
 :)
module namespace tsworktypes = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-queries-worktypes";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "../../modules/queries.xqm";

(:~
 : Apply the work-types predicate string to a fixture sequence the same way
 : q:parameters2arguments stitches it onto //t:TEI in live search.
 :)
declare %private function tsworktypes:select($teis as element(t:TEI)*, $work-type as xs:string*) as element(t:TEI)* {
	let $pred := q:par-works-type-impl($work-type)
	return util:eval("$teis" || $pred)
};

declare %private function tsworktypes:fixtures() as element(t:TEI)+ {
	(
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LIT1367Exodus" />,
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="corpus10" />,
		(: IHA authority works end with "IHA"; already excluded from works search. :)
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LIT0000IHA" />,
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="BNFet32" />
	)
};

(:~
 : #193: corpus* must not appear when searching works.
 :)
declare %test:assertEquals("LIT1367Exodus") function tsworktypes:work-excludes-corpus-and-iha() {
	string-join(tsworktypes:select(tsworktypes:fixtures(), "work")/@xml:id, ",")
};

declare %test:assertTrue function tsworktypes:work-predicate-mentions-corpus-guard() {
	contains(q:par-works-type-impl("work"), 'starts-with(@xml:id, "corpus")')
};

declare %test:assertEquals("BNFet32") function tsworktypes:mss-unchanged() {
	string-join(tsworktypes:select(tsworktypes:fixtures(), "mss")/@xml:id, ",")
};
