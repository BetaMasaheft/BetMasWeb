xquery version "3.1" encoding "UTF-8";

(:~
 : Thin helpers around Roaster/router response maps.
 : Prefer these over ad-hoc map key strings so in-process code stays aligned
 : with how router.xql detects and reads responses.
 :)
module namespace rutil = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/rutil";

declare namespace http = "http://expath.org/ns/http-client";

import module namespace router = "http://e-editiones.org/roaster/router";

(:~
 : True when $value is a Roaster response map (same test as router.xql).
 :)
declare function rutil:is-response($value as item()?) as xs:boolean {
	exists($value) and
		$value instance of map(*) and
		(map:contains($value, $router:RESPONSE_CODE) or map:contains($value, $router:RESPONSE_BODY))
};

(:~
 : Body of a Roaster response map, or $value unchanged (e.g. TEI, EXPath body).
 :)
declare function rutil:body($value as item()*) as item()* {
	if (count($value) eq 1 and rutil:is-response($value)) then
		$value($router:RESPONSE_BODY)
	else
		$value
};

(:~
 : Named header from a Roaster RESPONSE_HEADERS map, or from an EXPath
 : http:send-request sequence that still carries http:header elements.
 :)
declare function rutil:header($value as item()*, $name as xs:string) as xs:string? {
	if (count($value) eq 1 and rutil:is-response($value)) then
		let $headers := $value($router:RESPONSE_HEADERS)
		return ($headers?($name), $headers?(lower-case($name)))[normalize-space(string(.)) ne ""][1]!string(.)
	else
		($value//http:header[lower-case(@name) = lower-case($name)]/string(@value))[normalize-space(.) ne ""][1]
};
