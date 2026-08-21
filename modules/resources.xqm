xquery version "3.1" encoding "UTF-8";

(:~
 : This module contains functions printing indexes and lists extracted from the data which are not list of resources
 : @author Pietro Liuzzo
 :)

module namespace lists = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/lists";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace templates = "http://exist-db.org/xquery/templates";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

declare variable $lists:collection-rootMS := collection($config:data-rootMS);

declare variable $lists:collection-rootW := collection($config:data-rootW);

declare variable $lists:collection-rootA := collection($config:data-rootA);

declare variable $lists:cal := doc("/db/apps/BetMasWeb/calendars/ethiopian.xml");

(:~
 : Collects distinct bibliography pointer targets (t:ptr target) from a
 : collection of entities, optionally narrowed by entity type, listBibl
 : type, and a single bm: pointer.
 :
 : @param $node the context node
 : @param $model the template model
 : @param $type listBibl type value(s) to match, or "all"
 : @param $collection entity type to search within (e.g. "mss"), or "all"/"" for the whole collection
 : @param $pointer a specific bm: pointer target, or "" for any
 : @return a map with "hits" (the distinct target strings), "type", and
 : "coll" (the base collection node sequence, reused by lists:biblRes)
 :)
declare
	%templates:default("collection", "") %templates:default("pointer", "") %templates:default("type", "all")
function lists:bibl(
	$node as node(),
	$model as map(*),
	$type as xs:string+,
	$collection as xs:string,
	$pointer as xs:string*
) {
	let $baseColl := if ($collection = "all" or $collection = "") then
		$exptit:col
	else
		$exptit:col//t:TEI[@type = $collection]
	let $listBibls := if ($type = "all") then
		$baseColl
	else
		$baseColl//t:listBibl[@type = $type]
	let $ptrs := $listBibls//t:ptr[starts-with(@target, "bm:")]
	let $query := (
		if ($pointer = "") then
			$ptrs
		else
			$ptrs[@target = $pointer]
	)/@target
	let $bms :=
		for $bibl in config:distinct-values($query)
		order by $bibl
		return $bibl
	return map {"hits": $bms, "type": "bibliography", "coll": $baseColl}
};

(:~
 : Filters manuscript-addition items (t:item, xml:id starting with "a") by
 : any combination of type, target work/person/place/keyword/language,
 : free-text search, interpretation, repository, content, and main keyword.
 :
 : Unfiltered/large-result calls are slow (multi-second, multi-MB response);
 : the cause is architectural (no pagination, plus filter dropdowns
 : re-scanning the full unfiltered hit set every request), not something
 : this eval-removal pass fixes.
 :
 : @param $node the context node
 : @param $model the template model
 : @param $query unused (reserved for template signature compatibility)
 : @param $type t:desc type value(s) to match, or "all"
 : @param $target-keyword t:term key value(s) to match, or "all"
 : @param $target-language t:q xml:lang value(s) to match, or "all"
 : @param $target-pers t:persName ref value(s) to match, or "all"
 : @param $target-place t:placeName ref value(s) to match, or "all"
 : @param $repo repository ref value(s) to match, or "all"
 : @param $content msItem title ref value(s) to match, or "all"
 : @param $main-key textClass keyword key value(s) to match, or "all"
 : @param $target-work t:title ref value(s) to match, or "all"
 : @param $termText free text matched against descendant t:term
 : @param $otherText free text full-text-matched against descendant t:q
 : @param $interpret t:seg ana value(s) to match, or "all"
 : @return a map with "hits" (the matching t:item nodes)
 : @see https://github.com/BetaMasaheft/betmas-e2e/issues/5
 :)
declare
	%templates:default("scope", "narrow")
	%templates:default("type", "all")
	%templates:default("target-pers", "all")
	%templates:default("target-place", "all")
	%templates:default("repo", "all")
	%templates:default("content", "all")
	%templates:default("main-key", "all")
	%templates:default("target-work", "all")
	%templates:default("target-keyword", "all")
	%templates:default("target-language", "all")
	%templates:default("interpret", "all")
function lists:additions(
	$node as node()*,
	$model as map(*),
	$query as xs:string*,
	$type as xs:string+,
	$target-keyword as xs:string+,
	$target-language as xs:string+,
	$target-pers as xs:string+,
	$target-place as xs:string+,
	$repo as xs:string+,
	$content as xs:string+,
	$main-key as xs:string+,
	$target-work as xs:string+,
	$termText as xs:string*,
	$otherText as xs:string*,
	$interpret as xs:string*
) {
	(:
	 : was ancestor::t:TEI//t:textClass/t:keywords:/t:term[@ref eq ...] -
	 : the stray colon made util:eval's string always fail to parse when
	 : $main-key != "all", masking a second bug: the main-key <select>
	 : below (and its only source of option values) is populated from
	 : t:keywords/t:term/@key, not @ref, so even a syntactically valid
	 : version of the old filter would have matched nothing. Both fixed
	 : here as part of the native-predicate rewrite.
	 :
	 : Each filter step below is applied only when its parameter is
	 : active ("all"/empty means skip) - unlike "[$x = 'all' or ...]"
	 : chained onto every step regardless, which still pays for the
	 : (often expensive, descendant-scanning) right-hand side per node
	 : even when the left-hand side is already true. That form measured
	 : 5-9x slower than the original util:eval'd query on this corpus.
	 :)
	let $s1 := $lists:collection-rootMS//t:item[starts-with(@xml:id, "a")]
	let $s2 := if ($type = "all") then
		$s1
	else
		$s1[descendant::t:desc/@type = $type]
	let $s3 := if ($target-work = "all") then
		$s2
	else
		$s2[descendant::t:title/@ref = $target-work]
	let $s4 := if ($target-pers = "all") then
		$s3
	else
		$s3[descendant::t:persName/@ref = $target-pers]
	let $s5 := if ($target-place = "all") then
		$s4
	else
		$s4[descendant::t:placeName/@ref = $target-place]
	let $s6 := if ($target-keyword = "all") then
		$s5
	else
		$s5[descendant::t:term/@key = $target-keyword]
	let $s7 := if ($target-language = "all") then
		$s6
	else
		$s6[descendant::t:q/@xml:lang = $target-language]
	let $s8 := if (not($termText)) then
		$s7
	else
		$s7[descendant::t:term[contains(., $termText)]]
	let $s9 := if (not($otherText)) then
		$s8
	else
		$s8[descendant::t:q[ft:query(., $otherText)]]
	let $s10 := if ($interpret = "all") then
		$s9
	else
		$s9[descendant::t:seg/@ana = $interpret]
	let $s11 := if ($repo = "all") then
		$s10
	else
		$s10[ancestor::t:TEI//t:repository/@ref = $repo]
	let $s12 := if ($content = "all") then
		$s11
	else
		$s11[ancestor::t:TEI//t:msContents/t:msItem/t:title/@ref = $content]
	let $additions := if ($main-key = "all") then
		$s12
	else
		$s12[ancestor::t:TEI//t:textClass/t:keywords/t:term/@key = $main-key]
	return map {"hits": $additions}
};

(:~
 : Filters binding decoNotes (t:decoNote, xml:id starting with "b") by
 : type, target keyword, sewing-station count, binding material, color,
 : pastedown pattern, and fastening.
 :
 : @param $node the context node
 : @param $model the template model
 : @param $query unused (reserved for template signature compatibility)
 : @param $type t:decoNote type value(s) to match, or "all"
 : @param $target-keyword t:term key value(s) to match, or "all"
 : @param $SewingStationsN a sewing-stations count (type "SewingStations"), or "all"/""
 : @param $BindingMaterial t:material key value(s) to match, or "all"
 : @param $color a decoNote color value to match, or "all"
 : @param $pastedown a regex matched against the pastedown attribute, or "all"
 : @param $fastening a fastening description (type "Fastening") to match, or "all"
 : @return a map with "hits" (the matching t:decoNote nodes)
 :)
declare
	%templates:default("scope", "narrow")
	%templates:default("type", "all")
	%templates:default("target-keyword", "all")
	%templates:default("SewingStationsN", "all")
	%templates:default("BindingMaterial", "all")
	%templates:default("color", "all")
	%templates:default("pastedown", "all")
	%templates:default("fastening", "all")
function lists:SearchBinding(
	$node as node()*,
	$model as map(*),
	$query as xs:string*,
	$type as xs:string+,
	$target-keyword as xs:string+,
	$SewingStationsN as xs:string+,
	$BindingMaterial as xs:string+,
	$color as xs:string+,
	$pastedown as xs:string+,
	$fastening as xs:string+
) {
	(:
	 : filter steps applied only when active - see the comment in
	 : lists:additions for why chaining "[$x = 'all' or ...]" on every
	 : step regardless is a real performance regression, not just style.
	 :)
	let $s1 := $lists:collection-rootMS//t:decoNote[starts-with(@xml:id, "b")]
	let $s2 := if ($type = "all") then
		$s1
	else
		$s1[@type = $type]
	let $s3 := if ($target-keyword = "all") then
		$s2
	else
		$s2[descendant::t:term/@key = $target-keyword]
	let $s4 := if ($SewingStationsN = "all" or $SewingStationsN = "") then
		$s3
	else
		$s3[@type = "SewingStations" and . = $SewingStationsN]
	let $s5 := if ($BindingMaterial = "all") then
		$s4
	else
		$s4[descendant::t:material/@key = $BindingMaterial]
	let $s6 := if ($color = "all") then
		$s5
	else
		$s5[@color = $color]
	let $s7 := if ($pastedown = "all") then
		$s6
	else
		$s6[matches(@pastedown, $pastedown)]
	let $decos := if ($fastening = "all") then
		$s7
	else
		$s7[@type = "Fastening" and . = $fastening]
	return map {"hits": $decos}
};

(:~
 : Filters decoration decoNotes (t:decoNote, xml:id starting with "d") by
 : type, target work/artistic theme/person/place/keyword, repository,
 : content, and free-text legend/other-text search.
 :
 : @param $node the context node
 : @param $model the template model
 : @param $query unused (reserved for template signature compatibility)
 : @param $type t:decoNote type value(s) to match, or "all" (decoNotes
 : with no type attribute at all are always excluded)
 : @param $target-keyword t:term key value(s) to match, or "all"
 : @param $target-pers t:persName ref value(s) to match, or "all"
 : @param $target-place t:placeName ref value(s) to match, or "all"
 : @param $repo repository ref value(s) to match, or "all"
 : @param $content msItem title ref value(s) to match, or "all"
 : @param $target-work t:title ref value(s) to match, or "all"
 : @param $target-artTheme authFile t:ref corresp value(s) to match, or "all"
 : @param $legendText free text full-text-matched against descendant t:q
 : @param $otherText free text full-text-matched against descendant
 : t:foreign in Ge'ez
 : @return a map with "hits" (the matching t:decoNote nodes)
 :)
declare
	%templates:default("scope", "narrow")
	%templates:default("type", "all")
	%templates:default("target-pers", "all")
	%templates:default("target-place", "all")
	%templates:default("repo", "all")
	%templates:default("content", "all")
	%templates:default("target-work", "all")
	%templates:default("target-artTheme", "all")
	%templates:default("target-keyword", "all")
function lists:SearchDeco(
	$node as node()*,
	$model as map(*),
	$query as xs:string*,
	$type as xs:string+,
	$target-keyword as xs:string+,
	$target-pers as xs:string+,
	$target-place as xs:string+,
	$repo as xs:string+,
	$content as xs:string+,
	$target-work as xs:string+,
	$target-artTheme as xs:string+,
	$legendText as xs:string*,
	$otherText as xs:string*
) {
	(:
	 : filter steps applied only when active - see the comment in
	 : lists:additions for why chaining "[$x = 'all' or ...]" on every
	 : step regardless is a real performance regression, not just style.
	 :)
	let $s1 := $lists:collection-rootMS//t:decoNote[starts-with(@xml:id, "d")][@type]
	let $s2 := if ($type = "all") then
		$s1
	else
		$s1[@type = $type]
	let $s3 := if ($repo = "all") then
		$s2
	else
		$s2[ancestor::t:TEI//t:repository/@ref = $repo]
	let $s4 := if ($content = "all") then
		$s3
	else
		$s3[ancestor::t:TEI//t:msContents/t:msItem/t:title/@ref = $content]
	let $s5 := if ($target-work = "all") then
		$s4
	else
		$s4[descendant::t:title/@ref = $target-work]
	let $s6 := if ($target-artTheme = "all") then
		$s5
	else
		$s5[descendant::t:ref[@type = "authFile"]/@corresp = $target-artTheme]
	let $s7 := if ($target-pers = "all") then
		$s6
	else
		$s6[descendant::t:persName/@ref = $target-pers]
	let $s8 := if ($target-place = "all") then
		$s7
	else
		$s7[descendant::t:placeName/@ref = $target-place]
	let $s9 := if ($target-keyword = "all") then
		$s8
	else
		$s8[descendant::t:term/@key = $target-keyword]
	let $s10 := if (not($legendText)) then
		$s9
	else
		$s9[descendant::t:q[@xml:lang][ft:query(., $legendText)]]
	let $decos := if (not($otherText)) then
		$s10
	else
		$s10[descendant::t:foreign[@xml:lang = "gez"][ft:query(., $otherText)]]
	return map {"hits": $decos}
};

(:~
 : Filters ethiocal t:date entities by day/month, then by target work/
 : artistic theme/person/place/keyword scoped to each date's nearest
 : ancestor with an xml:id.
 :
 : @param $node the context node
 : @param $model the template model
 : @param $target-keyword t:term key value(s) to match, or "all"
 : @param $day an ethiocal day code (e.g. "Maskaram1") to match, or "all"
 : @param $month an ethiocal month name; only consulted via a dead branch
 : (see the inline comment below), so this currently has no effect
 : @param $target-pers t:persName ref value(s) to match, or "all"
 : @param $target-place t:placeName ref value(s) to match, or "all"
 : @param $target-work t:title ref value(s) to match, or "all"
 : @param $target-artTheme authFile t:ref corresp value(s) to match, or "all"
 : @return a map with "hits" (the matching t:date nodes)
 :)
declare
	%templates:default("scope", "narrow")
	%templates:default("target-pers", "all")
	%templates:default("day", "all")
	%templates:default("month", "all")
	%templates:default("target-place", "all")
	%templates:default("target-work", "all")
	%templates:default("target-artTheme", "all")
	%templates:default("target-keyword", "all")
function lists:SearchCalendar(
	$node as node()*,
	$model as map(*),
	$target-keyword as xs:string+,
	$day as xs:string+,
	$month as xs:string+,
	$target-pers as xs:string+,
	$target-place as xs:string+,
	$target-work as xs:string+,
	$target-artTheme as xs:string+
) {
	(:
	 : $anc is computed via a separate let, then filtered on its own,
	 : rather than chaining [1] and the filters into one predicate list
	 : on the ancestor step - eXist mis-evaluates that combined form for
	 : reverse axes (it silently drops real matches, verified against the
	 : raw data), so the original util:eval'd string, which built exactly
	 : that combined form, had the same latent bug.
	 :)
	let $dates :=
		for $d in
			$exptit:col//t:date[if ($day = "all") then
				starts-with(@ref, "ethiocal:")
			(:
			 : unreachable: $day = "all" is already caught above; kept
			 : as-is since the original's branch order made it dead
			 :)
			else if ($day = "all" and $month != "all") then
				starts-with(@ref, "ethiocal:" || $month)
			else
				@ref = "ethiocal:" || $day]
		let $anc := $d/ancestor::t:*[@xml:id][1]
		(:
		 : filter steps applied only when active - see the comment in
		 : lists:additions for why chaining "[$x = 'all' or ...]" on every
		 : step regardless is a real performance regression, not just style.
		 :)
		let $m1 := if ($target-work = "all") then
			$anc
		else
			$anc[descendant::t:title/@ref = $target-work]
		let $m2 := if ($target-artTheme = "all") then
			$m1
		else
			$m1[descendant::t:ref[@type = "authFile"]/@corresp = $target-artTheme]
		let $m3 := if ($target-pers = "all") then
			$m2
		else
			$m2[descendant::t:persName/@ref = $target-pers]
		let $m4 := if ($target-place = "all") then
			$m3
		else
			$m3[descendant::t:placeName/@ref = $target-place]
		let $m5 := if ($target-keyword = "all") then
			$m4
		else
			$m4[descendant::t:term/@key = $target-keyword]
		where exists($m5)
		return $d
	return map {"hits": $dates}
};

(:~
 : Searches titles, divs, segs, and colophon/incipit/explicit elements,
 : optionally scoped to a specific work and/or manuscript, and filtered by
 : type/subtype markers, target work/artistic theme/person/place/keyword,
 : and free-text query.
 :
 : @param $node the context node
 : @param $model the template model
 : @param $query free text full-text-matched against each candidate element
 : @param $typeval "all" (no filter), "marked" (a fixed set of structural
 : markers), or one or more custom type/subtype substrings
 : @param $target-keyword t:term key value(s) to match, or "all"
 : @param $target-pers t:persName ref value(s) to match, or "all"
 : @param $target-place t:placeName ref value(s) to match, or "all"
 : @param $target-work t:title ref value(s) to match, or "all"
 : @param $limit-mss an xml:id to scope the search to one manuscript, or ""
 : @param $limit-work an xml:id to scope the search to one work, or ""
 : @param $target-artTheme authFile t:ref corresp value(s) to match, or "all"
 : @param $elements "all", or one of "title"/"div"/"seg"/"colophon"/
 : "incipit"/"explicit" to search only that element kind
 : @return a map with "hits" (the matching nodes across all searched
 : element kinds)
 : @see https://github.com/BetaMasaheft/BetMasWeb/issues/45 limit-work/limit-mss error
 :)
declare
	%templates:default("scope", "narrow")
	%templates:default("typeval", "marked")
	%templates:default("target-pers", "all")
	%templates:default("target-place", "all")
	%templates:default("target-work", "all")
	%templates:default("target-mss", "all")
	%templates:default("limit-mss", "")
	%templates:default("limit-work", "")
	%templates:default("target-artTheme", "all")
	%templates:default("target-keyword", "all")
	%templates:default("elements", "all")
function lists:SearchTitles(
	$node as node()*,
	$model as map(*),
	$query as xs:string*,
	$typeval as xs:string+,
	$target-keyword as xs:string+,
	$target-pers as xs:string+,
	$target-place as xs:string+,
	$target-work as xs:string+,
	$limit-mss as xs:string+,
	$limit-work as xs:string+,
	$target-artTheme as xs:string+,
	$elements as xs:string+
) {
	let $values := (
		"subscriptio", "supplication", "embedded", "inscriptio", "translation", "expanded", "title", "desinit"
	)
	(:
	 : when $typeval = "marked" this checks against the fixed $values list;
	 : otherwise $typeval itself is already the caller-supplied list of
	 : substrings to match - either way "contains(@x, $typeValues)" is
	 : the OR-combination the old eval'd query built by hand. This relies
	 : on eXist's (non-standard but supported) form of contains() that
	 : takes a sequence as the second argument; the seemingly-more-correct
	 : "some $v in $typeValues satisfies contains(@x, $v)" measured 20x
	 : slower on this corpus (765ms vs 38ms per call), so it's kept as-is
	 : rather than made "properly" standard XPath.
	 :)
	let $typeValues := if ($typeval = "marked") then
		$values
	else
		$typeval
	let $works := if ($limit-work = "") then (
	) else
		$lists:collection-rootW//id($limit-work)
	let $mss := if ($limit-mss = "") then (
	) else
		$lists:collection-rootMS//id($limit-mss)
	(: t:title/@ref stores the full canonical URL, not the bare @xml:id this parameter arrives as :)
	let $limit-work-ref := if ($limit-work = "") then
		""
	else
		$config:BMurl || $limit-work
	(:
	 : $mssWork/$msitems are only ever read from $context below, in the
	 : "limit-work only" and "limit-work + limit-mss" branches respectively -
	 : guarding them here skips a $lists:collection-rootMS scan on the two
	 : other branches (no limits at all, or limit-mss only), which is the
	 : common case for a plain /titles page load.
	 :)
	let $mssWork := if ($limit-work-ref != "" and $limit-mss = "") then
		$lists:collection-rootMS//t:msItem[t:title[@ref eq $limit-work-ref]]
	else (
	)
	let $msitems := if ($limit-work-ref != "" and $limit-mss != "") then
		$mss//t:msItem[t:title[@ref eq $limit-work-ref]]
	else (
	)
	let $msitemsIDS := $msitems/@xml:id
	let $msSitemsIDS := $mssWork/@xml:id
	(:
	 : eq eq eq: eXist's range-index optimizer throws XPTY0004 on a
	 : zero-cardinality key sequence instead of returning zero hits (hence
	 : the exists() guards), and plain eq also rejects a many-item key
	 : sequence outright (a value comparison requires singleton operands) -
	 : realistic here whenever $limit-work matches more than one manuscript.
	 : = (general comparison) tolerates any cardinality on both sides.
	 :)
	let $divs := if (exists($msitemsIDS)) then
		$mss//t:div[@corresp = $msitemsIDS]
	else (
	)
	let $mssdivs := if (exists($msSitemsIDS)) then
		$mssWork/following::t:div[@corresp = $msSitemsIDS]
	else (
	)
	let $additions := if (exists($msitemsIDS)) then
		$mss//t:item[@corresp = $msitemsIDS]
	else (
	)
	let $mssadditions := if (exists($msSitemsIDS)) then
		$mssWork/following::t:item[@corresp = $msSitemsIDS]
	else (
	)
	let $workdivs := $works//t:div[@type eq "edition"]

	(:
	 : $context used to be built as a string naming one of these
	 : already-bound node-sequence variables, then util:eval'd - XQuery
	 : path steps distribute over a sequence-valued context, so binding
	 : $context to the real node sequence directly works the same way,
	 : with no eval needed.
	 :
	 : if the search is limited to a set of manuscripts or a set of works, the context changes.
	 : first if the no limit is set, we will search all the collection
	 :)
	let $context := if ($limit-work = "" and $limit-mss = "") then
		$exptit:col
	(: if the search is limited by work, then we want to search
                                - the file of that work,
                                - the relevant parts of manuscripts which contain that work
                                this assumes that if also parts or related works are wanted, the parameter should list those already :)
	else if ($limit-work != "" and $limit-mss = "") then (
		$workdivs, $mssWork, $mssadditions, $mssdivs
	) (: if the search is limited by manuscript, then we want to search
                                - the files of those manuscripts :) else if ($limit-work = "" and $limit-mss != "") then
		$mss
	(: if the search is limited by manuscript and work
                                - the relevant parts of those manuscripts which contain that work
                                this assumes that if also parts or related works are wanted, the parameter should list those already :)
	else (
		$msitems, $additions, $divs
	)

	(:
	 : filter steps applied only when active - see the comment in
	 : lists:additions for why chaining "[$x = 'all' or ...]" on every
	 : step regardless is a real performance regression, not just style.
	 :)
	let $titles := if ($elements = "all" or $elements = "title") then
		let $t1 := $context//t:title[not(parent::t:titleStmt)]
		let $t2 := if ($typeval = "all") then
			$t1
		else
			$t1[contains(@subtype, $typeValues)]
		let $t3 := if ($target-work = "all") then
			$t2
		else
			$t2[descendant::t:title/@ref = $target-work]
		let $t4 := if ($target-artTheme = "all") then
			$t3
		else
			$t3[descendant::t:ref[@type = "authFile"]/@corresp = $target-artTheme]
		let $t5 := if ($target-pers = "all") then
			$t4
		else
			$t4[descendant::t:persName/@ref = $target-pers]
		let $t6 := if ($target-place = "all") then
			$t5
		else
			$t5[descendant::t:placeName/@ref = $target-place]
		let $t7 := if ($target-keyword = "all") then
			$t6
		else
			$t6[descendant::t:term/@key = $target-keyword]
		return if (not($query)) then
			$t7
		else
			$t7[ft:query(., $query)]
	else (
	)
	let $divsResult := if ($elements = "all" or $elements = "div") then
		let $d1 := $context//t:div
		let $d2 := if ($typeval = "all") then
			$d1
		else
			$d1[contains(@subtype, $typeValues)]
		let $d3 := if ($target-work = "all") then
			$d2
		else
			$d2[descendant::t:title/@ref = $target-work]
		let $d4 := if ($target-artTheme = "all") then
			$d3
		else
			$d3[descendant::t:ref[@type = "authFile"]/@corresp = $target-artTheme]
		let $d5 := if ($target-pers = "all") then
			$d4
		else
			$d4[descendant::t:persName/@ref = $target-pers]
		let $d6 := if ($target-place = "all") then
			$d5
		else
			$d5[descendant::t:placeName/@ref = $target-place]
		let $d7 := if ($target-keyword = "all") then
			$d6
		else
			$d6[descendant::t:term/@key = $target-keyword]
		return if (not($query)) then
			$d7
		else
			$d7[ft:query(., $query)]
	else (
	)
	let $segs := if ($elements = "all" or $elements = "seg") then
		let $sg1 := $context//t:seg[not(ancestor::t:handDesc)]
		let $sg2 := if ($typeval = "all") then
			$sg1
		else
			$sg1[contains(@type, $typeValues)]
		let $sg3 := if ($target-work = "all") then
			$sg2
		else
			$sg2[descendant::t:title/@ref = $target-work]
		let $sg4 := if ($target-artTheme = "all") then
			$sg3
		else
			$sg3[descendant::t:ref[@type = "authFile"]/@corresp = $target-artTheme]
		let $sg5 := if ($target-pers = "all") then
			$sg4
		else
			$sg4[descendant::t:persName/@ref = $target-pers]
		let $sg6 := if ($target-place = "all") then
			$sg5
		else
			$sg5[descendant::t:placeName/@ref = $target-place]
		let $sg7 := if ($target-keyword = "all") then
			$sg6
		else
			$sg6[descendant::t:term/@key = $target-keyword]
		return if (not($query)) then
			$sg7
		else
			$sg7[ft:query(., $query)]
	else (
	)
	let $colincex :=
		for $cie in ("colophon", "incipit", "explicit")
		return if ($elements = "all" or $elements = $cie) then
			(:
			 : a static named step (//t:colophon etc) instead of
			 : t:*[local-name() = $cie] - the latter forces a scan of
			 : every element in $context to check its name instead of
			 : eXist's fast named-descendant lookup; measured 226x
			 : slower (19s vs 84ms) on this corpus.
			 :)
			let $c1 := switch ($cie)
				case "colophon" return
					$context//t:colophon
				case "incipit" return
					$context//t:incipit
				case "explicit" return
					$context//t:explicit
				default return
					()
			let $c2 := if ($typeval = "all") then
				$c1
			else
				$c1[contains(@type, $typeValues)]
			let $c3 := if ($target-work = "all") then
				$c2
			else
				$c2[descendant::t:title/@ref = $target-work]
			let $c4 := if ($target-artTheme = "all") then
				$c3
			else
				$c3[descendant::t:ref[@type = "authFile"]/@corresp = $target-artTheme]
			let $c5 := if ($target-pers = "all") then
				$c4
			else
				$c4[descendant::t:persName/@ref = $target-pers]
			let $c6 := if ($target-place = "all") then
				$c5
			else
				$c5[descendant::t:placeName/@ref = $target-place]
			let $c7 := if ($target-keyword = "all") then
				$c6
			else
				$c6[descendant::t:term/@key = $target-keyword]
			return if (not($query)) then
				$c7
			else
				$c7[ft:query(., $query)]
		else (
		)
	let $allTitles := ($titles | $divsResult | $segs | $colincex)
	(:
	 : computed once here and shared via $model with the descendant
	 : lists:titlesform/lists:titlesRes templates (both nested inside this
	 : function's own div in titles.html), instead of each of them calling
	 : lists:typeGroupsMap($allTitles) separately - see
	 : .claude/notes/performance.plan.md item 7
	 :)
	let $typeGroups := lists:typeGroupsMap($allTitles)
	return map {"hits": $allTitles, "typeGroups": $typeGroups}
};

declare function lists:biblform($node as node(), $model as map(*)) {
	<form xmlns="http://www.w3.org/1999/xhtml" action="" class="w3-container">
		<div class="w3-container w3-margin-bottom">
			<small class="form-text text-muted">Select one
   or more type of bibliography</small>
			<br />
			<label class="checkbox"><input class="w3-check" name="type" type="checkbox" value="secondary" />secondary</label>
			<br />
			<label class="checkbox"><input class="w3-check" name="type" type="checkbox" value="editions" />editions</label>
			<br />
			<label class="checkbox">
				<input class="w3-check" name="type" type="checkbox" value="translation" />translation</label>
			<br />
			<label class="checkbox"><input class="w3-check" name="type" type="checkbox" value="text" />text</label>
			<br />
			<label class="checkbox"><input class="w3-check" name="type" type="checkbox" value="clavis" />clavis</label>
			<br />
			<label class="checkbox"><input class="w3-check" name="type" type="checkbox" value="catalogue" />catalogue</label>
			<br />
			<label class="checkbox">
				<input class="w3-check" name="type" type="checkbox" value="otherLanguages" />otherLanguages</label>
			<br />
		</div>
		<div class="w3-container w3-margin-bottom">
			<small class="form-text text-muted">enter a Zotero bm:id</small>
			<input class="w3-input w3-border" name="pointer" placeholder="bm:" />
		</div>
		<div class="w3-container w3-margin-bottom">
			<small class="form-text text-muted">Select a collection</small>
			<select class="w3-select w3-border" name="collection">
				<option value="all">all</option>
				<option value="mss">Manuscripts</option>
				<option value="work">Works</option>
				<option value="pers">Persons</option>
				<option value="place">Places</option>
				<option value="ins">Repositories</option>
				<option value="auth">Authority Files</option>
			</select>
		</div>
		<div class="w3-container w3-margin-top">
			<div class="w3-bar">
				<button class="w3-bar-item w3-button w3-red" type="submit">
					<i aria-hidden="true" class="fa fa-search" />
				</button>
				<a class="w3-bar-item w3-button w3-gray" href="/bibliography" role="button">
					<i aria-hidden="true" class="fa fa-th-list" />
				</a>
			</div>
		</div>
	</form>
};

declare function lists:additionsform($node as node(), $model as map(*)) {
	let $auth := $lists:collection-rootA
	return <form action="" class="w3-container">
		<div id="additiontypes" />
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">Search in the text of marked terms</small>
			<br />
			<input class="w3-input w3-border" name="termText" />
		</div>
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">Search in the text of the documents or additions</small>
			<br />
			<input class="w3-input w3-border" name="otherText" />
		</div>
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">Select manuscript repository</small>
			<br />
			<select
				xmlns="http://www.w3.org/1999/xhtml"
				class="w3-select w3-border"
				id="repo"
				multiple="multiple"
				name="repo"
			>
				{
					for $d in config:distinct-values($model("hits")/ancestor::t:TEI//t:repository/@ref)
					order by exptit:printTitle($d)
					return <option value="{ $d }">{ exptit:printTitle($d) }</option>
				}
			</select>
		</div>
		{
			if ($model("hits")/ancestor::t:TEI//t:msItem/t:title/@ref) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select main content in the manuscripts</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="content"
						multiple="multiple"
						name="content"
					>
						{
							for $d in
								config:distinct-values(
									$model("hits")/ancestor::t:TEI//t:msContents/t:msItem/t:title/@ref[not(contains(., "IHA"))]
								)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")/ancestor::t:TEI//t:textClass/t:keywords/t:term/@key) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select main keywords associated with the manuscripts</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="main-key"
						multiple="multiple"
						name="main-key"
					>
						{
							for $d in config:distinct-values($model("hits")/ancestor::t:TEI//t:textClass/t:keywords/t:term/@key)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:q) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select the language of the additions you want to see</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-language"
						multiple="multiple"
						name="target-language"
					>
						{
							for $d in config:distinct-values($model("hits")//t:q/@xml:lang)
							order by $d
							return <option value="{ $d }">{ data($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:title) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more works referred to in the document or addition</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-work"
						multiple="multiple"
						name="target-work"
					>
						{
							for $d in config:distinct-values($model("hits")//t:title/@ref)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:seg) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more interpretation segments</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-int"
						multiple="multiple"
						name="interpret"
					>
						{
							for $d in config:distinct-values($model("hits")//t:seg/@ana)
							order by $d
							return <option value="{ $d }">{ substring-after($d, "#") }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:persName) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more persons referred to in the document or addition</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-pers"
						multiple="multiple"
						name="target-pers"
					>
						{
							for $d in
								config:distinct-values($model("hits")//t:persName/@ref[not(contains(., ".xml"))][not(contains(., "#"))])
							order by replace(data($d), "^.*[0-9]", "")
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:placeName) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more places referred to in the document or addition</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-place"
						multiple="multiple"
						name="target-place"
					>
						{
							for $d in config:distinct-values($model("hits")//t:placeName/@ref[not(contains(., ".xml"))])
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:term) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more keywords referred to in the document or addition</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-keyword"
						multiple="multiple"
						name="target-keyword"
					>
						{
							for $d in config:distinct-values($model("hits")//t:term/@key)
							order by $d
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		<div class="w3-container w3-margin-top">
			<div class="w3-bar">
				<button class="w3-bar-item w3-button w3-red" type="submit">
					<i aria-hidden="true" class="fa fa-search" />
				</button>
				<a class="w3-bar-item w3-button w3-gray" href="/additions" role="button">
					<i aria-hidden="true" class="fa fa-th-list" />
				</a>
			</div>
		</div>
	</form>
};

declare function lists:titlesform($node as node(), $model as map(*)) {
	let $auth := $lists:collection-rootA
	return <form action="" class="w3-container">
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Search Text</small>
			<br />
			<input class="w3-input w3-border" name="query" />
		</div>
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Limit to Textual Units, adding a list of space separated identifiers</small>
			<br />
			<input class="w3-input w3-border" name="limit-work" />
		</div>
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Limit to Manuscripts, adding a list of space separated identifiers</small>
			<br />
			<input class="w3-input w3-border" name="limit-mss" />
		</div>
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Limit by type</small>
			<br />
			<select class="w3-select w3-border" multiple="multiple" name="typeval">
				<option selected="selected" val="marked">marked</option>
				{
					let $groupsMap := if (exists($model("typeGroups"))) then
						$model("typeGroups")
					else
						lists:typeGroupsMap($model("hits"))
					for $d in map:keys($groupsMap)
					return <option value="{ $d }">{ $d } ({ count($groupsMap($d)) })</option>
				}
				<option value="all">all</option>
			</select>
		</div>
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Limit to a specific context element</small>
			<br />
			<select class="w3-select w3-border" multiple="multiple" name="elements">
				{
					for $d in config:distinct-values($model("hits")/name())
					return <option value="{ $d }">{ $d } ({ count($model("hits")[name() = $d]) })</option>
				}
			</select>
		</div>
		{
			if ($model("hits")//t:ref[@type eq "authFile"]) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more Art Themes associated with the title/colophon/supplication</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-artTheme"
						multiple="multiple"
						name="target-artTheme"
					>
						{
							for $d in config:distinct-values($model("hits")//t:ref[@type eq "authFile"]/@corresp)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:title) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more works referred to in the title/colophon/supplication</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-work"
						multiple="multiple"
						name="target-work"
					>
						{
							for $d in config:distinct-values($model("hits")//t:title/@ref)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:persName) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more persons referred to in the title/colophon/supplication</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-pers"
						multiple="multiple"
						name="target-pers"
					>
						{
							for $d in config:distinct-values($model("hits")//t:persName/@ref)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:placeName) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more places referred to in the title/colophon/supplication</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-place"
						multiple="multiple"
						name="target-place"
					>
						{
							for $d in config:distinct-values($model("hits")//t:placeName/@ref)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:term) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more keywords referred to in the title/colophon/supplication</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-keyword"
						multiple="multiple"
						name="target-keyword"
					>
						{
							for $d in config:distinct-values($model("hits")//t:term/@key)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		<div class="w3-container w3-margin">
			<div class="w3-bar">
				<button class="w3-bar-item w3-button w3-red" type="submit">
					<i aria-hidden="true" class="fa fa-search" />
				</button>
				<a class="w3-bar-item w3-button w3-gray" href="/titles" role="button">
					<i aria-hidden="true" class="fa fa-th-list" />
				</a>
			</div>
		</div>
	</form>
};

declare function lists:decorationsform($node as node(), $model as map(*)) {
	let $auth := $lists:collection-rootA
	return <form action="" class="w3-container">
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Select one or more type of decoration</small>
			<br />
			{
				for $d in config:distinct-values($model("hits")/@type)
				order by $d
				return (
					<label class="checkbox">
						<input class="w3-check" name="type" type="checkbox" value="{ $d }" />
						{ string($d) }
					</label>,
					<br />
				)
			}
		</div>
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Search in the text of the legends</small>
			<br />
			<input class="w3-input w3-border" name="legendText" />
		</div>
		<div class="w3-container  w3-margin">
			<small class="form-text text-muted">Select in text on the decorations which is not the legend</small>
			<br />
			<input class="w3-input w3-border" name="otherText" />
		</div>
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">Select manuscript repository</small>
			<br />
			<select
				xmlns="http://www.w3.org/1999/xhtml"
				class="w3-select w3-border"
				id="repo"
				multiple="multiple"
				name="repo"
			>
				{
					for $d in config:distinct-values($model("hits")/ancestor::t:TEI//t:repository/@ref)
					order by exptit:printTitle($d)
					return <option value="{ $d }">{ exptit:printTitle($d) }</option>
				}
			</select>
		</div>
		{
			if ($model("hits")//t:ref[@type eq "authFile"]) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more Art Themes associated with the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-artTheme"
						multiple="multiple"
						name="target-artTheme"
					>
						{
							for $d in config:distinct-values($model("hits")//t:ref[@type eq "authFile"]/@corresp)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:title) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more works referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-work"
						multiple="multiple"
						name="target-work"
					>
						{
							for $d in config:distinct-values($model("hits")//t:title/@ref)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:persName) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more persons referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-pers"
						multiple="multiple"
						name="target-pers"
					>
						{
							for $d in config:distinct-values($model("hits")//t:persName/@ref)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:placeName) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more places referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-place"
						multiple="multiple"
						name="target-place"
					>
						{
							for $d in config:distinct-values($model("hits")//t:placeName/@ref)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")/ancestor::t:TEI//t:msItem/t:title/@ref) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select main content in the manuscripts</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="content"
						multiple="multiple"
						name="content"
					>
						{
							for $d in
								config:distinct-values(
									$model("hits")/ancestor::t:TEI//t:msContents/t:msItem/t:title/@ref[not(contains(., "IHA"))]
								)
							order by exptit:printTitle($d)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:term) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more artistic elements referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-keyword"
						multiple="multiple"
						name="target-keyword"
					>
						{
							for $d in config:distinct-values($model("hits")//t:term/@key)
							order by $d
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		<div class="w3-container w3-margin">
			<div class="w3-bar">
				<button class="w3-bar-item w3-button w3-red" type="submit">
					<i aria-hidden="true" class="fa fa-search" />
				</button>
				<a class="w3-bar-item w3-button w3-gray" href="/decorations" role="button">
					<i aria-hidden="true" class="fa fa-th-list" />
				</a>
			</div>
		</div>
	</form>
};

declare function lists:calendarform($node as node(), $model as map(*)) {
	let $auth := $lists:collection-rootA
	return <form action="" class="w3-container">
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">Select a month</small>
			<br />
			<select
				xmlns="http://www.w3.org/1999/xhtml"
				class="w3-select w3-border"
				id="month"
				multiple="multiple"
				name="month"
			>
				{
					for $d at $p in $lists:cal//t:body/t:list/t:item/@xml:id
					order by $p
					return <option value="{ string($d) }">{ string($d) }</option>
				}
			</select>
		</div>
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">Select a day</small>
			<br />
			<select xmlns="http://www.w3.org/1999/xhtml" class="w3-select w3-border" id="day" multiple="multiple" name="day">
				{
					for $d at $p in $lists:cal//t:body/t:list/t:item/t:list/t:item
					order by $p
					return <option value="{ string($d/@xml:id) }">{ $d/text() }</option>
				}
			</select>
		</div>
		{
			if ($model("hits")//t:ref[@type eq "authFile"]) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more Art Themes associated with the date</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-artTheme"
						multiple="multiple"
						name="target-artTheme"
					>
						{
							for $d in config:distinct-values($model("hits")//t:ref[@type eq "authFile"]/@corresp)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")/parent::t:*[@xml:id][1]//t:title) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more works referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-work"
						multiple="multiple"
						name="target-work"
					>
						{
							for $d in config:distinct-values($model("hits")/parent::t:*[@xml:id][1]//t:title/@ref)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")/parent::t:*[@xml:id][1]//t:persName) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more persons referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-pers"
						multiple="multiple"
						name="target-pers"
					>
						{
							for $d in config:distinct-values($model("hits")/parent::t:*[@xml:id][1]//t:persName/@ref)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")/parent::t:*[@xml:id][1]//t:placeName) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more places referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-place"
						multiple="multiple"
						name="target-place"
					>
						{
							for $d in config:distinct-values($model("hits")/parent::t:*[@xml:id][1]//t:placeName/@ref)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")/parent::t:*[@xml:id][1]//t:term) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select one or more artistic elements referred to in the decoration description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-keyword"
						multiple="multiple"
						name="target-keyword"
					>
						{
							for $d in config:distinct-values($model("hits")/parent::t:*[@xml:id][1]//t:term/@key)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		<div class="w3-container w3-margin">
			<div class="w3-bar">
				<button class="w3-bar-item w3-button w3-red" type="submit">
					<i aria-hidden="true" class="fa fa-search" />
				</button>
				<a class="w3-bar-item w3-button w3-gray" href="/decorations" role="button">
					<i aria-hidden="true" class="fa fa-th-list" />
				</a>
			</div>
		</div>
	</form>
};

declare function lists:bindingsform($node as node(), $model as map(*)) {
	let $auth := $lists:collection-rootA
	return <form action="" class="w3-container">
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">Select one or more type of decoration</small>
			<br />
			{
				for $d in config:distinct-values($model("hits")/@type)
				return (
					<label class="checkbox">
						<input class="w3-check" name="type" type="checkbox" value="{ $d }" />
						{ string($d) }
					</label>,
					<br />
				)
			}
		</div>
		{
			if ($model("hits")//t:term) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select one or more features of the binding description</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="target-keyword"
						multiple="multiple"
						name="target-keyword"
					>
						{
							for $d in config:distinct-values($model("hits")//t:term/@key)
							return <option value="{ $d }">{ exptit:printTitle($d) }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//@color) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select a color</small>
					<br />
					<select xmlns="http://www.w3.org/1999/xhtml" class="w3-select w3-border" id="color" name="color">
						<option value="all">all</option>
						{
							for $d in config:distinct-values($model("hits")//@color)
							return <option value="{ $d }">{ $d }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//@pastedown) then
				<div class="w3-container w3-margin">
					<small
						class="form-text text-muted"
					>Select a pastedown type (will search only manuscripts where this is present)</small>
					<br />
					<select xmlns="http://www.w3.org/1999/xhtml" class="w3-select w3-border" id="pastedown" name="pastedown">
						<option value="all">all</option>
						{
							for $d in config:distinct-values($model("hits")//@pastedown)
							return <option value="{ $d }">{ $d }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:material) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select a binding material</small>
					<br />
					<select
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-select w3-border"
						id="BindingMaterial"
						name="BindingMaterial"
					>
						<option value="all">all</option>
						{
							for $d in config:distinct-values($model("hits")//t:material/@key)
							return <option value="{ $d }">{ $d }</option>
						}
					</select>
				</div>
			else (
			)
		}
		{
			if ($model("hits")//t:decoNote[@type eq "Fastening"]) then
				<div class="w3-container w3-margin">
					<small class="form-text text-muted">Select a fastening feature</small>
					<br />
					<select xmlns="http://www.w3.org/1999/xhtml" class="w3-select w3-border" id="Fastening" name="fastening">
						<option value="all">all</option>
						{
							for $d in $model("hits")//t:decoNote[@type eq "Fastening"]
							return <option value="{ $d/text() }">{ $d/text() }</option>
						}
					</select>
				</div>
			else (
			)
		}
		<div class="w3-container w3-margin">
			<small class="form-text text-muted">number of Sewing stations</small>
			<br />
			<input class="w3-input w3-border" id="SewingStationsN" name="SewingStationsN" type="number" />
		</div>
		<div class="w3-container w3-margin">
			<div class="w3-bar">
				<button class="w3-bar-item w3-button w3-red" type="submit">
					<i aria-hidden="true" class="fa fa-search" />
				</button>
				<a class="w3-bar-item w3-button w3-gray" href="/bindings" role="button">
					<i aria-hidden="true" class="fa fa-th-list" />
				</a>
			</div>
		</div>
	</form>
};

declare %templates:wrap %templates:default("start", 1) %templates:default("per-page", 10) function lists:biblRes(
	$node as node(),
	$model as map(*),
	$start as xs:integer,
	$per-page as xs:integer
) {
	for $target at $p in subsequence($model("hits"), $start, $per-page)
	let $ptrs := $model("coll")//t:ptr[@target eq $target]
	let $count := count($ptrs)
	return <div class="w3-container w3-padding w3-border-bottom">
		<div class="w3-half w3-padding">
			<div class="w3-col" id="{ $target }" style="width:90%">
				{ doc("/db/apps/lists/bibliography.xml")//*:entry[@xml:id = $target]/*:reference }
			</div>
			<div class="w3-col w3-center" style="width:10%">
				<a href="https://www.zotero.org/groups/358366/ethiostudies/items/tag/{ $target }" target="_blank">
					<img src="/resources/images/zotero_16x16x32.png" style="display:inline;" />
				</a>
				<br />
				<span class="w3-small w3-tag w3-gray w3-margin-top w3-hide-small" style="word-break: break-all;">
					{ $target }
				</span>
			</div>
		</div>
		<div class="w3-half w3-padding">
			<div class="w3-threequarter">
				<ul class="w3-ul w3-hoverable">
					{
						for $citingentity in $ptrs/@target
						let $stringR := string(root($citingentity)/t:TEI/@xml:id)
						let $cr := $citingentity/parent::t:ptr/following-sibling::t:citedRange/text()
						let $n := number($cr[1] => replace("-", "") => replace("[a-zA-Z]", ""))
						group by $root := $stringR
						order by $n[1] ascending
						return <li class="w3-padding">
							<a href="{ $root }">{ exptit:printTitle($root) }</a>
							{
								let $ranges :=
									for $c in $citingentity
									let $cr := $c/parent::t:ptr/following-sibling::t:citedRange
									order by $cr[1]
									return if ($cr) then (
										string($cr[1]/@unit) || ", " || $cr[1]/text()
									) else (
									)
								return if (count($ranges) ge 1) then (
									" (" || string-join($ranges, "; ") || ")"
								) else (
								)
							}
						</li>
					}
				</ul>
			</div>
			<div class="w3-quarter w3-center w3-hide-small"><span class="w3-tag w3-gray">{ $count }</span></div>
		</div>
	</div>
};

declare %templates:wrap function lists:addRes($node as node(), $model as map(*)) {
	let $data := $model("hits")
	return for $addition at $p in $data
		let $t := if ($addition//t:desc/@type) then
			string-join($addition//t:desc/@type)
		else
			"undefined"
		group by $type := $t
		order by $type
		let $tit := exptit:printTitleID($type)
		return (
			<button class="w3-button w3-block w3-gray w3-margin-bottom" onclick="openAccordion('{ data($type) }')">
				<span class="w3-badge w3-right">
					{
						if ($type = "undefined") then
							count($data[not(descendant::t:desc/@type)])
						else
							count($data/t:desc[@type eq $type])
					}
				</span>
				<span class="w3-left additionType" data-value="{ $type }">
					{
						if ($type = "undefined") then
							$type
						else
							$tit
					}
				</span>
			</button>,
			<div class="w3-container w3-hide" id="{ data($type) }">
				<div>
					{
						if (count($addition) gt 100) then
							<span> (showing up to 100 results; use filters to narrow down your search)</span>
						else (
						)
					}
				</div>
				<ul class="w3-ul w3-padding w3-hoverable">
					{
						let $start := xs:integer(request:get-parameter("start", "1"))
						let $num := xs:integer(request:get-parameter("num", "100"))
						for $a in subsequence($addition, $start, $num)

						let $fileID := data($a/ancestor::t:TEI/@xml:id)
						let $additionID := data($a/@xml:id)
						order by $fileID
						return <li>
							<a href="{ $fileID }#{ $additionID }">{ $fileID },{ $additionID }</a> |
            <div
								class="additionTextContent w3-container"
							>
								<div id="{ $fileID }_{ $additionID }">
									{
										if ($a//t:relation[@name eq "saws:formsPartOf"][contains(@passive, "corpus")]) then (
											<p>Document in Corpus <a href="/{ $a//t:relation/@passive }/corpus">
													{ string($a//t:relation/@passive) }
												</a>
											</p>
										) else (
										)
									}
									{
										for $q in $a//t:q
										return <p>
											{
												if ($q[@xml:lang = "gez"]) then
													attribute class { "gez" }
												else (
												)
											}
											{ $q }
										</p>
									}
								</div>
							</div>
						</li>
					}
				</ul>
			</div>
		)
};

declare %templates:wrap function lists:bindingRes($node as node(), $model as map(*)) {
	for $binding at $p in $model("hits")
	let $t := $binding/@type
	(: group by type :)
	group by $type := $t
	order by $type
	return (
		<button class="w3-button w3-block w3-gray w3-padding w3-margin-bottom" onclick="openAccordion('{ data($type) }')">
			<span class="w3-badge w3-right">{ count($binding) }</span>
			<span class="w3-left " data-value="{ $type }">{ string($type) }</span>
		</button>,
		<div class="w3-container w3-hide" id="{ data($type) }">
			{
				for $b in $binding
				let $msid := $b/ancestor::t:TEI/@xml:id

				(: group by containing ms :)
				group by $ms := $msid
				order by $ms
				return (
					<button
						class="w3-button w3-block w3-red w3-padding w3-margin-bottom"
						onclick="openAccordion('{ data($ms) }{ data($type) }')"
					>
						<span class="w3-badge w3-right">{ count($b) }</span>
						<span class="w3-left " data-value="{ $type }">
							{ $lists:collection-rootMS//id($ms)//t:msIdentifier/t:idno }
						</span>
					</button>,
					<div class="w3-container w3-hide" id="{ data($ms) }{ data($type) }">
						<ul class="w3-ul w3-hoverable">
							{
								for $sb in $b
								let $images := root($sb)//t:msIdentifier/t:idno
								let $locus := string($sb/t:locus/@facs)
								order by $sb/@xml:id
								return <li>
									<a href="{ data($ms) }#{ data($sb/@xml:id) }">{ data($sb/@xml:id) }</a>: {
										try { string:tei2string($sb/node()) } catch * {
											(($err:code || ": " || $err:description), string-join($sb//text(), " "))
										}
									}
								</li>
							}
						</ul>
					</div>
				)
			}
		</div>
	)
};

declare %templates:wrap function lists:calendarRes($node as node(), $model as map(*)) {
	for $date at $p in $model("hits")
	let $t := substring-after($date/@ref, "ethiocal:")
	(: group by type :)
	group by $type := $t
	order by $type
	return (
		<button class="w3-button w3-block w3-gray w3-padding w3-margin-bottom" onclick="openAccordion('{ data($type) }')">
			<span class="w3-badge w3-right">{ count($date) }</span>
			<span class="w3-left " data-value="{ $type }">{ string($type) }</span>
		</button>,
		<div class="w3-container w3-hide" id="{ data($type) }">
			{
				for $d in $date
				let $msid := $d/ancestor::t:TEI/@xml:id

				(: group by containing ms :)
				group by $ms := $msid
				order by $ms
				return (
					<button
						class="w3-button w3-block w3-red w3-padding w3-margin-bottom"
						onclick="openAccordion('{ data($ms) }{ data($type) }')"
					>
						<span class="w3-badge w3-right">{ count($d) }</span>
						<span class="w3-left " data-value="{ $type }">{ exptit:printTitleID($ms) }</span>
					</button>,
					<div class="w3-container w3-hide" id="{ data($ms) }{ data($type) }">
						<ul class="w3-ul w3-hoverable">
							{
								for $sd in $d
								let $parentID := $sd/ancestor::t:*[@xml:id][1]/@xml:id
								let $parentName := $sd/ancestor::t:*[@xml:id][1]/name()
								order by $parentID
								return <li>
									<a
										href="{ data($ms) }{
											if ($parentID != $ms) then
												"#" || data($parentID)
											else (
											)
										}"
									>
										{
											if ($parentID != $ms) then
												"In a " || $parentName || " element with xml:id " || data($parentID)
											else (
												"within the file: "
											)
										}
									</a>:
            {
										try { string:tei2string($sd/node()) } catch * {
											(($err:code || ": " || $err:description), string-join($sd//text(), " "))
										}
									}
								</li>
							}
						</ul>
					</div>
				)
			}
		</div>
	)
};

declare %templates:wrap function lists:decoRes($node as node(), $model as map(*)) {
	for $decoration at $p in $model("hits")
	let $t := $decoration/@type
	(: group by type :)
	group by $type := $t
	order by $type
	return (
		<button class="w3-button w3-block w3-gray w3-padding w3-margin-bottom" onclick="openAccordion('{ data($type) }')">
			<span class="w3-badge w3-right">{ count($decoration) }</span>
			<span class="w3-left additionType" data-value="{ $type }">{ string($type) }</span>
		</button>,
		<div class="w3-container w3-hide" id="{ data($type) }">
			<div class="w3-container" id="{ data($type) }">
				{
					if (count($decoration) gt 400) then
						<div>Showing up to 400 results; use filters to narrow down the search results</div>
					else (
					),
					let $start := xs:integer(request:get-parameter("start", "1"))
					let $num := xs:integer(request:get-parameter("num", "400"))
					for $d in subsequence($decoration, $start, $num)
					let $msid := $d/ancestor::t:TEI/@xml:id
					(: group by containing ms :)
					group by $ms := $msid
					order by $ms
					return (
						<button
							class="w3-button w3-block w3-red  w3-margin-bottom"
							onclick="openAccordion('{ data($ms) }{ data($type) }')"
						>
							<span class="w3-left">{ $lists:collection-rootMS//id($ms)//t:msIdentifier/t:idno }</span>
							<span class="w3-badge w3-right">{ count($d) }</span>
						</button>,
						<div class="w3-container w3-hide" id="{ data($ms) }{ data($type) }">
							<ul class="w3-ul w3-hoverable">
								{
									for $sd in $d
									let $images := root($sd)//t:msIdentifier/t:idno
									let $locusfacs := string($sd/t:locus[1]/@facs)
									let $locusfirst := if (contains($locusfacs, " ")) then
										substring-before($locusfacs, " ")
									else
										$locusfacs
									let $locus := replace($locusfirst, "[a-z\s]", "")
									order by $sd/@xml:id
									return <li class="w3-container">
										{
											if ($images/@facs and $locus) then (
												<a href="/manuscripts/{ $ms }/viewer" target="_blank">
													<img
														class="thumb"
														src="{
															if (starts-with($ms, "BML")) then
																$config:appUrl ||
																	"/iiif/" ||
																	string($images/@facs) ||
																	$locus ||
																	".tif/full/150,/0/default.jpg"
															else if (starts-with($ms, "ES")) then
																$config:appUrl ||
																	"/iiif/" ||
																	string($images/@facs) ||
																	"_" ||
																	$locus ||
																	".tif/full/150,/0/default.jpg"
															else if (starts-with($ms, "EMIP")) then
																$config:appUrl ||
																	"/iiif/" ||
																	string($images/@facs) ||
																	$locus ||
																	".tif/full/150,/0/default.jpg"
															else if (starts-with($ms, "BNF")) then
																replace($images/@facs, "ark:", "iiif/ark:") ||
																	"/" ||
																	$locus ||
																	"/full/150,/0/native.jpg"
															else if (starts-with($ms, "BAV")) then
																replace(substring-before($images/@facs, "/manifest.json"), "iiif", "pub/digit") ||
																	"/thumb/" ||
																	substring-before(substring-after($images/@facs, "MSS_"), "/manifest.json") ||
																	"_" ||
																	$locus ||
																	".tif.jpg"
															else (
															)
														}"
														style="width:10%" />
												</a>
											) else (
											)
										}
										<p class="w3-rest">
											<a href="{ data($ms) }#{ data($sd/@xml:id) }">{ data($sd/@xml:id) }</a>
											<br />
											{
												if (count($sd//t:ref[@type eq "authFile"]) ge 1) then
													<span>Art themes: </span>
												else (
												),
												for $at in $sd//t:ref[@type eq "authFile"]
												return <a href="{ string($at/@corresp) }">
													{ concat(string-join(exptit:printTitle($at/@corresp), " "), ", ") }
												</a>
											}
										</p>
									</li>
								}
							</ul>
						</div>
					)
				}
			</div>
		</div>
	)
};

(:~
 : Single-pass replacement for the former lists:typedistvalues +
 : lists:typegroups pair, which re-scanned $hits once per distinct
 : type/subtype tag (O(distinct-tags × |hits|), the dominant cost of an
 : unscoped /titles or /additions-style page - see
 : .claude/notes/performance.plan.md item 1). Tokenizes each relevant
 : node's @type/@subtype once and groups natively, instead of re-testing
 : every node against every candidate tag.
 :
 : Preserves the original two-scope behaviour exactly (verified 2026-08-21
 : against a real corpus - a naive single-scope rewrite surfaced 5 extra
 : tags that only exist on nested descendants): the original's tag *set*
 : came from a narrow scan of $hits' own direct members only
 : (lists:typedistvalues), while each tag's *content* came from a broader
 : scan that also reaches matching descendants of $hits members
 : (lists:typegroups) - so a nested title inside a matched div contributes
 : to an already-known tag's group, but never creates a new tag of its
 : own. $validTags enforces that boundary; distinct-values() per node
 : avoids double-counting a node that carries the same tag word in both
 : @type and @subtype.
 :
 : @param $hits the node sequence to group (title/div/seg/colophon/
 : incipit/explicit elements, or their ancestors' descendants of same)
 : @return a map from tag string to the matching node sequence
 :)
declare function lists:typeGroupsMap($hits) as map(*) {
	let $narrow := $hits[self::t:seg[ancestor::t:text][not(ancestor::t:bibl)] or
		self::t:incipit or
		self::t:explicit or
		self::t:colophon or
		self::t:title or
		self::t:div]
	(: matches lists:typedistvalues' original "prefer @subtype, else @type" rule exactly - not a union of both, unlike the broader per-tag content match below :)
	let $validTags := distinct-values(
		for $node in $narrow
		let $tagSource := ($node/@subtype, $node/@type)[1]
		return tokenize($tagSource, "\s+")[.]
	)
	let $broad := $hits//self::t:seg[ancestor::t:text][not(ancestor::t:bibl)] |
		$hits//self::t:incipit |
		$hits//self::t:explicit |
		$hits//self::t:colophon |
		$hits//self::t:title |
		$hits//self::t:div
	return map:merge(
		for $node in $broad
		for $tag in distinct-values((tokenize($node/@type, "\s+"), tokenize($node/@subtype, "\s+"))[.])[. = $validTags]
		group by $tag
		return map:entry($tag, $node)
	)
};

declare %templates:wrap function lists:titlesRes($node as node(), $model as map(*)) {
	let $groupsMap := if (exists($model("typeGroups"))) then
		$model("typeGroups")
	else
		lists:typeGroupsMap($model("hits"))

	for $i in map:keys($groupsMap)
	order by $i
	let $group := $groupsMap($i)
	return (
		<button class="w3-button w3-block w3-gray w3-padding w3-margin-bottom" onclick="openAccordion('{ $i }')">
			<span class="w3-badge w3-right">{ count($group) }</span>
			<span class="w3-left additionType" data-value="{ $i }">{ $i }</span>
		</button>,
		<div class="w3-container w3-hide" id="{ $i }">
			<div class="w3-container" id="{ $i }">
				{
					for $d at $p in $group
					let $tei := $d/ancestor::t:TEI
					let $msid := $tei/@xml:id

					(: group by containing ms :)
					group by $ms := $msid
					let $itemtype := distinct-values($tei/@type)[1]
					let $htmlid := concat(data($ms), "-", $i)
					order by $ms
					return (
						<button class="w3-button w3-block w3-red  w3-margin-bottom" onclick="openAccordion('{ $htmlid }')">
							<span class="w3-left">
								{
									if ($itemtype eq "mss") then
										$lists:collection-rootMS//id($ms)//t:msIdentifier/t:idno
									else
										try { exptit:printTitleID($ms) } catch * { util:log("WARNING", $ms) }
								}
							</span>
							<span class="w3-badge w3-right">{ count($d) }</span>
						</button>,
						<div class="w3-container w3-hide" id="{ $htmlid }">
							<ul class="w3-ul w3-hoverable">
								{
									if ($itemtype eq "mss") then
										for $sd in $d
										let $images := root($sd)//t:msIdentifier/t:idno
										let $locus := string($sd/t:locus/@facs)
										let $uid := if ($sd/@xml:id) then
											$sd/@xml:id
										else
											generate-id($sd)
										order by $uid
										return if (exists($sd/node())) then
											try {
												<li class="w3-container">
													{
														if ($images/@facs and $locus) then (
															<a href="/manuscripts/{ $ms }/viewer" target="_blank">
																<img
																	class="thumb"
																	src="{
																		if (starts-with($ms, "BML")) then
																			$config:appUrl ||
																				"/iiif/" ||
																				string($images/@facs) ||
																				$locus ||
																				".tif/full/150,/0/default.jpg"
																		else if (starts-with($ms, "ES")) then
																			$config:appUrl ||
																				"/iiif/" ||
																				string($images/@facs) ||
																				"_" ||
																				$locus ||
																				".tif/full/150,/0/default.jpg"
																		else if (starts-with($ms, "BNF")) then
																			replace($images/@facs, "ark:", "iiif/ark:") ||
																				"/" ||
																				$locus ||
																				"/full/150,/0/native.jpg"
																		else if (starts-with($ms, "BAV")) then
																			replace(substring-before($images/@facs, "/manifest.json"), "iiif", "pub/digit") ||
																				"/thumb/" ||
																				substring-before(substring-after($images/@facs, "MSS_"), "/manifest.json") ||
																				"_" ||
																				$locus ||
																				".tif.jpg"
																		else (
																		)
																	}"
																	style="width:10%" />
															</a>
														) else
															<div class="w3-third">No image found</div>
													}
													<div class="w3-third">
														{
															if (exists($sd/node())) then
																string:tei2string($sd/node())
															else
																"div"
														}
													</div>
													<div class="w3-third">
														<div class="w3-third">
															<a href="/{ $ms }">
																<b>{ $sd/name() }</b>
																{ " | " }
																{
																	if ($sd/@subtype) then
																		string($sd/@subtype)
																	else
																		string($sd/@type)
																}
															</a>
														</div>
														<div class="w3-third">Refers to {
																if ($sd/name() = "div" and $itemtype eq "work") then
																	<span>{ exptit:printTitle($ms) }</span>
																else if ($sd/name() = "div" and $itemtype eq "mss") then (
																	let $corr := $sd/@corresp
																	let $msitem := if (exists($corr)) then
																		$sd/ancestor::t:TEI//t:msItem[@xml:id = $corr]
																	else (
																	)
																	let $work := if (exists($msitem)) then
																		$msitem/t:title/@ref
																	else (
																	)
																	return if (exists($work)) then
																		<span>{ exptit:printTitle(string($work[1])) }</span>
																	else
																		<span class="w3-text-grey">[no work reference]</span>
																) else if (
																	$sd/name() = "colophon" or
																		$sd/name() = "incipit" or
																		$d/name() = "explicit" or
																		$sd/name() = "title"
																) then (
																	let $msitem := $sd/ancestor::t:msItem
																	let $work := $msitem/t:title/@ref
																	return <span>{ exptit:printTitle(string($work[1])) }</span>
																) else
																	"unable to retrieve reference"
															}
														</div>
														<div class="w3-third">
															<a href="{ data($ms) }#{ $uid }">{ data($uid) }</a>
															<br />
															{
																if (count($sd//t:ref[@type eq "authFile"]) ge 1) then
																	<span>Art themes: </span>
																else (
																),
																for $at in $sd//t:ref[@type eq "authFile"]
																return <a href="{ string($at/@corresp) }">
																	{ concat(string-join(exptit:printTitle($at/@corresp), " "), ", ") }
																</a>
															}
														</div>
													</div>
												</li>
											} catch * {
												util:log(
													"ERROR",
													concat(
														"Problematic node: ",
														$sd/name(),
														"(",
														$uid,
														") in TEI ",
														string($sd/ancestor::t:TEI/@xml:id),
														" for type ",
														$i,
														" || Error: ",
														$err:code,
														" ",
														$err:description
													)
												)
											}
										else (
										)
									else
										for $sd in $d
										return <li class="w3-container">
											<div class="w3-half">{ string:tei2string($sd/node()) }</div>
											<div class="w3-half">
												<div class="w3-third">
													<a href="/{ $ms }">
														<b>{ $sd/name() }</b>
														{ " | " }
														{
															if ($sd/@subtype) then
																string($sd/@subtype)
															else
																string($sd/@type)
														}
													</a>
												</div>
												<div class="w3-third">Refers to {
														if ($sd/name() = "div" and $itemtype eq "work") then (
															<a href="/{ $ms }"><span>{ $ms }</span></a>,
															<br />,
															<div class="w3-bar w3-gray w3-small">
																<a
																	class="w3-bar-item w3-button"
																	href="/titles?limit-work={ $ms }"
																>limit results to this work</a>
																<a class="w3-bar-item w3-button" href="/compare?workid={ $ms }">compare mss</a>
																<a class="w3-bar-item w3-button" href="/workmap?worksid={ $ms }">map mss</a>
																<a class="w3-bar-item w3-button" href="/litcomp?worksid={ $ms }">literature view</a>
															</div>
														) else if ($sd/name() = "div" and $itemtype eq "mss") then (
															let $corr := $sd/@corresp
															let $msitem := $sd/ancestor::t:TEI//t:msItem[@xml:id = $corr]
															let $work := $msitem/t:title/@ref
															return (
																<a href="{ string($work[1]) }"><span>{ exptit:printTitle(string($work[1])) }</span></a>,
																<br />,
																<div class="w3-bar w3-gray w3-small">
																	<a
																		class="w3-bar-item w3-button"
																		href="/titles?limit-work={ string($work[1]) }"
																	>limit results to this work</a>
																	<a
																		class="w3-bar-item w3-button"
																		href="/compare?workid={ string($work[1]) }"
																	>compare mss</a>
																	<a
																		class="w3-bar-item w3-button"
																		href="/workmap?worksid={ string($work[1]) }"
																	>map mss</a>
																	<a
																		class="w3-bar-item w3-button"
																		href="/litcomp?worksid={ string($work[1]) }"
																	>literature view</a>
																</div>
															)
														) else if (
															$sd/name() = "colophon" or
																$sd/name() = "incipit" or
																$d/name() = "explicit" or
																$sd/name() = "title"
														) then (
															let $msitem := $sd/ancestor::t:msItem
															let $work := $msitem/t:title/@ref
															return (
																<a href="{ string($work[1]) }"><span>{ exptit:printTitle(string($work[1])) }</span></a>,
																<br />,
																<div class="w3-bar w3-gray w3-small">
																	<a
																		class="w3-bar-item w3-button"
																		href="/titles?limit-work={ string($work[1]) }"
																	>limit results to this work</a>
																	<a
																		class="w3-bar-item w3-button"
																		href="/compare?workid={ string($work[1]) }"
																	>compare mss</a>
																	<a
																		class="w3-bar-item w3-button"
																		href="/workmap?worksid={ string($work[1]) }"
																	>map mss</a>
																	<a
																		class="w3-bar-item w3-button"
																		href="/litcomp?worksid={ string($work[1]) }"
																	>literature view</a>
																</div>
															)
														) else
															"unable to retrieve reference"
													}
												</div>
												<div class="w3-third">
													<a
														href="{ data($ms) }#{
															if ($sd/@xml:id) then
																concat("#", $sd/@xml:id)
															else (
															)
														}"
													>
														{
															if ($sd/@xml:id) then
																data($sd/@xml:id)
															else
																"[item]"
														}
													</a>
													<br />
													{
														if (count($sd//t:ref[@type eq "authFile"]) ge 1) then
															<span>Art themes: </span>
														else (
														),
														for $at in $sd//t:ref[@type eq "authFile"]
														return <a href="{ string($at/@corresp) }">
															{ concat(string-join(exptit:printTitle($at/@corresp), " "), ", ") }
														</a>
													}
												</div>
											</div>
										</li>
								}
							</ul>
						</div>
					)
				}
			</div>
		</div>
	)
};

declare function lists:corporaeditors($editor as node()*) {
	for $node in $editor
	return typeswitch ($node)
		case element(t:forename) return
			$node/text() || " "
		case element(t:surname) return
			$node/text()
		case element(t:resp) return
			<i>{ $node/text() }</i>
		case element() return
			lists:corporaeditors($node/node())

		default return
			$node
};

declare function lists:corpora($node as node(), $model as map(*)) {
	<div class="w3-responsive">
		<table class="w3-table w3-hoverable">
			<thead>
				<tr>
					<th>Title</th>
					<th>Primary editor</th>
					<th>Description</th>
					<th>Contents</th>
					<th>Statement of responsibilty</th>
				</tr>
			</thead>
			<tbody>
				{
					for $corpus in collection($config:bmdata-root || "/corpora")//*:TEI
					let $id := string($corpus/@xml:id)
					let $title := $corpus//t:titleStmt/t:title[1]/text()
					order by $title
					return <tr>
						<td><a href="/{ $id }/corpus"><h4>{ $title }</h4></a></td>
						<td>{ lists:corporaeditors($corpus//t:principal) }</td>
						<td>{ $corpus//t:projectDesc }</td>
						<td>
							<ul class="nodot">
								{
									for $document in $lists:collection-rootMS//t:relation[contains(@passive, $id)]
									let $rootid := substring-after(string($document/@active), ".eu/")
									let $mainid := if (contains($rootid, "#")) then
										substring-before($rootid, "#")
									else
										$rootid
									group by $ID := $mainid
									return for $textid in $rootid
										return <li class="nodot">
											<a href="/{ $textid }">{ substring-after($textid, "#") } in { $ID }</a>
										</li>
								}
							</ul>
						</td>
						<td>
							<ul class="nodot">
								{
									for $r in $corpus//t:respStmt
									return <li class="nodot">{ lists:corporaeditors($r/node()) }</li>
								}
							</ul>
						</td>
					</tr>
				}
			</tbody>
		</table>
	</div>
};
