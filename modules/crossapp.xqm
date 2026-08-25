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
			"collection": "/db/apps/BetMasApi",
			"namespace-uri": "https://www.betamasaheft.uni-hamburg.de/BetMasApi/places",
			"prefix": "places",
			"location": "xmldb:exist:///db/apps/BetMasApi/local/places.xqm",
			"arity": 1
		},
	"apisparql:sparqlQueryVersions":
		map {
			"package": "BetMasApi",
			"collection": "/db/apps/BetMasApi",
			"namespace-uri": "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apisparql",
			"prefix": "apisparql",
			"location": "xmldb:exist:///db/apps/BetMasApi/local/sparqlRest.xqm",
			"arity": 1
		}
};

(:~
 : Resolve $operationId against the registry above. Returns the empty
 : sequence *only* if $operationId isn't registered at all, so callers can
 : safely fall through to their own default handling for it -
 : modules/api.xql's local:lookup calls this *before* attempting its own
 : xs:QName($operationId): the single-argument xs:QName cast resolves
 : prefixes against the calling module's own static in-scope namespaces
 : only, fixed at compile time, and util:import-module()'s dynamic prefix
 : binding below doesn't change that for a caller elsewhere -
 : xs:QName("places:json") throws XPST0081 in any module that hasn't
 : statically imported something bound to "places". For any $operationId
 : that *is* registered, this always returns a callable function - never
 : the empty sequence - specifically so local:lookup never mistakes "this
 : registered operation is broken" for "this isn't a cross-app operation
 : at all" and attempts that same doomed native lookup itself.
 :
 : Distinguishes "genuinely not installed" from "installed but broken":
 : only the former gets the friendly 501. If the package's collection
 : exists but util:import-module/function-lookup still can't resolve the
 : operation (compile error, renamed function, wrong arity), that's a real
 : bug in this registry or in the target package - reported as a clean 500
 : naming the problem, rather than being misreported as "not installed" or
 : crashing on a native lookup this module was never going to satisfy.
 :
 : @param $operationId a prefixed function name from the registry, e.g. "places:json"
 : @return the resolved function, a 501 "not installed" fallback, a 500
 : "registration is broken" fallback, or the empty sequence if
 : $operationId isn't in the registry at all
 :)
declare function crossapp:resolve($operationId as xs:string) as function(*)? {
	if (not(map:contains($crossapp:registry, $operationId))) then (
	) else
		let $entry := $crossapp:registry($operationId)
		return if (not(xmldb:collection-available($entry?collection))) then
			function ($request as map(*)) {
				error(
					$errors:NOT_IMPLEMENTED,
					$entry?package || " is not installed on this deployment (operation: " || $operationId || ")"
				)
			}
		else
			let $fn := (
				util:import-module(xs:anyURI($entry?namespace-uri), $entry?prefix, xs:anyURI($entry?location)),
				function-lookup(xs:QName($operationId), $entry?arity)
			)[last()]
			return if (exists($fn)) then
				$fn
			else
				function ($request as map(*)) {
					error(
						$errors:OPERATION,
						$entry?package ||
							" is installed, but operation " ||
							$operationId ||
							" (arity " ||
							$entry?arity ||
							") could not be resolved - check modules/crossapp.xqm's registry entry"
					)
				}
};
