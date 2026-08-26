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
	if (xmldb:collection-available($tsbatchexp:src-col)) then (
	) else (
		xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandTest")
	),
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
 : Expanding a one-file fixture under BetMasData stores under /db/apps/expanded/...
 : and uses group-scoped perms (not world-writable).
 :)
declare %test:assertTrue function tsbatchexp:stores-under-expanded() {
	let $_clean1 := tsbatchexp:cleanup()
	let $_src := tsbatchexp:ensure-src()
	let $summary := batchExpand:expandCollection($tsbatchexp:src-col)
	let $stored-path := $tsbatchexp:out-col || "/" || $tsbatchexp:file
	let $stored := doc($stored-path)
	let $mode := string((sm:get-permissions(xs:anyURI($stored-path))/@mode)[1])
	(: other-write must be off (not rwxrwxrwx); accept rwxrwxr-x :)
	let $ok := exists($stored/t:TEI[@xml:id = "LITTESTbatchExpand"]) and
		matches($summary, "^expanded 1 file\(s\) in ") and
		matches($mode, "^rwxrwxr-x$")
	let $_clean2 := tsbatchexp:cleanup()
	return $ok
};
