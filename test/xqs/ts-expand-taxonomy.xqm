xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for expand taxonomy XInclude (BetMasWeb#89).
 : Expanded export must reference a public URI, not xmldb:exist.
 :)
module namespace tsexpandtax = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-taxonomy";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";
import module namespace router = "http://e-editiones.org/roaster/router";
import module namespace rutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/rutil" at "../../modules/roaster-util.xqm";
import module namespace listsTax = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/listsTax" at "../../restviews/listsTaxonomy.xqm";

(:~
 : Minimal TEI whose xml:id is not a taxonomy category id.
 :)
declare variable $tsexpandtax:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="LITTESTtaxXi">
	<teiHeader><encodingDesc><p>seed</p></encodingDesc></teiHeader>
	<text><body><div type="edition"><ab>x</ab></div></body></text>
</TEI>;

declare variable $tsexpandtax:encodingDesc := $tsexpandtax:tei//t:encodingDesc;

(:~
 : Expand must emit xi:include with the public taxonomy URI (not xmldb:exist).
 :)
declare
	%test:assertEquals("https://betamasaheft.eu/api/lists/canonicaltaxonomy.xml")
function tsexpandtax:include-href-is-public-uri() {
	let $out := expand:tei2fulltei($tsexpandtax:encodingDesc, ())
	return string($out//xi:include/@href)
};

(:~
 : No eXist-private URI left in the expanded encodingDesc include.
 :)
declare %test:assertFalse function tsexpandtax:include-href-is-not-xmldb() {
	let $href := string(expand:tei2fulltei($tsexpandtax:encodingDesc, ())//xi:include/@href)
	return starts-with($href, "xmldb:")
};

(:~
 : Roaster handler returns the stored classDecl document.
 :)
declare %test:assertEquals("classDecl") function tsexpandtax:route-body-is-classDecl() {
	local-name(rutil:body(listsTax:canonicaltaxonomy(map {})))
};

declare %test:assertEquals(200) function tsexpandtax:route-is-roaster-200() {
	listsTax:canonicaltaxonomy(map {})($router:RESPONSE_CODE)
};
