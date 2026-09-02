xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for lists:titlesRes (modules/resources.xqm) - the /titles
 : page's results renderer. Had the same per-item N+1 as q:facetDiv/
 : lists:decoRes (BetMasWeb#3/#125): exptit:printTitle() once per
 : manuscript group, work ref and authFile ref, plus a redundant
 : collection-wide id() lookup for a document already reachable via
 : root() on a node in hand.
 :)
module namespace tstitlesres = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-resources-titlesres";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists" at "../../modules/resources.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "../../modules/config.xqm";

(: real, stable id with no pre-existing cache/TUList/persNames entry,
verified live before picking it - same id ts-queries-facetdiv.xqm uses. :)
declare variable $tstitlesres:real-id := "AT1002Annunciation";

declare variable $tstitlesres:real-title := "Annunciation";

(:~
 : "mss" itemtype fixture: a manuscript with one msItem, one colophon
 : referencing it (for the work-ref path) and carrying an authFile ref.
 :)
declare %private function tstitlesres:mss-fixture($msid as xs:string) as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="{ $msid }">
		<teiHeader>
			<fileDesc>
				<sourceDesc><msDesc><msIdentifier><idno>{ $msid }-shelfmark</idno></msIdentifier></msDesc></sourceDesc>
			</fileDesc>
		</teiHeader>
		<text>
			<body>
				<msItem xml:id="{ $msid }item1">
					<title ref="{ $config:BMurl }{ $tstitlesres:real-id }" />
					<colophon xml:id="{ $msid }col1">
						<ref corresp="{ $config:BMurl }{ $tstitlesres:real-id }" type="authFile" />
					</colophon>
				</msItem>
			</body>
		</text>
	</TEI>
};

(:~
 : Colophon carries @corresp to another msItem, but the renderer's
 : colophon branch reads the ancestor msItem's work ref - batch must
 : prefetch both shapes, not only the corresp-matched one.
 :)
declare %private function tstitlesres:mss-fixture-colophon-with-corresp($msid as xs:string) as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="{ $msid }">
		<teiHeader>
			<fileDesc>
				<sourceDesc><msDesc><msIdentifier><idno>{ $msid }-shelfmark</idno></msIdentifier></msDesc></sourceDesc>
			</fileDesc>
		</teiHeader>
		<text>
			<body>
				<msItem xml:id="{ $msid }item1">
					<title ref="{ $config:BMurl }{ $tstitlesres:real-id }" />
					<colophon corresp="{ $msid }item2" xml:id="{ $msid }col1">placeholder</colophon>
				</msItem>
				<msItem xml:id="{ $msid }item2"><title ref="{ $config:BMurl }INSTESTtitlesresCorrespMiss77" /></msItem>
			</body>
		</text>
	</TEI>
};

(:~
 : "work" itemtype fixture: a bare div, no msItem needed - its own
 : group-level $ms id is resolved directly.
 :)
declare %private function tstitlesres:work-fixture($workid as xs:string) as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="{ $workid }">
		<text><body><div xml:id="{ $workid }div1" /></body></text>
	</TEI>
};

declare %private function tstitlesres:model($hits as element()*) as map(*) {
	map {"typeGroups": map {"test-tag": $hits}}
};

(:~
 : The manuscript-group idno resolves via root() on an already-held
 : hit node, not a collection() the test never populates.
 :)
declare
	%test:assertEquals("MSTESTtitlesresPlain77-shelfmark")
function tstitlesres:resolves-msidentifier-without-a-collection() {
	let $fixture := tstitlesres:mss-fixture("MSTESTtitlesresPlain77")
	let $result := lists:titlesRes(<a />, tstitlesres:model($fixture//t:colophon), 1, 20)
	return string(($result//*:idno)[1])
};

(:~
 : A real, uncached authFile ref resolves via the batched lookup.
 :)
declare %test:assertEquals("Annunciation, ") function tstitlesres:resolves-authfile-title-via-batch() {
	let $fixture := tstitlesres:mss-fixture("MSTESTtitlesresAuth77")
	let $result := lists:titlesRes(<a />, tstitlesres:model($fixture//t:colophon), 1, 20)
	return string(($result//*:a[contains(@href, $tstitlesres:real-id)])[1])
};

(:~
 : A real, uncached work ref (t:msItem/t:title/@ref) resolves via the
 : batched lookup, for the colophon/incipit/explicit/title branch.
 :)
declare %test:assertEquals("Annunciation") function tstitlesres:resolves-workref-title-via-batch() {
	let $fixture := tstitlesres:mss-fixture("MSTESTtitlesresWork77")
	let $result := lists:titlesRes(<a />, tstitlesres:model($fixture//t:colophon), 1, 20)
	return string(($result//*:div[*:span][contains(., "Refers to")]/*:span)[1])
};

(:~
 : With @corresp on the colophon, the ancestor msItem's work ref still
 : resolves (not the corresp-target msItem's ref).
 :)
declare %test:assertEquals("Annunciation") function tstitlesres:resolves-ancestor-workref-when-colophon-has-corresp() {
	let $fixture := tstitlesres:mss-fixture-colophon-with-corresp("MSTESTtitlesresCorresp77")
	let $result := lists:titlesRes(<a />, tstitlesres:model($fixture//t:colophon), 1, 20)
	return string(($result//*:div[*:span][contains(., "Refers to")]/*:span)[1])
};

(:~
 : The non-"mss" itemtype branch resolves its own group-level title
 : (exptit:printTitleID($ms), wrapped in try/catch in the real code)
 : via the same batch, not just on a cache/generic-id() miss.
 :)
declare %test:assertEquals("Annunciation") function tstitlesres:resolves-nonmss-group-title-via-batch() {
	let $fixture := tstitlesres:work-fixture($tstitlesres:real-id)
	let $result := lists:titlesRes(<a />, tstitlesres:model($fixture//t:div), 1, 20)
	return string(($result//*:button[@class = "w3-button w3-block w3-red  w3-margin-bottom"]/*:span)[1])
};
