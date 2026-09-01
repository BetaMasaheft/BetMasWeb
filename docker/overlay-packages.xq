xquery version "3.1";

(: Replace any base-image copy of BetMasService, parser, and BetMasWeb with
   this build's xars. exist-db/exist#5579: AutoDeploymentTrigger skips
   already-installed names (enforceDeps=false). repo:install-and-deploy-from-db
   sets enforceDeps=true.

   Runs in the same client -F as the admin seed: eval SEED_XQ from the build
   secret first (repo.xml permissions user="BetaMasaheftAdmin"), then overlay
   in install order (Service → parser → Web). Errors if a deployed package
   version or content canary does not match this build. :)

declare function local:want-version($expath-file as xs:string) as xs:string {
	string(parse-xml(file:read($expath-file))/*:package/@version)
};

declare function local:overlay-package(
	$pkg as xs:string,
	$abbrev as xs:string,
	$xar as xs:string,
	$expath-file as xs:string,
	$canary-doc as xs:string?,
	$canary-text as xs:string?
) as item()* {
	if (repo:list() = $pkg) then (
		repo:undeploy($pkg), repo:remove($pkg)
	) else (
	),
	let $col := if (xmldb:collection-available("/db/tmp")) then
		"/db/tmp"
	else
		xmldb:create-collection("/db", "tmp")
	let $xar-name := $abbrev || ".xar"
	let $stored := xmldb:store($col, $xar-name, file:read-binary($xar))
	let $status := repo:install-and-deploy-from-db($stored)
	let $_ := xmldb:remove($col, $xar-name)
	let $want := local:want-version($expath-file)
	let $got := string(doc("/db/apps/" || $abbrev || "/expath-pkg.xml")/*:package/@version)
	return if ($got ne $want) then
		error(xs:QName("local:overlay-stale"), $abbrev || " overlay deployed " || $got || ", expected " || $want)
	else if ($canary-doc and $canary-text) then
		let $src := util:binary-to-string(util:binary-doc($canary-doc))
		return if (not(contains($src, $canary-text))) then
			error(xs:QName("local:overlay-stale"), $abbrev || " overlay canary missing: " || $canary-text)
		else
			$status
	else
		$status
};

util:eval(file:read("/run/secrets/seed.xq")),
local:overlay-package(
	"https://betamasaheft.eu/BetMasService",
	"BetMasService",
	"/exist/overlay/BetMasService.xar",
	"/exist/overlay/BetMasService-expath-pkg.xml",
	"/db/apps/BetMasService/modules/registerRESTXQ.xql",
	"registerRESTXQ"
),
local:overlay-package(
	"http://betamasaheft.aai.uni-hamburg.de/parser/",
	"parser",
	"/exist/overlay/parser.xar",
	"/exist/overlay/parser-expath-pkg.xml",
	(),
	()
),
local:overlay-package(
	"https://betamasaheft.eu/betmasweb/",
	"BetMasWeb",
	"/exist/overlay/BetMasWeb.xar",
	"/exist/overlay/BetMasWeb-expath-pkg.xml",
	"/db/apps/BetMasWeb/modules/queries.xqm",
	"q:ms-parts-count-filter"
)
