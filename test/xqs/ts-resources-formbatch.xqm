xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for the batch-title fix applied to /titles', /calendar's and
 : /bindings' filter-picker forms (lists:titlesform, lists:calendarform,
 : lists:bindingsform) - same N+1 as q:facetDiv/lists:decoRes/
 : lists:titlesRes, and the same fix (lists:batch-resolve-titles()).
 : lists:additionsform/lists:decorationsform were upgraded too but
 : already had XQSuite coverage of the underlying resolve-title
 : mechanism (see ts-resources-titlelookup.xqm) - not duplicated here.
 :)
module namespace tsformbatch = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-resources-formbatch";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "../../modules/resources.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

(: real, stable id with no pre-existing cache/TUList/persNames entry,
verified live before picking it - same id ts-queries-facetdiv.xqm and
ts-resources-titlesres.xqm use. :)
declare variable $tsformbatch:real-id := "AT1002Annunciation";

declare variable $tsformbatch:real-title := "Annunciation";

declare %private function tsformbatch:fixture-with-authfile-ref($msid as xs:string) as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="{ $msid }">
		<text>
			<body>
				<decoNote type="test-type" xml:id="{ $msid }deco1">
					<ref corresp="{ $config:BMurl }{ $tsformbatch:real-id }" type="authFile" />
				</decoNote>
			</body>
		</text>
	</TEI>
};

declare %test:assertEquals("Annunciation") function tsformbatch:titlesform-resolves-authfile-option-via-batch() {
	let $fixture := tsformbatch:fixture-with-authfile-ref("MSTESTformbatchTitles77")
	let $form := lists:titlesform(<a />, map {"hits": $fixture//t:decoNote})
	return string(($form//*:select[@id = "target-artTheme"]/*:option)[1])
};

declare %test:assertEquals("Annunciation") function tsformbatch:calendarform-resolves-authfile-option-via-batch() {
	let $fixture := tsformbatch:fixture-with-authfile-ref("MSTESTformbatchCal77")
	let $form := lists:calendarform(<a />, map {"hits": $fixture//t:decoNote})
	return string(($form//*:select[@id = "target-artTheme"]/*:option)[1])
};

declare %test:assertEquals("Annunciation") function tsformbatch:bindingsform-resolves-keyword-option-via-batch() {
	let $fixture := <TEI xmlns="http://www.tei-c.org/ns/1.0" xml:id="MSTESTformbatchBind77">
		<text>
			<body>
				<decoNote type="test-type" xml:id="d1"><term key="{ $config:BMurl }{ $tsformbatch:real-id }" /></decoNote>
			</body>
		</text>
	</TEI>
	let $form := lists:bindingsform(<a />, map {"hits": $fixture//t:decoNote})
	return string(($form//*:select[@id = "target-keyword"]/*:option)[1])
};
