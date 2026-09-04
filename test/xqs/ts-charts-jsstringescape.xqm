xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for charts:js-string-escape (modules/charts.xqm), the helper
 : charts:support-column-chart uses to embed corpus text inside an inline
 : <script>'s JS string literals. Most of that function's six callers pass
 : controlled-vocabulary @key/@form values, but one (SewingStations) passes
 : raw t:decoNote free text - real corpus values are cataloguer prose with
 : embedded newlines/indentation (e.g. "4\n                                "),
 : which breaks the JS string literal outright and takes down the whole
 : page's script execution. These tests pin the escaping/normalizing
 : behaviour so that regression can't recur silently.
 :)
module namespace tsjsescape = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-charts-jsstringescape";

declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "../../modules/charts.xqm";

declare %test:assertEquals("") function tsjsescape:empty-sequence-becomes-empty-string() {
	charts:js-string-escape(())
};

declare %test:assertEquals("hello") function tsjsescape:plain-text-unchanged() {
	charts:js-string-escape("hello")
};

declare %test:assertEquals("4") function tsjsescape:trailing-newline-and-indentation-collapsed() {
	(:
	 : the actual shape found live: a "4" decoNote value serialized with a
	 : trailing newline + indentation from the source TEI's mixed content
	 :)
	charts:js-string-escape("4" || codepoints-to-string(10) || "                                ")
};

declare %test:assertEquals("line one line two") function tsjsescape:embedded-newline-becomes-space() {
	charts:js-string-escape("line one" || codepoints-to-string(10) || "line two")
};

declare %test:assertEquals("a\\b") function tsjsescape:backslash-is-escaped() {
	charts:js-string-escape("a\b")
};

declare %test:assertEquals('say \"hi\"') function tsjsescape:double-quote-is-escaped() {
	charts:js-string-escape('say "hi"')
};

declare %test:assertEquals("<\/script><script>alert(1)<\/script>") function tsjsescape:script-close-neutralized() {
	charts:js-string-escape("</script><script>alert(1)</script>")
};

declare %test:assertEquals("<\/SCRIPT>") function tsjsescape:script-close-neutralized-case-insensitively() {
	charts:js-string-escape("</SCRIPT>")
};
