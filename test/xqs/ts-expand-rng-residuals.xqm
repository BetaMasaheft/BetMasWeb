xquery version "3.1";

module namespace tsexpandrng = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ts-expand-rng-residuals";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "../../modules/expand.xqm";

(:~
 : Short fragment refs must keep a single leading "#".
 :)
declare %test:assertEquals("#p2") function tsexpandrng:reflike-keeps-hash-fragment() {
	string(expand:reflike(attribute corresp { "#p2" }))
};

declare %test:assertEquals("#ab") function tsexpandrng:reflike-keeps-two-char-fragment() {
	string(expand:reflike(attribute corresp { "#ab" }))
};

declare %test:assertEquals("#p2") function tsexpandrng:reflike-prefixes-bare-short() {
	string(expand:reflike(attribute corresp { "p2" }))
};

(:~
 : ecrm relation @name → @ref. CIDOC-CRM local names use underscores
 : (P129_is_about). Unanchored fn:replace with an alnum-only matchPattern
 : re-prefixed each underscore-separated run, producing the residual
 : shape still seen in a few stale expanded files after hybrid re-expand:
 : …/P129_http://…/is_http://…/about
 : Cover every ecrm value allowed by tei-betamesaheft-expanded.rng.
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/127
 :)
declare
	%test:arg("id", "ecrm:P129_is_about")
	%test:assertEquals("http://erlangen-crm.org/current/P129_is_about")
	%test:arg("id", "ecrm:P129i_is_subject_of")
	%test:assertEquals("http://erlangen-crm.org/current/P129i_is_subject_of")
	%test:arg("id", "ecrm:CLP46i_may_form_part_of")
	%test:assertEquals("http://erlangen-crm.org/current/CLP46i_may_form_part_of")
	%test:arg("id", "ecrm:CLP45_should_consist_of")
	%test:assertEquals("http://erlangen-crm.org/current/CLP45_should_consist_of")
	%test:arg("id", "ecrm:CLP45i_should_be_incorporated_in")
	%test:assertEquals("http://erlangen-crm.org/current/CLP45i_should_be_incorporated_in")
	%test:arg("id", "ecrm:CLP57_should_have_number_of_parts")
	%test:assertEquals("http://erlangen-crm.org/current/CLP57_should_have_number_of_parts")
	%test:arg("id", "ecrm:P57_has_number_of_parts")
	%test:assertEquals("http://erlangen-crm.org/current/P57_has_number_of_parts")
function tsexpandrng:ecrm-id-keeps-underscored-property-name($id as xs:string) {
	string(expand:id($id))
};

(:~
 : Regression: expand:id must never emit the segment-reprefix mangling
 : shape residual in expanded (…/_http://…).
 :)
declare %test:assertFalse function tsexpandrng:ecrm-id-does-not-reprefix-segments() {
	contains(string(expand:id("ecrm:CLP46i_may_form_part_of")), "_http://")
};

(:~
 : relation expansion recomputes @ref from @name via expand:id.
 :)
declare
	%test:assertEquals("http://erlangen-crm.org/current/P129_is_about")
function tsexpandrng:relation-ecrm-ref-from-name() {
	let $rel := <relation
		xmlns="http://www.tei-c.org/ns/1.0"
		active="LIT0001Test"
		name="ecrm:P129_is_about"
		passive="PRS0001Test" />
	let $out := expand:tei2fulltei($rel, ())
	return string($out/@ref)
};

declare
	%test:assertEquals("http://erlangen-crm.org/current/CLP46i_may_form_part_of")
function tsexpandrng:relation-ecrm-clp46-ref-from-name() {
	let $rel := <relation
		xmlns="http://www.tei-c.org/ns/1.0"
		active="LIT0001Test"
		name="ecrm:CLP46i_may_form_part_of"
		passive="LIT0002Test" />
	let $out := expand:tei2fulltei($rel, ())
	return string($out/@ref)
};

(:~
 : $expand:listPrefixDef is what expand:id reads — ecrm must allow "_".
 :)
declare %test:assertTrue function tsexpandrng:ecrm-prefixDef-matchPattern-allows-underscore() {
	contains(string($expand:listPrefixDef//t:prefixDef[@ident = "ecrm"]/@matchPattern), "_")
};

(:~
 : encodingDesc expand injects that same listPrefixDef (needs an encodingDesc
 : in the input — bare teiHeader does not create one).
 :)
declare %test:assertTrue function tsexpandrng:ecrm-prefixDef-injected-into-encodingDesc() {
	let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITTESTecrmPdef">
		<teiHeader>
			<titleStmt><title>seed</title></titleStmt>
			<encodingDesc><p>seed</p></encodingDesc>
			<profileDesc><abstract><p>a</p></abstract></profileDesc>
		</teiHeader>
		<text><body><div><ab>x</ab></div></body></text>
	</TEI>
	let $out := expand:tei2fulltei($tei, ())
	return contains(string($out//t:prefixDef[@ident = "ecrm"]/@matchPattern), "_")
};

(:~
 : Unresolved repository @ref → plain text under repository (xtext), not seg.
 :)
declare %test:assertFalse function tsexpandrng:repository-no-item-is-not-seg() {
	let $repo := <repository xmlns="http://www.tei-c.org/ns/1.0" ref="INS0517BetaMasqalKebra" />
	let $out := expand:refel($repo, ())
	return exists($out/t:seg)
};

declare %test:assertTrue function tsexpandrng:repository-no-item-is-text() {
	let $repo := <repository xmlns="http://www.tei-c.org/ns/1.0" ref="INS0517BetaMasqalKebra" />
	let $out := expand:refel($repo, ())
	return contains(string($out), "No item:") and empty($out/t:seg)
};

(:~
 : Multiple profileDesc siblings get a single calendarDesc (no duplicate ids).
 :)
declare %test:assertEquals(1) function tsexpandrng:calendarDesc-once-per-tei() {
	let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITTESTdualProfile">
		<teiHeader>
			<titleStmt><title>seed</title></titleStmt>
			<profileDesc><abstract><p>a</p></abstract></profileDesc>
			<profileDesc><langUsage><language ident="en">English</language></langUsage></profileDesc>
		</teiHeader>
		<text><body><div><ab>x</ab></div></body></text>
	</TEI>
	let $out := expand:tei2fulltei($tei, ())
	return count($out//t:calendarDesc)
};

declare %test:assertEquals(1) function tsexpandrng:calendar-world-id-once() {
	let $tei := <TEI xmlns="http://www.tei-c.org/ns/1.0" type="work" xml:id="LITTESTdualProfile2">
		<teiHeader>
			<titleStmt><title>seed</title></titleStmt>
			<profileDesc><abstract><p>a</p></abstract></profileDesc>
			<profileDesc><langUsage><language ident="en">English</language></langUsage></profileDesc>
		</teiHeader>
		<text><body><div><ab>x</ab></div></body></text>
	</TEI>
	let $out := expand:tei2fulltei($tei, ())
	return count($out//t:calendar[@xml:id = "world"])
};

(:~
 : Unresolved settlement/region/country @ref → plain text (xtext), not
 : seg, same as repository.
 :)
declare %test:assertFalse function tsexpandrng:settlement-no-item-is-not-seg() {
	let $node := <settlement xmlns="http://www.tei-c.org/ns/1.0" ref="ZZZNOTAPLACE9999" />
	let $out := expand:refel($node, ())
	return exists($out/t:seg)
};

declare %test:assertFalse function tsexpandrng:region-no-item-is-not-seg() {
	let $node := <region xmlns="http://www.tei-c.org/ns/1.0" ref="ZZZNOTAPLACE9999" />
	let $out := expand:refel($node, ())
	return exists($out/t:seg)
};

declare %test:assertFalse function tsexpandrng:country-no-item-is-not-seg() {
	let $node := <country xmlns="http://www.tei-c.org/ns/1.0" ref="ZZZNOTAPLACE9999" />
	let $out := expand:refel($node, ())
	return exists($out/t:seg)
};

(:~
 : titles:printTitleID's self-loop deletion notice must be wrapped in a
 : TEI seg (not leaked as plain title/placeName text) even though the
 : underlying record's title still resolves.
 : @see modules/titlesData.xqm titles:printTitleID
 :)
declare %test:assertEquals("seg") function tsexpandrng:self-loop-deletion-notice-is-seg() {
	let $out := expand:teiTitle("LOC1464Ankoba")
	return local-name($out)
};

declare %test:assertEquals("LOC1464Ankoba") function tsexpandrng:self-loop-deletion-notice-seg-has-corresp() {
	let $out := expand:teiTitle("LOC1464Ankoba")
	return string($out/@corresp)
};

(:~
 : @who/@resp values starting with "#" must pass through unchanged, same
 : fix as expand:reflike's ##p2 guard.
 :)
declare %test:assertEquals("#p2") function tsexpandrng:wholike-keeps-hash-fragment() {
	string(expand:wholike(attribute who { "#p2" }))
};

declare %test:assertEquals("https://betamasaheft.eu/GS") function tsexpandrng:wholike-resolves-plain-value() {
	string(expand:wholike(attribute who { "GS" }))
};

(:~
 : A longer "#"-prefixed ref (not the short ##p2 case) still resolves via
 : expand:id(), same as before the ##p2 guard was added.
 :)
declare
	%test:assertEquals("https://betamasaheft.eu/#someLongFragmentId")
function tsexpandrng:reflike-resolves-long-hash-fragment() {
	string(expand:reflike(attribute corresp { "#someLongFragmentId" }))
};
