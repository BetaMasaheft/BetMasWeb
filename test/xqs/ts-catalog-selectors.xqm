xquery version "3.1" encoding "UTF-8";

(:~
 : Pure selector rules shared by expansion and the catalog facade.
 : Hermetic: every case is an in-memory TEI fragment.
 :
 : The manuscript-label cases pin down a deliberate Phase 2 correction. The
 : predicate used to be an unprefixed `objectDesc`, which cannot match TEI
 : input, so inscriptions were labelled through the repository branch. It now
 : reads `t:objectDesc` and inscriptions are labelled by their idno.
 :)
module namespace tsselectors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-catalog-selectors";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace selectors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog-selectors" at "../../modules/catalog-selectors.xqm";

declare %private function tsselectors:inscription() as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="INS0001Test">
		<msDesc>
			<msIdentifier><idno>RIE 185 I</idno></msIdentifier>
			<physDesc><objectDesc form="Inscription" /></physDesc>
		</msDesc>
	</TEI>
};

declare %private function tsselectors:manuscript() as element(t:TEI) {
	<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="BNFet32">
		<msDesc><msIdentifier><repository ref="INS0303BnF" /><idno>BnF Éthiopien 32</idno></msIdentifier></msDesc>
	</TEI>
};

(:~
 : An inscription is labelled by its idno alone, never by repository and
 : location. This is the branch the unprefixed predicate could not reach.
 :)
declare %test:assertEquals("RIE 185 I") function tsselectors:inscription-label-is-the-idno() {
	selectors:manuscript-label(tsselectors:inscription(), "Institut des études", "Paris")
};

(:~
 : Same fragment through the former unprefixed predicate: no match, so the
 : old code fell through to the repository branch. Kept as an explicit record
 : of what the corpus-wide label change replaced.
 :)
declare %test:assertFalse function tsselectors:unprefixed-objectdesc-never-matched-tei() {
	exists(tsselectors:inscription()//objectDesc[@form = "Inscription"])
};

declare
	%test:assertEquals("Paris, Bibliothèque nationale de France, BnF Éthiopien 32")
function tsselectors:manuscript-label-is-place-institution-idno() {
	selectors:manuscript-label(tsselectors:manuscript(), "Bibliothèque nationale de France", "Paris")
};

declare %test:assertEquals("Lost. BnF Éthiopien 32") function tsselectors:lost-repository-label() {
	selectors:manuscript-label(
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="Lost001">
			<msDesc>
				<msIdentifier><repository ref="INS0303BnF">Lost</repository><idno>BnF Éthiopien 32</idno></msIdentifier>
			</msDesc>
		</TEI>,
		"Bibliothèque nationale de France",
		"Paris"
	)
};

declare
	%test:assertEquals("No location record, No Institution record, BnF Éthiopien 32")
function tsselectors:missing-repository-metadata-is-explicit() {
	selectors:manuscript-label(tsselectors:manuscript(), (), ())
};

declare
	%test:assertEquals("no repository data for INS0001Test")
function tsselectors:no-repository-data-names-the-record() {
	selectors:manuscript-label(
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="mss" xml:id="INS0001Test"><msDesc><msIdentifier /></msDesc></TEI>,
		(),
		()
	)
};

declare %test:assertEquals("transformation tr1") function tsselectors:subtitle-transformation-anchor() {
	selectors:subtitle(
		<TEI xmlns="http://www.tei-c.org/ns/1.0" />,
		"tr1",
		map {
			"label": function ($id as xs:string) { $id },
			"text": function ($n as node()*) { $n/text() },
			"additio": false()
		}
	)
};

(:~
 : Bare "aN" anchors are additiones for raw source data only; the expanded
 : and catalog callers keep falling through to the element-name form.
 :)
declare %test:assertEquals("  additio a2") function tsselectors:subtitle-additio-for-raw-callers() {
	selectors:subtitle(
		<TEI xmlns="http://www.tei-c.org/ns/1.0"><item xml:id="a2" /></TEI>,
		"a2",
		map {
			"label": function ($id as xs:string) { $id },
			"text": function ($n as node()*) { $n/text() },
			"additio": true()
		}
	)
};

declare %test:assertEquals("item a2") function tsselectors:subtitle-without-additio-names-the-element() {
	selectors:subtitle(
		<TEI xmlns="http://www.tei-c.org/ns/1.0"><item xml:id="a2" /></TEI>,
		"a2",
		map {
			"label": function ($id as xs:string) { $id },
			"text": function ($n as node()*) { $n/text() },
			"additio": false()
		}
	)
};

(:~
 : The resolver callback is what distinguishes the three callers; a label
 : referenced through @corresp must come back through it.
 :)
declare %test:assertEquals("resolved(LIT1367Exodus)") function tsselectors:subtitle-uses-the-caller-resolver() {
	selectors:subtitle(
		<TEI xmlns="http://www.tei-c.org/ns/1.0"><item corresp="LIT1367Exodus" xml:id="x1" /></TEI>,
		"x1",
		map {
			"label": function ($id as xs:string) { "resolved(" || $id || ")" },
			"text": function ($n as node()*) { $n/text() },
			"additio": false()
		}
	)
};
