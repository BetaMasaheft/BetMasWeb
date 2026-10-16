xquery version "3.1" encoding "UTF-8";

(:~
 : Hermetic coverage of catalog-oracle-lib (parity oracle bibl presence).
 :)
module namespace tsoracle = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-catalog-oracle";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace b = "betmas.biblio";

import module namespace oraclelib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-oracle-lib" at "catalog-oracle-lib.xqm";

declare %test:assertEquals("hit") function tsoracle:bibl-presence-nonempty-citation() as xs:string {
	oraclelib:bibl-presence(<entry xmlns="betmas.biblio" id="bm:Example1979"><citation>Example 1979</citation></entry>)
};

declare %test:assertEquals("") function tsoracle:bibl-presence-blank-citation() as xs:string {
	oraclelib:bibl-presence(<entry xmlns="betmas.biblio" id="bm:EmptyCite"><citation /></entry>)
};

declare %test:assertEquals("") function tsoracle:bibl-presence-missing-citation-element() as xs:string {
	oraclelib:bibl-presence(<entry xmlns="betmas.biblio" id="bm:NoCite" />)
};

declare %test:assertEquals("") function tsoracle:bibl-presence-empty-sequence() as xs:string {
	oraclelib:bibl-presence(())
};

declare %test:assertTrue function tsoracle:valid-review-neutral() as xs:boolean {
	oraclelib:valid-review(<mismatch triage="neutral" />)
};

declare %test:assertFalse function tsoracle:valid-review-missing-triage() as xs:boolean {
	oraclelib:valid-review(<mismatch />)
};

declare %test:assertTrue function tsoracle:review-covers-without-pins() as xs:boolean {
	oraclelib:review-covers(<mismatch triage="better" />, "", "hit")
};

declare %test:assertTrue function tsoracle:review-covers-matching-pins() as xs:boolean {
	oraclelib:review-covers(<mismatch backendA="" backendB="hit" triage="better" />, "", "hit")
};

declare %test:assertFalse function tsoracle:review-covers-inverted-pins() as xs:boolean {
	oraclelib:review-covers(<mismatch backendA="" backendB="hit" triage="better" />, "hit", "")
};
