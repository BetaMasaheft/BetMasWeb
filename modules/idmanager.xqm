xquery version "3.1" encoding "UTF-8";

(:~
 : Client for the betmas-id-manager REST service - hands out and tracks
 : entity ids, replacing the inline scan-and-increment logic that used to
 : live in edit/save-new-entity.xql. See
 : https://github.com/BetaMasaheft/betmas-id-manager
 :)
module namespace idmanager = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/idmanager";

declare namespace http = "http://expath.org/ns/http-client";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

(:~
 : POSTs/GETs against the id-manager and normalizes its response into
 : map { "status": xs:integer, "body": map(*)? }. Network-level failures
 : (service unreachable, timeout) surface as status 503 rather than an
 : uncaught error, so callers only need to branch on $result?status.
 :)
declare %private function local:send($method as xs:string, $path as xs:string, $body as map(*)?) as map(*) {
	let $href := $config:idManagerUrl || $path
	let $bodyJson := if (exists($body)) then
		serialize($body, map {"method": "json"})
	else (
	)
	let $request := <http:request href="{ xs:anyURI($href) }" http-version="1.1" method="{ $method }">
		<http:header name="Accept" value="application/json" />
		{
			if (exists($bodyJson)) then (
				<http:header name="Content-Type" value="application/json" />,
				<http:body media-type="application/json" method="text">{ $bodyJson }</http:body>
			) else (
			)
		}
	</http:request>
	return try {
		let $response := http:send-request($request)
		let $status := xs:integer($response[1]/@status)
		let $rawBody := $response[2]
		let $decoded := if (empty($rawBody)) then (
		) else (
			try { util:base64-decode(string-join($rawBody)) } catch * { string-join($rawBody) }
		)
		let $json := if (exists($decoded) and string-length($decoded) gt 0) then
			try { parse-json($decoded) } catch * { () }
		else (
		)
		return map {"status": $status, "body": $json}
	} catch * {
		let $_ := util:log("error", "idmanager:send - " || $method || " " || $href || " failed: " || $err:description)
		return map {"status": 503, "body": map {"error": $err:description}}
	}
};

(:~
 : Reserve a new id for an auto-numbered type (works, studies, narratives,
 : persons, places, institutions). Returns the id-manager's response
 : envelope - callers check ?status (201 success, 400 unknown type, 503
 : service unreachable) and read the issued id from ?body?id.
 :)
declare function idmanager:reserve-auto($type as xs:string, $suffix as xs:string?) as map(*) {
	local:send("POST", "/ids/" || encode-for-uri($type), map {"suffix": $suffix})
};

(:~
 : Register a caller-chosen id for a manual type (manuscripts,
 : authority-files). ?status 201 success, 400 unknown type/unsafe id, 409
 : already registered, 503 service unreachable.
 :)
declare function idmanager:register-manual($type as xs:string, $id as xs:string?) as map(*) {
	local:send("POST", "/ids/" || encode-for-uri($type), map {"id": $id})
};

(:~
 : Look up a previously issued id. ?status 200 found, 404 unknown, 503
 : service unreachable.
 :)
declare function idmanager:get-id($id as xs:string) as map(*) {
	local:send("GET", "/id/" || encode-for-uri($id), ())
};

(:~
 : List known types and their prefix/mode. Used by the seeding script to
 : discover the auto/manual split from the id-manager itself rather than
 : hardcoding it a second time here.
 :)
declare function idmanager:list-types() as map(*) {
	local:send("GET", "/types", ())
};

(:~
 : Admin/seeding operation: set a type's counter (auto types only).
 :)
declare function idmanager:reset-counter($type as xs:string, $value as xs:integer?) as map(*) {
	local:send(
		"POST",
		"/types/" || encode-for-uri($type) || "/reset",
		if (exists($value)) then
			map {"value": $value}
		else
			map {}
	)
};

(:~
 : Admin/seeding operation: bulk-register ids that already exist elsewhere
 : (manual types only). Idempotent - safe to re-run/resume.
 :)
declare function idmanager:seed-manual($type as xs:string, $ids as xs:string*) as map(*) {
	local:send("POST", "/types/" || encode-for-uri($type) || "/seed", map {"ids": array { $ids }})
};
