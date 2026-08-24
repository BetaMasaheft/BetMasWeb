xquery version "3.1" encoding "UTF-8";

(:~
 : Dynamic lookup for Roaster operations whose implementation lives in
 : another, optionally-installed package (e.g. BetMasApi). A static
 : `import module` would fail this router's whole compile - taking every
 : other route down with it - the moment that package isn't installed, as
 : in BetMasWeb's own standalone/test image. util:import-module() resolves
 : at runtime instead, so a missing package degrades to a clean 501 for
 : just the one operation that needed it.
 :)
module namespace crossapp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/crossapp";

import module namespace errors = "http://e-editiones.org/roaster/errors";

(:~
 : Registry of operationIds implemented by another package. Add an entry
 : here for each cross-app route - modules/api.xql's local:lookup falls
 : back to crossapp:resolve() for anything it can't resolve from its own
 : statically-imported modules.
 :)
declare variable $crossapp:registry := map {
	"places:json":
		map {
			"package": "BetMasApi",
			"namespace-uri": "https://www.betamasaheft.uni-hamburg.de/BetMasApi/places",
			"prefix": "places",
			"location": "xmldb:exist:///db/apps/BetMasApi/local/places.xqm",
			"arity": 1
		}
};

(:~
 : Whether $operationId is a registered cross-app operation. Callers must
 : check this *before* attempting their own xs:QName($operationId) - the
 : single-argument xs:QName cast resolves prefixes against the calling
 : module's own static in-scope namespaces only, fixed at compile time.
 : util:import-module()'s dynamic prefix binding doesn't change that: a
 : caller in a different module that has never heard of the "places" prefix
 : still throws XPST0081 trying to even construct xs:QName("places:json"),
 : before crossapp:resolve() gets a chance to run.
 :)
declare function crossapp:known($operationId as xs:string) as xs:boolean {
	map:contains($crossapp:registry, $operationId)
};

(:~
 : Resolve $operationId against the registry above. Always returns a
 : callable function - either the real cross-app operation, or a fallback
 : that raises a clean 501 - so Roaster's router never sees an empty
 : lookup (which it turns into an opaque, unexplained 500).
 :
 : @param $operationId a prefixed function name from the registry, e.g. "places:json"
 : @return the resolved function, a 501 fallback, or the empty sequence if
 : $operationId isn't in the registry at all (so callers can still fall
 : through to their own default handling)
 :)
declare function crossapp:resolve($operationId as xs:string) as function(*)? {
	if (not(map:contains($crossapp:registry, $operationId))) then (
	) else
		let $entry := $crossapp:registry($operationId)
		let $fn := try {
			util:import-module(xs:anyURI($entry?namespace-uri), $entry?prefix, xs:anyURI($entry?location)),
			function-lookup(xs:QName($operationId), $entry?arity)
		} catch * { () }
		return if (exists($fn)) then
			$fn
		else
			function ($request as map(*)) {
				error(
					$errors:NOT_IMPLEMENTED,
					$entry?package || " is not installed on this deployment (operation: " || $operationId || ")"
				)
			}
};
