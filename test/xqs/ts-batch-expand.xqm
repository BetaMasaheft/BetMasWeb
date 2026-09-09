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

(: Own collection (not the shared src-col above) so storing a second file
   here can't affect tests asserting a one-file count on src-col. :)
declare variable $tsbatchexp:freshness-src-col := "/db/apps/BetMasData/works/_batchExpandFreshnessTest";

(: Parent + nested new/ for ID-reservation stub prune guards. :)
declare variable $tsbatchexp:new-parent-src := "/db/apps/BetMasData/works/_batchExpandNewParentTest";

declare variable $tsbatchexp:new-parent-out := "/db/apps/expanded/works/_batchExpandNewParentTest";

declare variable $tsbatchexp:new-col-parent-src := "/db/apps/BetMasData/works/_batchExpandNewColTest";

declare variable $tsbatchexp:new-col-parent-out := "/db/apps/expanded/works/_batchExpandNewColTest";

declare variable $tsbatchexp:new-col-src := $tsbatchexp:new-col-parent-src || "/new";

declare variable $tsbatchexp:new-col-out := $tsbatchexp:new-col-parent-out || "/new";

declare %private function tsbatchexp:remove-if-exists($col as xs:string) {
	if (xmldb:collection-available($col)) then
		try { xmldb:remove($col) } catch * { () }
	else (
	)
};

declare %private function tsbatchexp:cleanup() {
	tsbatchexp:remove-if-exists($tsbatchexp:out-col),
	tsbatchexp:remove-if-exists($tsbatchexp:src-col),
	tsbatchexp:remove-if-exists($tsbatchexp:empty-out-col),
	tsbatchexp:remove-if-exists($tsbatchexp:empty-src-col),
	tsbatchexp:remove-if-exists($tsbatchexp:path-out-col),
	tsbatchexp:remove-if-exists($tsbatchexp:path-src-col),
	tsbatchexp:remove-if-exists($tsbatchexp:freshness-src-col),
	tsbatchexp:remove-if-exists($tsbatchexp:new-parent-out),
	tsbatchexp:remove-if-exists($tsbatchexp:new-parent-src),
	tsbatchexp:remove-if-exists($tsbatchexp:new-col-parent-out),
	tsbatchexp:remove-if-exists($tsbatchexp:new-col-parent-src)
};

declare %test:setUp function tsbatchexp:setUp() {
	tsbatchexp:cleanup(), tsbatchexp:ensure-src()
};

declare %test:tearDown function tsbatchexp:tearDown() {
	tsbatchexp:cleanup()
};

(:~
 : Bare root (no trailing slash) and a nested subpath must both map.
 :)
declare %test:assertEquals("/db/apps/expanded") function tsbatchexp:expanded-mirror-maps-bare-root() {
	batchExpand:expanded-mirror($batchExpand:data-root)
};

declare %test:assertEquals("/db/apps/expanded/works/1-1000") function tsbatchexp:expanded-mirror-maps-subpath() {
	batchExpand:expanded-mirror($batchExpand:data-root || "/works/1-1000")
};

(:~
 : expected-relative-paths must re-read $col on every call, not memoize -
 : otherwise a file stored mid-batch would look stale and get pruned.
 :)
declare %test:assertEquals(2) function tsbatchexp:expected-relative-paths-sees-file-added-after-earlier-call() {
	let $_mk := xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandFreshnessTest")
	let $_seed := xmldb:store(
		$tsbatchexp:freshness-src-col,
		"FIRSTbatchExpand.xml",
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="FIRSTbatchExpand">
			<teiHeader><titleStmt><title>first</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
			<text><body><div type="edition"><ab>x</ab></div></body></text>
		</TEI>
	)
	let $_first-call := batchExpand:expected-relative-paths($tsbatchexp:freshness-src-col)
	let $_add := xmldb:store(
		$tsbatchexp:freshness-src-col,
		"SECONDbatchExpand.xml",
		<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="SECONDbatchExpand">
			<teiHeader><titleStmt><title>second</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
			<text><body><div type="edition"><ab>x</ab></div></body></text>
		</TEI>
	)
	return count(batchExpand:expected-relative-paths($tsbatchexp:freshness-src-col))
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
 : A trailing slash on $collectionUri must not defeat prune-mirror's
 : relative-path comparisons - normalize-space alone doesn't strip it, and
 : the resulting double slash matches no real resource path.
 :)
declare %test:assertFalse function tsbatchexp:trailing-slash-does-not-defeat-prune() {
	let $_seed := (
		if (xmldb:collection-available($tsbatchexp:out-col)) then (
		) else
			xmldb:create-collection("/db/apps/expanded/works", "_batchExpandTest"),
		xmldb:store(
			$tsbatchexp:out-col,
			"ORPHANtrailingSlash.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="ORPHANtrailingSlash">
				<teiHeader><titleStmt><title>orphan</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		)
	)
	let $_ := batchExpand:expandCollection($tsbatchexp:src-col || "/")
	return doc-available($tsbatchexp:out-col || "/ORPHANtrailingSlash.xml")
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
 : ID-reservation stubs live under a path segment `new/` (mirroring
 : BetMasData/{corpus}/new). Expanding a parent collection must not prune
 : those stubs just because they are absent from that batch's expected set.
 : @see https://github.com/BetaMasaheft/expanded/issues/31
 :)
declare %test:assertTrue function tsbatchexp:keeps-stubs-under-new-when-pruning-parent() {
	let $newOut := $tsbatchexp:new-parent-out || "/new"
	let $_seed := (
		xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandNewParentTest"),
		xmldb:store(
			$tsbatchexp:new-parent-src,
			"PARENTbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="PARENTbatchExpand">
				<teiHeader><titleStmt><title>parent</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		),
		xmldb:create-collection("/db/apps/expanded/works", "_batchExpandNewParentTest"),
		xmldb:create-collection($tsbatchexp:new-parent-out, "new"),
		xmldb:store(
			$newOut,
			"STUBbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="STUBbatchExpand">
				<teiHeader><titleStmt><title>stub</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		),
		(: Still prune true orphans outside new/ :)
		xmldb:store(
			$tsbatchexp:new-parent-out,
			"ORPHANbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="ORPHANbatchExpandNewParent">
				<teiHeader><titleStmt><title>orphan</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		)
	)
	let $_ := batchExpand:expandCollection($tsbatchexp:new-parent-src)
	return doc-available($newOut || "/STUBbatchExpand.xml") and
		not(doc-available($tsbatchexp:new-parent-out || "/ORPHANbatchExpand.xml"))
};

(:~
 : When CI expands a corpus `new/` collection directly, relative paths under
 : the mirror have no `new` segment - so the parent-expand stub guard does
 : not apply. App-only WIP (no BetMasData source yet) must still survive:
 : skip prune entirely for reservation collections. Overdue cleanup is
 : assemble's job (git) / parent-expand promotion (live).
 : @see https://github.com/BetaMasaheft/expanded/issues/31
 :)
declare %test:assertTrue function tsbatchexp:keeps-app-only-wip-when-expanding-new-collection() {
	let $_seed := (
		xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandNewColTest"),
		xmldb:create-collection($tsbatchexp:new-col-parent-src, "new"),
		xmldb:store(
			$tsbatchexp:new-col-src,
			"RESERVEDbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="RESERVEDbatchExpand">
				<teiHeader><titleStmt><title>reserved</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		),
		xmldb:create-collection("/db/apps/expanded/works", "_batchExpandNewColTest"),
		xmldb:create-collection($tsbatchexp:new-col-parent-out, "new"),
		xmldb:store(
			$tsbatchexp:new-col-out,
			"WIPinNewbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="WIPinNewbatchExpand">
				<teiHeader><titleStmt><title>app-only wip</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		)
	)
	let $_ := batchExpand:expandCollection($tsbatchexp:new-col-src)
	return doc-available($tsbatchexp:new-col-out || "/WIPinNewbatchExpand.xml") and
		doc-available($tsbatchexp:new-col-out || "/RESERVEDbatchExpand.xml")
};

(:~
 : Once a reservation stub's basename also appears elsewhere in $expected,
 : outside `new/`, the id was promoted to a permanent path within the same
 : batch - the stale copy left under `new/` is a resolved leftover, not a
 : WIP stub, and must be pruned.
 : @see https://github.com/BetaMasaheft/expanded/issues/31
 :)
declare %test:assertFalse function tsbatchexp:prunes-promoted-stub-once-real-file-exists-elsewhere() {
	let $newOut := $tsbatchexp:new-parent-out || "/new"
	let $_seed := (
		xmldb:create-collection("/db/apps/BetMasData/works", "_batchExpandNewParentTest"),
		xmldb:store(
			$tsbatchexp:new-parent-src,
			"PARENTbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="PARENTbatchExpand">
				<teiHeader><titleStmt><title>parent</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		),
		(: same basename now exists at a permanent (non-new) path: promoted :)
		xmldb:store(
			$tsbatchexp:new-parent-src,
			"STUBbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="STUBbatchExpandPromoted">
				<teiHeader><titleStmt><title>promoted</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		),
		xmldb:create-collection("/db/apps/expanded/works", "_batchExpandNewParentTest"),
		xmldb:create-collection($tsbatchexp:new-parent-out, "new"),
		xmldb:store(
			$newOut,
			"STUBbatchExpand.xml",
			<TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="STUBbatchExpand">
				<teiHeader><titleStmt><title>stub</title></titleStmt><encodingDesc><p>x</p></encodingDesc></teiHeader>
				<text><body><div type="edition"><ab>x</ab></div></body></text>
			</TEI>
		)
	)
	let $_ := batchExpand:expandCollection($tsbatchexp:new-parent-src)
	return doc-available($newOut || "/STUBbatchExpand.xml")
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
