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

declare %private function tsbatchexp:cleanup() {
	if (xmldb:collection-available($tsbatchexp:out-col)) then
		try { xmldb:remove($tsbatchexp:out-col) } catch * { () }
	else (
	),
	if (xmldb:collection-available($tsbatchexp:src-col)) then
		try { xmldb:remove($tsbatchexp:src-col) } catch * { () }
	else (
	)
};

declare %test:setUp function tsbatchexp:setUp() {
	tsbatchexp:cleanup(),
	tsbatchexp:ensure-src()
};

declare %test:tearDown function tsbatchexp:tearDown() {
	tsbatchexp:cleanup()
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
