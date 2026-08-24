xquery version "3.1" encoding "UTF-8";

(:~
 : Lookups into the EthioStudies citation caches.
 : Always use doc() on a named file: several citation XML files share @tag
 : and collection() would mix HLCEES with with-url-doi.
 :)
module namespace zc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/zc";

declare variable $zc:root := "/db/apps/EthioStudies/";

(: try/catch so a missing/unreadable cache file falls back to live Zotero
instead of breaking the caller - the EthioStudies xar this reads from is an
optional dependency (see BetaMasaheft/bibliography#18, BetMas#149) :)
declare function zc:bib($file as xs:string, $tag as xs:string) {
	try { doc($zc:root || $file)//*[@tag = $tag]//*:div[@class = "csl-entry"] } catch * { () }
};

(: (...)[1]: @tag is meant to be unique within one file (verified against the
real citation files - no duplicates today), but is reused across files, so
guard against a future duplicate silently concatenating two citations'
content together with no separator :)
declare function zc:cit($file as xs:string, $tag as xs:string) {
	try { (doc($zc:root || $file)//*[@tag = $tag])[1]/node() } catch * { () }
};
