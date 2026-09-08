xquery version "3.1" encoding "UTF-8";

(:~
 : XQSuite for parametrized batch expand (expanded#11 / makeExpand plan Task 1).
 :)
module namespace tsbatchexp = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-batch-expand";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace batchExpand = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/batchExpand" at "../../modules/batchExpand.xqm";

declare variable $tsbatchexp:src-col := "/db/apps/BetMasData/works/_batchExpandTest";

declare variable $tsbatchexp:out-col := "/db/apps/expanded/works/_batchExpandTest";

declare variable $tsbatchexp:file := "LITTESTbatchExpand.xml";

declare variable $tsbatchexp:tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITTESTbatchExpand">
	<teiHeader>
		<titleStmt><title xml:lang="en">batch expand fixture</title></titleStmt>
		<publicationStmt><p>test</p></publicationStmt>
		<sourceDesc><p>test</p></sourceDesc>
		<encodingDesc><p>seed</p></encodingDesc>
	</teiHeader>
	<text><body><div type="edition"><ab>x</ab></div></body></text>
</TEI>;

declare %private function tsbatchexp:ensure-src() {
	if (not(xmldb:collection-available("/db/apps/BetMasData"))) then
		error(xs:QName("tsbatchexp:NODATA"), "/db/apps/BetMasData is not available")
	else if (not(xmldb:collection-available("/db/apps/BetMasData/works"))) then
		xmldb:create-collection("/db/apps/BetMasData", "works")
	else (
	),
	if (xmldb:collection-available($tsbatchexp:src-col)) then (
	) else
		xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandTest"),
	xmldb:store($tsbatchexp:src-col, $tsbatchexp:file, $tsbatchexp:tei)
};

declare variable $tsbatchexp:empty-src-col := "/db/apps/BetMasData/works/_batchExpandEmptyTest";

declare variable $tsbatchexp:empty-out-col := "/db/apps/expanded/works/_batchExpandEmptyTest";

(: Own collection pair (not the shared src/out-col above) so this test's
   nested subcollections churn independently of the other fixtures sharing
   one xqsuite request/transaction. :)
declare variable $tsbatchexp:path-src-col := "/db/apps/BetMasData/works/_batchExpandPathTest";

declare variable $tsbatchexp:path-out-col := "/db/apps/expanded/works/_batchExpandPathTest";

declare %private function tsbatchexp:cleanup() {
	if (xmldb:collection-available($tsbatchexp:out-col)) then
		try { xmldb:remove($tsbatchexp:out-col) } catch * { () }
	else (
	),
	if (xmldb:collection-available($tsbatchexp:src-col)) then
		try { xmldb:remove($tsbatchexp:src-col) } catch * { () }
	else (
	),
	if (xmldb:collection-available($tsbatchexp:empty-out-col)) then
		try { xmldb:remove($tsbatchexp:empty-out-col) } catch * { () }
	else (
	),
	if (xmldb:collection-available($tsbatchexp:empty-src-col)) then
		try { xmldb:remove($tsbatchexp:empty-src-col) } catch * { () }
	else (
	),
	if (xmldb:collection-available($tsbatchexp:path-out-col)) then
		try { xmldb:remove($tsbatchexp:path-out-col) } catch * { () }
	else (
	),
	if (xmldb:collection-available($tsbatchexp:path-src-col)) then
		try { xmldb:remove($tsbatchexp:path-src-col) } catch * { () }
	else (
	)
};

declare %test:setUp function tsbatchexp:setUp() {
	tsbatchexp:cleanup(), tsbatchexp:ensure-src()
};

declare %test:tearDown function tsbatchexp:tearDown() {
	tsbatchexp:cleanup()
};

(:~
 : Pure path mapping BetMasData -> expanded. Exercises both the bare-root
 : case (no trailing slash for fn:replace to anchor on - the shape that let
 : prune-mirror delete straight from the live source) and a nested subpath.
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
declare %test:assertEquals("/db/apps/expanded") function tsbatchexp:expanded-mirror-maps-bare-root() {
	batchExpand:expanded-mirror($batchExpand:data-root)
};

declare %test:assertEquals("/db/apps/expanded/works/1-1000") function tsbatchexp:expanded-mirror-maps-subpath() {
	batchExpand:expanded-mirror($batchExpand:data-root || "/works/1-1000")
};

(:~
 : Empty / missing collection must refuse (no silent full-corpus).
 :)
declare %test:assertError("batchExpand:EMPTY") function tsbatchexp:refuse-empty-collection() {
	batchExpand:expandCollection("")
};

declare %test:assertError("batchExpand:EMPTY") function tsbatchexp:refuse-missing-param() {
	batchExpand:expandCollection(())
};

declare %test:assertError("batchExpand:BAD_ROOT") function tsbatchexp:refuse-outside-betmasdata() {
	batchExpand:expandCollection("/db/apps/lists")
};

declare %test:assertError("batchExpand:BAD_ROOT") function tsbatchexp:refuse-prefix-sibling() {
	batchExpand:expandCollection("/db/apps/BetMasDataEvil")
};

declare %test:assertError("batchExpand:BAD_ROOT") function tsbatchexp:refuse-dotdot-traversal() {
	batchExpand:expandCollection("/db/apps/BetMasData/../lists")
};

declare %test:assertError("batchExpand:MISSING") function tsbatchexp:refuse-missing-collection() {
	batchExpand:expandCollection("/db/apps/BetMasData/works/_batchExpandMissingCol")
};

(:~
 : Expanding a one-file fixture under BetMasData stores a TEI doc under
 : /db/apps/expanded/... at the expected path.
 :)
declare %test:assertTrue function tsbatchexp:stores-tei-document-at-expected-path() {
	let $_ := batchExpand:expandCollection($tsbatchexp:src-col)
	return doc-available($tsbatchexp:out-col || "/" || $tsbatchexp:file)
};

(:~
 : After a successful collection expand, resources under the expanded mirror
 : that are not in the BetMasData source set are removed (mirror sync).
 :)
declare %test:assertFalse function tsbatchexp:prunes-stale-mirror-resources() {
	let $_seed := (
		if (xmldb:collection-available($tsbatchexp:out-col)) then (
		) else
			xmldb:create-collection("/db/apps/expanded/works", "_batchExpandTest"),
		xmldb:store(
			$tsbatchexp:out-col,
			"ORPHANbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="ORPHANbatchExpand">
				<teiHeader><titleStmt><title>orphan</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		)
	)
	let $_ := batchExpand:expandCollection($tsbatchexp:src-col)
	return doc-available($tsbatchexp:out-col || "/ORPHANbatchExpand.xml")
};

(:~
 : An existing collection with zero TEI files right now must not be treated
 : as "nothing is expected" and wipe its whole expanded mirror - that's
 : indistinguishable from a full accidental wipe.
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
declare %test:assertTrue function tsbatchexp:does-not-wipe-mirror-when-source-has-no-tei-yet() {
	let $_seed := (
		if (xmldb:collection-available($tsbatchexp:empty-src-col)) then (
		) else
			xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandEmptyTest"),
		if (xmldb:collection-available($tsbatchexp:empty-out-col)) then (
		) else
			xmldb:create-collection("/db/apps/expanded/works", "_batchExpandEmptyTest"),
		xmldb:store(
			$tsbatchexp:empty-out-col,
			"SURVIVORbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="SURVIVORbatchExpand">
				<teiHeader><titleStmt><title>survivor</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		)
	)
	let $_ := batchExpand:expandCollection($tsbatchexp:empty-src-col)
	return doc-available($tsbatchexp:empty-out-col || "/SURVIVORbatchExpand.xml")
};

(:~
 : prune-mirror must key staleness off the path relative to the mirrored
 : collection, not the bare filename - two same-named files in different
 : subcollections must not shadow each other.
 : @see https://github.com/BetaMasaheft/expanded/issues/11
 :)
declare %test:assertEquals(2) function tsbatchexp:prunes-by-relative-path-not-basename() {
	let $subB := $tsbatchexp:path-src-col || "/subB"
	let $orphanCol := $tsbatchexp:path-out-col || "/subA"
	let $_seed := (
		xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandPathTest"),
		xmldb:create-collection($tsbatchexp:path-src-col, "subB"),
		xmldb:store(
			$subB,
			"SAMESHAPE.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITsubBsameshape">
				<teiHeader><titleStmt><title>subB</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		),
		xmldb:create-collection("/db/apps/expanded/works", "_batchExpandPathTest"),
		xmldb:create-collection($tsbatchexp:path-out-col, "subA"),
		xmldb:store(
			$orphanCol,
			"SAMESHAPE.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="ORPHANsubAsameshape">
				<teiHeader><titleStmt><title>subA orphan</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		)
	)
	let $_ := batchExpand:expandCollection($tsbatchexp:path-src-col)
	return (
		if (doc-available($tsbatchexp:path-out-col || "/subA/SAMESHAPE.xml")) then
			0
		else
			1,
		if (doc-available($tsbatchexp:path-out-col || "/subB/SAMESHAPE.xml")) then
			1
		else
			0
	)
		=> sum()
};

(:~
 : The stored document keeps the source TEI's xml:id.
 :)
declare %test:assertEquals("LITTESTbatchExpand") function tsbatchexp:stored-document-has-correct-tei-id() {
	let $_ := batchExpand:expandCollection($tsbatchexp:src-col)
	return string(doc($tsbatchexp:out-col || "/" || $tsbatchexp:file)/t:TEI/@xml:id)
};

(:~
 : The summary reports exactly one file expanded.
 :)
declare %test:assertTrue function tsbatchexp:summary-reports-one-file-expanded() {
	matches(batchExpand:expandCollection($tsbatchexp:src-col), "^expanded 1 file\(s\) in ")
};

(:~
 : batchExpand:setPermissions chmods the stored file to rwxrwxr-x (not
 : world-writable). sm:get-permissions returns a document-node wrapping
 : sm:permission, so @mode must be read off the child element.
 :)
declare %test:assertEquals("rwxrwxr-x") function tsbatchexp:stored-file-has-expected-permissions() {
	let $_ := batchExpand:expandCollection($tsbatchexp:src-col)
	return string(sm:get-permissions(xs:anyURI($tsbatchexp:out-col || "/" || $tsbatchexp:file))/sm:permission/@mode)
};
