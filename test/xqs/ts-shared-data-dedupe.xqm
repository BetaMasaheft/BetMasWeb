xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for shared-data dedupe: dts aliases dtslib JSON-LD maps,
 : expand loads calendarDesc from calendars/, newEntry loads relation
 : options from newEntryRelations.xml — no hardcoded twins.
 :)
module namespace tsshareddedupe = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-shared-data-dedupe";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace dtslib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib" at "../../modules/dtslib.xqm";
import module namespace dts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dts" at "../../modules/dts.xqm";
import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";
import module namespace new = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/new" at "../../modules/newEntry.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

(:~
 : dts JSON-LD @context must be the dtslib map (single source).
 :)
declare %test:assertTrue function tsshareddedupe:dts-context-aliases-dtslib() {
	deep-equal($dts:context, $dtslib:context)
};

declare %test:assertTrue function tsshareddedupe:dts-publisher-aliases-dtslib() {
	deep-equal($dts:publisher, $dtslib:publisher)
};

declare %test:assertTrue function tsshareddedupe:dts-regexCol-aliases-dtslib() {
	$dts:regexCol eq $dtslib:regexCol
};

declare %test:assertTrue function tsshareddedupe:dts-regexID-aliases-dtslib() {
	$dts:regexID eq $dtslib:regexID
};

(:~
 : Injected calendarDesc matches calendars/calendarDesc.xml (not a twin).
 :)
declare %test:assertTrue function tsshareddedupe:calendarDesc-from-app-file() {
	let $fromFile := doc($config:app-root || "/calendars/calendarDesc.xml")/t:calendarDesc
	return deep-equal($expand:calendarDesc, $fromFile)
};

declare %test:assertEquals(9) function tsshareddedupe:calendarDesc-has-nine-calendars() {
	count($expand:calendarDesc/t:calendar)
};

declare %test:assertTrue function tsshareddedupe:tei-injects-file-calendar-ids() {
	let $ids := $expand:calendarDesc/t:calendar/@xml:id/string()
	let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITTESTcalFile">
		<teiHeader>
			<titleStmt><title>seed</title></titleStmt>
			<profileDesc><abstract><p>a</p></abstract></profileDesc>
		</teiHeader>
		<text><body><div><ab>x</ab></div></body></text>
	</TEI>
	let $out := expand:tei2fulltei($tei, ())
	return deep-equal($out//t:calendar/@xml:id/string(), $ids)
};

(:~
 : new-entry relation options come from newEntryRelations.xml.
 :)
declare %test:assertTrue function tsshareddedupe:newEntry-relations-from-app-file() {
	let $fromFile := doc($config:app-root || "/newEntryRelations.xml")/relationOptions
	return deep-equal($new:relationOptions, $fromFile)
};

declare %test:assertEquals(25) function tsshareddedupe:newEntry-relations-count() {
	count($new:relationOptions/option)
};

declare %test:assertTrue function tsshareddedupe:newEntry-includes-ecrm-p129() {
	$new:relationOptions/option = "ecrm:P129_is_about"
};
