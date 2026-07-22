xquery version "3.1";

declare namespace sm = "http://exist-db.org/xquery/securitymanager";

declare variable $target external;

util:eval(xs:anyURI("/db/apps/BetMasService/modules/registerRESTXQ.xql")),
(: Create the groups needed in this app :)
for $group in ("Editors", "Cataloguers")
where not(sm:group-exists($group))
return sm:create-group($group),
(: Create logging collection. TODO: remove the use of it :)
if (not(xmldb:collection-available("/db/apps/log"))) then
	xmldb:create-collection("/db/apps", "log")
else (
),
(: Create placeholders. The real corpus (betmas-data image, or a dev
   instance with expanded.xar installed) already has /db/apps/expanded/*,
   so this is normally a no-op; on a bare instance (e.g. install-smoke CI,
   no data package involved) xmldb:create-collection requires each parent
   to exist first, so walk the path down instead of assuming it's there. :)
if (not(xmldb:collection-available("/db/apps/expanded"))) then
	xmldb:create-collection("/db/apps", "expanded")
else (
),
for $name in ("authority-files", "manuscripts", "institutions", "narratives", "persons", "places", "studies", "works")
let $col := "/db/apps/expanded/" || $name
return (
	if (not(xmldb:collection-available($col))) then
		xmldb:create-collection("/db/apps/expanded", $name)
	else (
	),
	if (not(xmldb:collection-available($col || "/new"))) then
		xmldb:create-collection($col, "new")
	else (
	)
)
(:
 TODO: in a cronjob persist users to a volume
 When running this finish, sync users to the database
 :) 