xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite regression tests for $dtslib:regexID / $dts:regexID.
 : https://github.com/BetaMasaheft/BetMasWeb/issues/40 - with every capture
 : group optional, the pattern could match a zero-length string, and
 : fn:analyze-string() forbids that outright (err:FORX0003) regardless of
 : the input passed in. The fix made the leading id group mandatory;
 : these tests call the real analyze-string() entry points on both the
 : dtslib and dts namespaces (dts:regexID only aliases dtslib:regexID
 : today, but each is a separate live call path) to guard against either
 : regressing back to an all-optional pattern.
 :)
module namespace tsdtsregex = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-dtslib-regexid";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace dtslib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib" at "../../modules/dtslib.xqm";
import module namespace dts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dts" at "../../modules/dts.xqm";

declare %test:assertEquals("analyze-string-result") function tsdtsregex:dtslib-parseDTSid-does-not-throw() {
	local-name(dtslib:parseDTSid("ESdz010.1"))
};

declare %test:assertEquals("analyze-string-result") function tsdtsregex:dtslib-parseDTS-does-not-throw() {
	local-name(dtslib:parseDTS("ESdz010.1"))
};

declare %test:assertEquals("analyze-string-result") function tsdtsregex:dts-parseDTSid-does-not-throw() {
	local-name(dts:parseDTSid("ESdz010.1"))
};

declare %test:assertEquals("analyze-string-result") function tsdtsregex:dts-parseDTS-does-not-throw() {
	local-name(dts:parseDTS("ESdz010.1"))
};

(:~
 : Shortest possible id (a single alphanumeric character, nothing else) is
 : the tightest exercise of the "leading group is mandatory" invariant.
 :)
declare %test:assertEquals("analyze-string-result") function tsdtsregex:dtslib-parseDTSid-single-char-does-not-throw() {
	local-name(dtslib:parseDTSid("a"))
};
