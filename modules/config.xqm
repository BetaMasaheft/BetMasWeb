xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
 :)
module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config";

declare namespace repo = "http://exist-db.org/xquery/repo";
declare namespace expath = "http://expath.org/ns/pkg";
declare namespace jmx = "http://exist-db.org/jmx";

import module namespace http = "http://expath.org/ns/http-client";
import module namespace loc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/loc" at "./loc.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";

declare variable $config:sparqlPrefixes :=
	"PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
         PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX lawd: <http://lawd.info/ontology/>
         PREFIX oa: <http://www.w3.org/ns/oa#>
         PREFIX ecrm: <http://erlangen-crm.org/current/>
         PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
         PREFIX gn: <http://www.geonames.org/ontology#>
         PREFIX agrelon: <http://d-nb.info/standards/elementset/agrelon.owl#>
         PREFIX rel: <http://purl.org/vocab/relationship/>
         PREFIX dcterms: <http://purl.org/dc/terms/>
         PREFIX bm: <https://betamasaheft.eu/>
         PREFIX betmas: <https://betamasaheft.eu/ontology/>
         PREFIX pelagios: <http://pelagios.github.io/vocab/terms#>
         PREFIX syriaca: <http://syriaca.org/documentation/relations.html#>
         PREFIX saws: <http://purl.org/saws/ontology#>
         PREFIX snap: <http://data.snapdrgn.net/ontology/snap#>
         PREFIX pleiades: <https://pleiades.stoa.org/>
         PREFIX wd: <https://www.wikidata.org/>
         PREFIX dc: <http://purl.org/dc/elements/1.1/>
         PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
         PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
         PREFIX t: <http://www.tei-c.org/ns/1.0>
         PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
         PREFIX foaf: <http://xmlns.com/foaf/0.1/>
         PREFIX sdc: <https://w3id.org/sdc/ontology#>";

(:
 : In practice this is `https://betamasaheft.eu/' for production and something like `localhost:8080/exist/apps/BetMasWeb` for development
 :)
(: declare variable $config:appUrl := 'https://betamasaheft.eu'; :)
declare variable $config:appUrl := $loc:appUrl;

declare variable $config:baseURI := $config:appUrl || "/";

(:~
 : Canonical Beta maṣāḥǝft URI prefix as baked into the expanded data by
 : expand.xqm (must match $expand:BMurl there). Use this to recognise and
 : strip the prefix from identifiers stored in the data (@ref, @corresp,
 : facet values, ...).
 :
 : This is deliberately NOT $config:appUrl: appUrl describes where this
 : instance is currently served (and is empty in the container), whereas
 : the data always carries this canonical prefix regardless of host.
 :)
declare variable $config:BMurl := "https://betamasaheft.eu/";

(:~
 : The path prefix the app is mounted under, for client-side JS that has to
 : build request URLs at runtime (root-absolute "/api/..." literals scattered
 : across resources/js/*.js - see BetMasWeb#32).
 :
 : Deliberately NOT $config:appUrl: appUrl describes the origin this
 : instance is served from (domain-level, empty in dev/CI containers), not
 : the path the app is mounted under *within* that origin - a client using
 : appUrl alone as a prefix would still build root-absolute "/api/..." URLs
 : in dev/CI, where the app actually lives under
 : "/exist/apps/BetMasWeb/...". In production, nginx rewrites the mount
 : path away before the request reaches eXist, so requests already arrive
 : root-absolute there and no prefix is needed - detected via the same
 : "nginx-request-uri" header controller.xql itself checks for routing.
 :
 : A function, not a module-level variable (BetMasWeb#73): a `declare
 : variable` initializer that reads request state isn't reliably
 : re-evaluated per HTTP request in eXist - if this module's binding is
 : first resolved for a request that arrived without the nginx header
 : (direct eXist access, init, REST on an internal port), it can stick at
 : the mount-path value for later, differently-fronted requests too. Same
 : pattern as controller.xql's own local:get-uri().
 :)
declare function config:appBase() as xs:string {
	if (request:get-header("nginx-request-uri")) then
		""
	else
		request:get-context-path() || "/apps/BetMasWeb"
};

(:~
 : Resolve an external service endpoint. A deployment relocates a service
 : by setting the corresponding environment variable on the eXist process
 : (e.g. `docker run -e COLLATEX_URL=...`); betmas-init captures set
 : variables into services.xml at the app root at instance initialisation, because
 : fn:environment-variable is a DBA-only read in eXist and request-time
 : code (running as guest) cannot see them. Falls back to the given
 : default (= production wiring) when the document or entry is missing.
 :)
declare function config:service-url($env-name as xs:string, $default as xs:string) as xs:string {
	try {
		(doc("/db/apps/BetMasWeb/services.xml")//service[@env eq $env-name][normalize-space(.) ne ""]/string(), $default)[1]
	} catch * { $default }
};

(:~
 : CollateX collation endpoint (env: COLLATEX_URL). The default is the
 : servlet deployment on the production host; the containerised
 : collatex-service serves the same API at http://<host>:17105/collate.
 :)
declare variable $config:collatexUrl := config:service-url(
	"COLLATEX_URL",
	"http://localhost:8081/collatex-servlet-1.7.1/collate"
);

declare variable $config:DOI := "10.25592/BetaMasaheft";

declare variable $config:ADMIN := environment-variable("ExistAdmin");

declare variable $config:ppw := environment-variable("ExistAdminPw");

declare variable $config:app-root := let $rawPath := system:get-module-load-path()
let $modulePath := (: strip the xmldb: part :) if (starts-with($rawPath, "xmldb:exist://")) then
	if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
		substring($rawPath, 36)
	else
		substring($rawPath, 15)
else
	$rawPath
return substring-before($modulePath, "/modules");

declare variable $config:app-title := "Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea";

declare variable $config:xslt-root := $config:app-root || "/xslt";

declare variable $config:bmdata-root := "/db/apps/BetMasData";

declare variable $config:data-root := "/db/apps/expanded";

declare variable $config:add-data-root := "/db/apps/expanded";

declare variable $config:schema-root := $config:app-root || "/schema";

declare variable $config:data-rootMS := $config:data-root || "/manuscripts";

declare variable $config:data-rootN := $config:data-root || "/narratives";

declare variable $config:data-rootW := $config:data-root || "/works";

declare variable $config:data-rootS := $config:data-root || "/studies";

declare variable $config:data-rootPl := $config:data-root || "/places";

declare variable $config:data-rootPr := $config:data-root || "/persons";

declare variable $config:data-rootIn := $config:data-root || "/institutions";

declare variable $config:data-rootA := $config:data-root || "/authority-files";

declare variable $config:data-rootCh := $config:bmdata-root || "/Chojnacki";

declare variable $config:data-rootTraces := $config:app-root || "/traces";

declare variable $config:repo-descriptor := doc(concat($config:app-root, "/repo.xml"))/repo:meta;

declare variable $config:expath-descriptor := doc(concat($config:app-root, "/expath-pkg.xml"))/expath:package;

(:~
 : Injects the config:appBase() value as a client-side global, for the
 : standalone page-wrapper templates (newpage.html, newindex2.html,
 : newsearch.html, sparql.html) that build their own <head> rather than
 : going through modules/scriptlinks.xqm's scriptStyle()/listScriptStyle()
 : (which inject it themselves). Call like
 : <script data-template="config:appBaseScript" />.
 :)
declare function config:appBaseScript($node as node(), $model as map(*)) as element(script) {
	<script type="text/javascript">{ 'var appBase = "' || config:appBase() || '";' }</script>
};

(:~
 : Call like <a data-template="config:prefix-href"  data-template-href="/bladiblah"/>
 : Results in <a href="whatevertheprefixis/bladiblah"/>
 :)
declare function config:prefix-href($node as node(), $model as map(*), $href as xs:string) as element(*) {
	element {name($node)} {
		attribute href { $config:appUrl || $href },
		$node/@* except ($node/@data-template, $node/@data-template-href),
		$node/node()!templates:process(., $model)
	}
};

(:~
 : Call like <script data-template="config:prefix-src"  data-template-src="/bladiblah"/>
 : Results in <script src="whatevertheprefixis/bladiblah"/>
 :)
declare function config:prefix-src($node as node(), $model as map(*), $src as xs:string) as element(*) {
	element {name($node)} {
		attribute src { $config:appUrl || $src },
		$node/@* except ($node/@data-template, $node/@data-template-src),
		$node/node()!templates:process(., $model)
	}
};

(:~
 : Resolve the given path using the current application context.
 : If the app resides in the file system,
 :)
declare function config:resolve($relPath as xs:string) {
	if (starts-with($config:app-root, "/db")) then
		doc(concat($config:app-root, "/", $relPath))
	else
		doc(concat("file://", $config:app-root, "/", $relPath))
};

(:~
 : Shared templates:apply config map. CONFIG_FILTER_ATTRIBUTES applies
 : app-wide, to every %templates:wrap function, not just one caller -
 : %templates:wrap always keeps its calling element's own data-template
 : attribute in the output by default, so there's no narrower scope to
 : give this flag. Confirmed safe app-wide, including fixing a
 : pre-existing data-template leak in lists:titlesRes (see "invert
 : templates:surround to a top-down render").
 :
 : @return the config map for templates:apply's 4th argument
 :)
declare function config:template-apply-config() as map(*) {
	map {
		$templates:CONFIG_STOP_ON_ERROR: true(),
		$templates:CONFIG_USE_CLASS_SYNTAX: false(),
		$templates:CONFIG_FILTER_ATTRIBUTES: true()
	}
};

(:~
 : Shared warn-vs-pass-through decision for the lookup function every
 : templates:apply call site passes in. templates:resolve() probes arity
 : 2..$templates:MAX_ARITY; only the last arity coming up empty means
 : "genuinely no such function" rather than "wrong arity, keep trying",
 : so that's the one point to log. Without this, a typo'd/removed
 : data-template target fails silently with no trace.
 :
 : Takes the already-probed $fn rather than calling function-lookup()
 : itself: function-lookup() resolves against the STATIC context of the
 : module it's written in, so a shared probe here could only ever see
 : functions imported into config.xqm, not e.g. item2:* or viewItem:*
 : targets. Each call site still runs its own
 : `try { function-lookup(...) } catch * { () }` and hands the result
 : here.
 :
 : @param $moduleLabel  calling module's name, for the log message
 : @param $functionName the data-template target name being resolved
 : @param $arity        the arity just probed
 : @param $fn           result of that probe - the resolved function, or ()
 : @return $fn unchanged, or () after logging on the terminal probe
 :)
declare function config:template-lookup-resolve(
	$moduleLabel as xs:string,
	$functionName as xs:string,
	$arity as xs:integer,
	$fn as function(*)?
) as function(*)? {
	if (empty($fn) and $arity = $templates:MAX_ARITY) then (
		(: logging itself must never take the template pipeline down :)
		try {
			util:log(
				"warn",
				$moduleLabel ||
					': no function found for data-template="' ||
					$functionName ||
					'" (probed arity 2..' ||
					$templates:MAX_ARITY ||
					")"
			)
		} catch * { () },
		()
	) else
		$fn
};

declare function config:get-configuration() as element(configuration) {
	doc(concat($config:app-root, "/configuration.xml"))/configuration
};

(:~
 : Returns the repo.xml descriptor for the current application.
 :)
declare function config:repo-descriptor() as element(repo:meta) {
	$config:repo-descriptor
};

(:~
 : Returns the expath-pkg.xml descriptor for the current application.
 :)
declare function config:expath-descriptor() as element(expath:package) {
	$config:expath-descriptor
};

declare %templates:wrap function config:app-title($node as node(), $model as map(*)) as text() {
	$config:expath-descriptor/expath:title/text()
};

declare function config:app-meta-rest() {
	<meta
		xmlns="http://www.w3.org/1999/xhtml"
		content="{ $config:repo-descriptor/repo:description/text() }"
		name="description" />,
	for $author in $config:repo-descriptor/repo:author
	return <meta xmlns="http://www.w3.org/1999/xhtml" content="{ $author/text() }" name="creator" />
};

declare function config:app-meta($node as node(), $model as map(*)) as element()* {
	<meta
		xmlns="http://www.w3.org/1999/xhtml"
		content="{ $config:repo-descriptor/repo:description/text() }"
		name="description" />,
	for $author in $config:repo-descriptor/repo:author
	return <meta xmlns="http://www.w3.org/1999/xhtml" content="{ $author/text() }" name="creator" />
};

(:~
 : For debugging: generates a table showing all properties defined
 : in the application descriptors.
 :)
declare function config:app-info($node as node(), $model as map(*)) {
	let $expath := config:expath-descriptor()
	let $repo := config:repo-descriptor()
	return <table class="app-info">
		<tr><td>app collection:</td><td>{ $config:app-root }</td></tr>
		{
			for $attr in ($expath/@*, $expath/*, $repo/*)
			return <tr><td>{ node-name($attr) }:</td><td>{ $attr/string() }</td></tr>
		}
		<tr><td>Controller:</td><td>{ request:get-attribute("$exist:controller") }</td></tr>
	</table>
};

declare function config:get-data-dir() as xs:string? {
	try {
		let $request := <http:request
			href="http://localhost:8080/{ request:get-context-path() }/status?c=disk"
			http-version="1.1"
			method="GET" />
		let $response := http:send-request($request)
		return if ($response[1]/@status eq "200") then
			let $dir := $response[2]//jmx:DataDirectory/string()
			return if (matches($dir, "^\w:")) then
				(: windows path? :)
				"/" || translate($dir, "\", "/")
			else
				$dir
		else (
		)
	} catch * { () }
};

declare function config:get-repo-dir() {
	let $dataDir := config:get-data-dir()
	let $pkgRoot := $config:expath-descriptor/@abbrev || "-" || $config:expath-descriptor/@version
	return if ($dataDir) then
		$dataDir || "/expathrepo/fonts-0.1"
	else (
	)
};

declare function config:get-fonts-dir() as xs:string? {
	let $repoDir := config:get-repo-dir()
	return if ($repoDir) then
		$repoDir || "/fonts"
	else (
	)
};

declare function config:distinct-values($values) {
	for $value in $values
	group by $value
	return $value
};
