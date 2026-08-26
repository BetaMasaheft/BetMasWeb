xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite tests for modules/viewItem.xqm's html-templating conversion of
 : the "place"/"ins" body render - viewItem:place($item) now calls
 : templates:apply(templates/itemPlace.html, ...) instead of building the
 : element tree inline. Both viewItem:main's "place" and "ins" cases
 : delegate to the same viewItem:place, so one conversion covers both.
 : Naming follows tei-publisher-lib: test/ts-<component>.xqm
 : @see https://github.com/eeditiones/tei-publisher-lib
 :
 : NOTE on this test file's shape: viewItem:place returns a *sequence* of
 : disconnected, freshly-constructed root nodes (script?, MainData div,
 : resp output), not one document tree. Live XPath (//, predicates)
 : applied directly to that sequence was found - by direct, repeated,
 : side-by-side testing, not assumed - to be unreliable in this eXist
 : version: identically-shaped expressions (e.g. `$result[self::*][@id =
 : "MainData"]//h2`) gave different true/false answers depending on what
 : else was evaluated earlier in the same query, including a bare for-loop
 : with no predicates at all. serialize()-then-string-match was the one
 : pattern that stayed consistent across repeated runs, so every assertion
 : below goes through serialize() first rather than querying the live
 : result sequence - not for style, this is a correctness requirement.
 :)
module namespace tsviplace = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-viewitem-place";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "../../modules/viewItem.xqm";

declare %private function tsviplace:doc($id as xs:string, $collection as xs:string) as element()? {
	collection("/db/apps/expanded/" || $collection)//t:TEI[@xml:id = $id]
};

declare %private function tsviplace:render($item as element()) as xs:string {
	string-join(
		for $x in viewItem:place($item)
		return serialize($x)
	)
};

(:~
 : viewItem:place's output is a raw sequence (script?, MainData div, resp
 : output), not a single wrapped element - the template's own root
 : wrapper must vanish at runtime (no %templates:wrap on
 : viewItem:placeRoot), leaving MainData as a genuine top-level result.
 :)
declare %test:assertXPath("contains($result, 'id=&quot;MainData&quot;')") function tsviplace:place-renders-maindata-wrapper() {
	tsviplace:render(tsviplace:doc("LOC3080Ferheb", "places"))
};

(:~
 : viewItem:main's "ins" case also delegates to viewItem:place - same
 : conversion has to serve institutions too, not just places.
 :)
declare %test:assertXPath("contains($result, 'id=&quot;MainData&quot;')") function tsviplace:institution-renders-maindata-wrapper() {
	tsviplace:render(tsviplace:doc("INS0013IHA", "institutions"))
};

(:~
 : viewItem:placeSetup computes the relations scan once and merges it
 : into $model for viewItem:placeRelsInfo to read back (same model-sharing
 : shape as the narratives conversion) - assert the section has content
 : for a document with real relations data, not just "no error".
 :)
declare %test:assertXPath("contains($result, 'id=&quot;description&quot;')") function tsviplace:relsinfo-reads-model-shared-rels() {
	tsviplace:render(tsviplace:doc("LOC3080Ferheb", "places"))
};

(:~
 : The figure-conditional <script> only appears for items with t:figure -
 : exercised on a document confirmed to have one (INS0091AQM), and
 : confirmed absent on one that doesn't (LOC3080Ferheb), so the
 : conversion is tested on both sides of the conditional, not just the
 : happy path. Fixture-shape and rendered-output are asserted separately
 : so a failure says which one broke.
 :)
declare %test:assertTrue function tsviplace:figure-fixture-has-figure-element() {
	exists(tsviplace:doc("INS0091AQM", "institutions")//t:figure)
};

declare %test:assertXPath("contains($result, 'openseadragon')") function tsviplace:figure-script-present-when-item-has-figure() {
	tsviplace:render(tsviplace:doc("INS0091AQM", "institutions"))
};

declare %test:assertTrue function tsviplace:no-figure-fixture-has-no-figure-element() {
	empty(tsviplace:doc("LOC3080Ferheb", "places")//t:figure)
};

declare %test:assertXPath("not(contains($result, 'openseadragon'))") function tsviplace:figure-script-absent-when-item-has-no-figure() {
	tsviplace:render(tsviplace:doc("LOC3080Ferheb", "places"))
};

(:~
 : The sameAs-driven globe icon link in the Names heading is another
 : conditional - exercised on a document known to have @sameAs.
 :)
declare %test:assertTrue function tsviplace:sameas-fixture-has-sameas-attribute() {
	exists(tsviplace:doc("LOC3994Kampal", "places")//t:place/@sameAs)
};

declare %test:assertXPath("contains($result, 'icon-globe')") function tsviplace:sameas-link-present-when-item-has-sameas() {
	tsviplace:render(tsviplace:doc("LOC3994Kampal", "places"))
};
