xquery version "3.1" encoding "UTF-8";

(:~
 : Public canonical taxonomy document for XInclude consumers.
 :
 : Temporary home in BetMasWeb (same pattern as /api/idlookup). This route
 : should move to BetMasApi one day so all /api/lists/* live with the API app;
 : until then nginx must exact-match this path to BetMasWeb.
 :
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/89
 :)
module namespace listsTax = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/listsTax";

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace roaster = "http://e-editiones.org/roaster";

declare variable $listsTax:canonical := doc("/db/apps/lists/canonicaltaxonomy.xml");

(:~
 : GET /api/lists/canonicaltaxonomy.xml — returns the TEI classDecl taxonomy.
 :)
declare function listsTax:canonicaltaxonomy($request as map(*)) {
	if (exists($listsTax:canonical/*)) then
		roaster:response(
			200,
			"application/xml; charset=utf-8",
			$listsTax:canonical/*,
			map {"Access-Control-Allow-Origin": "*"}
		)
	else
		roaster:response(
			404,
			"application/xml",
			<error xmlns="https://w3id.org/dts/api#" statusCode="404">
				<title>Not Found</title>
				<description>canonicaltaxonomy.xml is not available in /db/apps/lists</description>
			</error>
		)
};
