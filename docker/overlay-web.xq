xquery version "3.1";

(: Replace BETMAS_APP_IMAGE's BetMasWeb with this build's xar.
   exist-db/exist#5579: AutoDeploymentTrigger skips already-installed names
   (enforceDeps=false). repo:install-and-deploy-from-db sets enforceDeps=true.

   Runs in the same client -F as the admin seed: eval SEED_XQ from the build
   secret first (repo.xml permissions user="BetaMasaheftAdmin"), then overlay.
   Errors if the deployed package is still the base image's copy. :)

declare variable $local:pkg := "https://betamasaheft.eu/betmasweb/";

declare variable $local:xar := "/exist/overlay/BetMasWeb.xar";

declare variable $local:want := string(parse-xml(file:read("/exist/overlay/expath-pkg.xml"))/*:package/@version);

util:eval(file:read("/run/secrets/seed.xq")),
if (repo:list() = $local:pkg) then (
	repo:undeploy($local:pkg), repo:remove($local:pkg)
) else (
),
let $col := if (xmldb:collection-available("/db/tmp")) then
	"/db/tmp"
else
	xmldb:create-collection("/db", "tmp")
let $stored := xmldb:store($col, "BetMasWeb.xar", file:read-binary($local:xar))
let $status := repo:install-and-deploy-from-db($stored)
let $_ := xmldb:remove($col, "BetMasWeb.xar")
let $got := string(doc("/db/apps/BetMasWeb/expath-pkg.xml")/*:package/@version)
let $src := util:binary-to-string(util:binary-doc("/db/apps/BetMasWeb/modules/queries.xqm"))
return if ($got ne $local:want) then
	error(xs:QName("local:overlay-stale"), "BetMasWeb overlay deployed " || $got || ", expected " || $local:want)
else if (not(contains($src, "q:ms-parts-count-filter"))) then
	error(xs:QName("local:overlay-stale"), "BetMasWeb overlay canary missing: q:ms-parts-count-filter")
else
	$status
