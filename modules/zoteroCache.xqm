xquery version "3.1" encoding "UTF-8";

(:~
 : Lookups into the EthioStudies citation caches.
 : Always use doc() on a named file: several citation XML files share @tag
 : and collection() would mix HLCEES with with-url-doi.
 :)
module namespace zc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/zc";

declare variable $zc:root := "/db/apps/EthioStudies/";

declare function zc:bib($file as xs:string, $tag as xs:string) {
	doc($zc:root || $file)//*[@tag = $tag]//*:div[@class = "csl-entry"]
};

declare function zc:cit($file as xs:string, $tag as xs:string) {
	doc($zc:root || $file)//*[@tag = $tag]/node()
};
