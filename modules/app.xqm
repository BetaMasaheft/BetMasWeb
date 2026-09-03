xquery version "3.1" encoding "UTF-8";

(:~
 : module used by the app for string query, templating pages and general behaviours
 : mostly inherited from exist-db examples app but all largely modified
 :
 : @author Pietro Liuzzo
 :)
module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace xconf = "http://exist-db.org/collection-config/1.0";

import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace lib = "http://exist-db.org/xquery/html-templating/lib";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/coord" at "xmldb:exist:///db/apps/BetMasWeb/modules/coordinates.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace ann = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ann" at "xmldb:exist:///db/apps/BetMasWeb/modules/annotations.xqm";
import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace validation = "http://exist-db.org/xquery/validation";
import module namespace fusekisparql = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/sparqlfuseki" at "xmldb:exist:///db/apps/BetMasWeb/fuseki/fuseki.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace apptable = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apptable" at "xmldb:exist:///db/apps/BetMasWeb/modules/apptable.xqm";
import module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/queries" at "xmldb:exist:///db/apps/BetMasWeb/modules/queries.xqm";

(:~
 : declare variable $app:item-uri as xs:string := raequest:get-parameter('uri',());
 :)
declare variable $app:deleted := doc("/db/apps/lists/deleted.xml");

declare variable $app:collection := request:get-parameter("collection", ());

declare variable $app:name := request:get-parameter("name", ());

declare variable $app:params := request:get-parameter-names();

(:~
 : Resolves a facet function's own "context" parameter, calling
 : collection() directly for the common (unoverridden default) case
 : instead of util:eval - the parameter stays honored for any caller
 : that overrides it.
 :
 : Must call collection() fresh per invocation, not read a module-level
 : variable bound to it once: a persisted global reference to a large
 : collection() result held eXist document locks across requests via
 : compiled-query caching, hanging every as.html request. No range
 : index exists for the attributes these facets query
 : (https://github.com/BetaMasaheft/expanded/issues/19), so each call
 : still walks every document either way.
 :
 : @param $context the function's own context parameter (templates-resolved)
 : @return the evaluated context node sequence
 :)
declare %private function app:eval-mss-context($context as xs:string*) as node()* {
	if ($context = "collection($config:data-rootMS)") then
		collection($config:data-rootMS)
	else
		util:eval($context)
};

declare variable $app:rest := "/rest/";

declare variable $app:languages := doc("/db/apps/lists/languages.xml");

declare variable $app:range-lookup := (
	function-lookup(xs:QName("range:index-keys-for-field"), 4), function-lookup(xs:QName("range:index-keys-for-field"), 3)
)[1];

declare variable $app:util-index-lookup := (
	function-lookup(xs:QName("util:index-keys"), 5), function-lookup(xs:QName("util:index-keys"), 4)
)[1];

declare variable $app:search-title := "Search: ";

declare variable $app:searchphrase := request:get-parameter("query", ());

declare %private function functx:capitalize-first($arg as xs:string?) as xs:string? {
	concat(upper-case(substring($arg, 1, 1)), substring($arg, 2))
};

declare function app:interpretationSegments($node as node(), $model as map(*)) {
	for $d in config:distinct-values(collection($config:data-rootMS)//t:seg/@ana)
	return <option value="{ $d }">{ substring-after($d, "#") }</option>
};

(: get parallel diplomatique forms :)
declare function app:diplomatiqueforms($node as node(), $model as map(*), $interpret as xs:string*) {
	let $path := '$exptit:col//t:seg[@ana eq "' || $interpret || '"]'
	let $hits :=
		for $occurrence in util:eval($path)
		return $occurrence
	return map {"hits": $hits}
};

declare
	%templates:wrap %templates:default("start", 1) %templates:default("per-page", 10)
function app:diplomatiqueResults($node as node(), $model as map(*), $start as xs:integer, $per-page as xs:integer) {
	for $occurrence at $p in subsequence($model("hits"), $start, $per-page)
	let $text := normalize-space($occurrence/text())
	let $rootID := string(root($occurrence)/t:TEI/@xml:id)
	let $itemid := string($occurrence/ancestor::t:item/@xml:id)
	let $source := ($rootID || "#" || $itemid)
	let $stitle := $source
	return <div class="w3-row reference">
		<div class="w3-col"><span class="number">{ $start + $p - 1 }</span></div>
		<div class="w3-quarter">
			<a href="{ $config:appUrl }/{ $rootID }">{ exptit:printTitleID($rootID) }</a> ({ $rootID }#{ $itemid })</div>
		<div class="w3-rest">{ $text }</div>
	</div>
};

(:~
 : logging function to be called from templating pages
 :)
declare function app:logging($node as node(), $model as map(*)) {
	let $url := request:get-uri()

	let $paramstobelogged :=
		for $p in $app:params
		for $value in request:get-parameter($p, ())
		return ($p || "=" || $value)
	let $logparams := if (count($paramstobelogged) >= 1) then
		"?" || string-join($paramstobelogged, "&amp;")
	else (
	)
	let $url := $url || $logparams
	return log:add-log-message($url, sm:id()//sm:real/sm:username/string(), "page")
};

(:~
 : storing separately this input in this
 : function makes sure that when the page is
 : reloaded with the results the value entered remains in the input element
 :)
declare function app:queryinput($node as node(), $model as map(*), $query as xs:string*) {
	<input
		class="w3-input  w3-border diacritics"
		name="query"
		placeholder="type here the text you want to search"
		type="search"
		value="{ $query }" />
};

(: ~ calls the templates for static parts of the page so that different templates can use them. To make those usable also from restxq, they have to be called by templates like this, so nav.xql needs not the template module :)
declare function app:NbarNew($node as node()*, $model as map(*)) {
	nav:barNew()
};

declare function app:modalsNew($node as node()*, $model as map(*)) {
	nav:modalsNew()
};

declare function app:footerNew($node as node()*, $model as map(*)) {
	nav:footerNew()
};

(:~
 : the new issue button with a link to the github repo issues list
 :)
declare function app:newissue($node as node()*, $model as map(*)) {
	<a
		class="w3-button w3-small w3-gray"
		href="https://github.com/BetaMasaheft/Documentation/issues/new/choose"
		role="button"
		target="_blank"
	>new issue</a>
};

(:~
 : determins what the selectors for various form controls will look like, is called by app:formcontrol()
 :)
declare function app:selectors($nodeName, $path, $nodes, $type, $context) {
	<select class="w3-select w3-border" id="{ $nodeName }" multiple="multiple" name="{ $nodeName }">
		{
			if ($type = "keywords") then (
				for $group in $nodes/t:category[t:desc]
				let $label := $group/t:desc/text()
				let $rangeindexname := switch ($label)
					case "Occupation" return
						"occtype"
					case "Art Themes" return
						"refcorresp"
					case "Additiones" return
						"desctype"
					case "Place types" return
						"placetype"
					default return
						"termkey"
				return for $n in $group//t:catDesc
					let $id := $n/text()
					let $title := exptit:printTitleID($id)

					let $facet := try {
						$path/$app:range-lookup($rangeindexname, $id, function ($key, $count) { $count[2] }, 100)
					} catch * { ($err:code || $err:description) }
					let $fac := if ($facet[1] ge 1) then
						$facet[1]
					else
						"0"
					return <option value="{ $id }">{ ($title[1] || " (" || $fac || ")") }</option>
			) else if ($type = "name") then (
				for $n in $nodes[. != ""][. != " "]
				let $id := string($n/@xml:id)
				let $title := exptit:printTitleID($id)
				order by $id
				return <option value="{ $id }">{ $title }</option>
			) else if ($type = "rels") then (
				for $n in $nodes[. != ""][. != " "]
				let $title := exptit:printTitleID($n)
				order by $title[1]
				return <option value="{ $n }">{ normalize-space(string-join($title)) }</option>
			) else if ($type = "hierels") then (
				for $n in $nodes[. != ""][. != " "][not(starts-with(., "#"))]
				group by $work
						:=
							if (contains($n, "#")) then (
								substring-before($n, "#")
							) else
								$n
				order by $work
				return let $label := try {
						let $title := exptit:printTitleID($work)
						return if (string-length(string-join($title)) ge 1) then
							$title
						else
							$work
					} (: this has to stay because optgroup requires label and this cannot be computed from the javascript as in other places :) catch * {
						(
							"while trying to create a list for the filter " ||
								$nodeName ||
								" I got " ||
								$err:code ||
								": " ||
								$err:description ||
								" about " ||
								$work
						),
						$work
					}
					return if (count($n) = 1) then
						<option value="{ $work }">{ exptit:printTitleID($work) }</option>
					else (
						<optgroup label="{ $label }">
							{
								for $subid in $n
								return <option value="{ $subid }">
									{
										if (contains($subid, "#")) then
											substring-after($subid, "#")
										else
											"all"
									}
								</option>
							}
						</optgroup>
					)
			) else if ($type = "institutions") then (
				let $institutions := collection($config:data-rootIn)//t:TEI/@xml:id
				for $institutionId in $nodes[. eq $institutions]
				return <option value="{ $institutionId }">{ exptit:printTitleID($institutionId) }</option>
			) else if ($type = "sex") then (
				for $n in $nodes[. != ""][. != " "]
				let $key := replace(functx:trim($n), "_", " ")
				order by $n
				return <option value="{ string($key) }">
					{
						switch ($key)
							case "1" return
								"Male"
							default return
								"Female"
					}
				</option>
			) else (
				(: type is values :)
				for $n in $nodes[. != ""][. != " "]
				let $thiskey := replace(functx:trim($n), "_", " ")
				let $title := if (
					$nodeName = "keyword" or $nodeName = "placetype" or $nodeName = "country" or $nodeName = "settlement"
				) then
					exptit:printTitleID($thiskey)
				else if ($nodeName = "language") then
					$app:languages//t:item[@xml:id eq $thiskey]/text()
				else
					$thiskey
				let $rangeindexname := switch ($nodeName)
					case "relType" return
						"relname"
					case "language" return
						"TEIlanguageIdent"
					case "material" return
						"materialkey"
					case "bmaterial" return
						"materialkey"
					case "bindingtype" return
						"bindingtype"
					case "placetype" return
						"placetype"
					case "country" return
						"countryref"
					case "settlement" return
						"settlref"
					case "occupation" return
						"occtype"
					case "faith" return
						"faithtype"
					case "objectType" return
						"form"
					default return
						"termkey"
				let $ctx := app:eval-mss-context($context)
				let $facet := if ($nodeName = "script") then (
					$app:util-index-lookup(
						$ctx//@script,
						lower-case($thiskey),
						function ($key, $count) { $count[2] },
						100,
						"lucene-index"
					)
				) else (
					$ctx/$app:range-lookup($rangeindexname, $thiskey, function ($key, $count) { $count[2] }, 100)
				)
				order by $n
				return <option value="{ $thiskey }">
					{
						if ($thiskey = "Printedbook") then
							"Printed Book"
						else
							$title
					}
					{ (" (" || $facet[1] || ")") }
				</option>
			)
		}
	</select>
};

(:~
 : builds the form control according to the data specification and is called by all
 : the functions building the search form. these are in turn called by a html div called by a javascript function.
 : retold from user perspective the initial form in as.html uses the controller template model with the template search.html, which calls
 : a javascirpt filters.js which on click loads with AJAX the selected form*.html file.
 : Each of these contains a call to a function app:NAMEofTHEform which will call app:formcontrol which will call app:selectors
 :)
declare function app:formcontrol($nodeName as xs:string, $path, $group, $type, $context) {
	if ($group = "true") then (
		let $values :=
			for $i in $path
			return if (contains($i, " ")) then
				tokenize($i, " ")
			else if ($i = " " or $i = "") then (
			) else
				functx:trim(normalize-space($i))
		let $nodes := config:distinct-values($values)
		return <div class="w3-container">
			<label for="{ $nodeName }">
				{ $nodeName }s <span class="w3-badge">{ count($nodes[. != ""][. != " "]) }</span>
			</label>
			{ app:selectors($nodeName, $path, $nodes, $type, $context) }
		</div>
	) else (
		let $nodes :=
			for $node in $path
			return $node
		return app:selectors($nodeName, $path, $nodes, $type, $context)
	)
};

(:~
 : the filters available in the search results view used by search.html
 :)
declare function app:searchFilter($node as node()*, $model as map(*)) {
	let $items-info := $model("hits")
	let $q := $model("q")
	let $cont := $model("query")
	return <form action="" class="w3-container">
		{
			app:formcontrol("language", $items-info//@xml:lang, "true", "values", $cont),
			app:formcontrol("keyword", $items-info//t:term/@key, "true", "titles", $cont),
			<label for="dates">date range</label>,
			<input
				class="span2"
				data-slider-max="2000"
				data-slider-min="0"
				data-slider-step="10"
				data-slider-value="[0,2000]"
				id="dates"
				name="dateRange"
				type="text" />,
			<script type="text/javascript">{ "$('#dates').bootstrapSlider({});" }</script>,
			<input name="query" type="hidden" value="{ $q }" />
		}
		<div class="w3-bar">
			<button class="w3-button w3-red w3-bar-item" type="submit"> Filter
                    </button>
			<a class="w3-button w3-gray w3-bar-item" href="{ $config:appUrl }/as.html" role="button">Advanced Search Form</a>
		</div>
	</form>
};

(:~
 : query parameters and corresponding filtering of the xpath context for ft:query
 : returns xpath as string to be later evaluated
 :)
declare function app:ListQueryParam($parameter, $context, $mode, $function) {
	if (exists($app:params)) then (
		let $allparamvalues := if ($parameter = $app:params) then (
			request:get-parameter($parameter, ())
		) else
			"all"
		return if ($allparamvalues = "all") then (
		) else (
			if ($parameter = "xmlid") then (
				if ($allparamvalues = "") then (
				) else if ($allparamvalues != "all") then
					"[contains(@xml:id, '" || $allparamvalues || "')]"
				else (
				)
			) else
				let $keys := if ($parameter = "keyword") then (
					for $k in $allparamvalues
					let $ks := doc($config:data-rootA || "/taxonomy.xml")//t:catDesc[text() eq
						$k]/following-sibling::t:*/t:catDesc/text()
					let $nestedCats :=
						for $n in $ks
						return $n
					return if ($nestedCats >= 2) then (
						replace($k, "#", " ") || " OR " || string-join($nestedCats, " OR ")
					) else (
						replace($k, "#", " ")
					)
				) else (
					for $k in $allparamvalues
					return replace($k, "#", " ")
				)
				return if ($function = "list") then
					"[ft:query(" || $context || ", '" || string-join($keys, " ") || "')]"
				else
					let $limit :=
						for $k in $allparamvalues
						return if ($parameter = "author") then
							"descendant::" ||
								$context ||
								"='" ||
								$k ||
								"' or  descendant::t:relation[@name eq 'dcterms:creator']/@passive eq '" ||
								$k ||
								"'"
						else if ($parameter = "tabot") then
							"descendant::t:ab[@type eq 'tabot'][descendant::t:persName[contains(@ref, '" ||
								$k ||
								"')] or descendant::t:ref[contains(@corresp, '" ||
								$k ||
								"')]]"
						else if ($parameter = "target-ins") then
							(:
							 : app:target-ins's own picker submits the bare institution
							 : id (its <option>s come from $config:data-rootIn's
							 : @xml:id), but t:repository/@ref in the manuscripts
							 : collection stores the full $config:BMurl-prefixed URI -
							 : an exact `=` match here (this branch's own default,
							 : below) never matched anything, silently no-op'ing every
							 : institution-filtered search. ends-with (rather than
							 : contains) keeps the match anchored to the id's own path
							 : segment, not any arbitrary substring of the URI.
							 :)
							"descendant::t:repository[ends-with(@ref, '/" || $k || "')]"
						else
							let $c := if (starts-with($context, "@")) then (
							) else
								"descendant::"
							return $c || $context || "='" || replace($k, " ", "_") || "' "

					return "[" || string-join($limit, " or ") || "]"
		)
	) else (
	)
};

(:~
 : on login, print the name of the logged user
 :)
declare function app:greetings-rest() {
	<a href="">Hi { sm:id()//sm:username/text() }!</a>
};

(: on login, print the name of the logged user :)
declare function app:greetings($node as element(), $model as map(*)) as xs:string {
	<a href="">Hi { sm:id()//sm:username/text() }!</a>
};

declare function app:logout() {
	session:invalidate()
};

(:~
 : general count of contributions to the data
 :)
declare function app:team($node as node(), $model as map(*)) {
	<ul class="w3-ul w3-hoverable w3-padding">
		{
			$exptit:col/$app:range-lookup(
				"changewho",
				(),
				function ($key, $count) {
					let $k := distinct-values(
						if (contains($key, "#")) then
							substring-after($key, "#")
						else
							$key
					)
					return <li id="{ $key }">
						{
							editors:editorKey(replace($key, "#", "")) ||
								" (" ||
								$key ||
								")" ||
								" made " ||
								$count[1] ||
								" changes in " ||
								$count[2] ||
								" documents. "
						}
						<a
							href="/xpath?xpath=%24config%3Acollection-root%2F%2Ft%3Achange%5Bmatches%28%40who%2C+%27{ $k }%27%29%5D"
						>See the changes.</a>
					</li>
				},
				1000
			)
		}
	</ul>
};

(:~
 : general count of contributions to the data
 :)
declare function app:deleted($node as node(), $model as map(*)) {
	<ul class="w3-ul w3-hoverable w3-padding">
		{
			for $deleted in $app:deleted//t:item[normalize-space()]
			order by $deleted
			let $coll := switch2:col(switch2:switchPrefix($deleted))
			return <li
				class="w3-display-container"
				data-id="{ $deleted }"
				data-path="{ functx:capitalize-first(string($deleted/@source)) }/{ $deleted }.xml"
				data-type="{ functx:capitalize-first($coll) }"
				id="permanentIDs{ $deleted }"
			>
				{ $deleted/text() }, deleted from { string($deleted/@source) } on { string($deleted/@change) }.
    {
					let $formerly := $exptit:col//t:relation[@name eq "betmas:formerlyAlsoListedAs"][@passive eq $deleted/text()]
					let $same := $exptit:col//t:relation[@name eq "skos:exactMatch"][@passive eq $deleted/text()]
					return (
						if ($formerly) then
							<p>This record is now listed as { string-join($formerly/@active, ", ") }.</p>
						else (
						),
						if ($same) then
							for $s in $same
							return <p>This record is the same as <a href="{ $config:appUrl }/{ string($s/@active) }" target="_blank">
									{ exptit:printTitleID($s/@active) }
								</a>.</p>
						else (
						)
					)
				}
				<a class="w3-btn w3-gray w3-display-right" id="LoadPermanentIDs{ $deleted }">Permalinks</a>
			</li>
		}
	</ul>,
	<script src="resources/js/permanentID.js" type="text/javascript" />
};

declare function app:oldids($node as node(), $model as map(*)) {
	<ul class="w3-ul w3-hoverable w3-padding">
		{
			let $formerly := $exptit:col//t:relation[@name eq "betmas:formerlyAlsoListedAs"]/@passive
			for $deleted in $formerly
			let $now := string-join($deleted/ancestor::t:relation[@passive eq $deleted]/@active, ", ")
			order by $deleted
			return <li class="w3-display-container">
				{ substring-after($deleted, "eu/") } is now listed as <a href="{ $config:appUrl }/{ $now }">
					{ substring-after($now, "eu/") }
				</a>.
    </li>
		}
	</ul>
};

declare function functx:value-intersect($arg1 as xs:anyAtomicType*, $arg2 as xs:anyAtomicType*) as xs:anyAtomicType* {
	config:distinct-values($arg1[. eq $arg2])
};

declare function functx:trim($arg as xs:string?) as xs:string {
	replace(replace($arg, "\s+$", ""), "^\s+", "")
};

declare function functx:contains-any-of($arg as xs:string?, $searchStrings as xs:string*) as xs:boolean {
	some $searchString in $searchStrings satisfies contains($arg, $searchString)
};

(: modified by applying functx:escape-for-regex() :)
declare function functx:number-of-matches($arg as xs:string?, $pattern as xs:string) as xs:integer {
	count(tokenize(functx:escape-for-regex(functx:escape-for-regex($arg)), functx:escape-for-regex($pattern))) - 1
};

declare function functx:escape-for-regex($arg as xs:string?) as xs:string {
	replace($arg, "(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))", "\\$1")
};

(:~
 : ADVANCED SEARCH FUNCTIONS the list of searchable and indexed elements
 :)
declare function app:elements($node as node(), $model as map(*)) {
	let $control := <select
		xmlns="http://www.w3.org/1999/xhtml"
		class="w3-select w3-border"
		id="element"
		multiple="multiple"
		name="element"
	>
		<option value="title">Titles</option>
		<option value="persName">Person names</option>
		<option value="placeName">Place names</option>
		<option value="ref">References</option>
		<option value="ab">Texts</option>
		<option value="l">Lines</option>
		<option value="p">Paragraphs</option>
		<option value="note">Notes</option>
		<option value="incipit">Incipits</option>
		<option value="explicit">Explicits</option>
		<option value="colophon">Colophons</option>
		<option value="q">Quotes</option>
		<option value="occupation">Occupation</option>
		<option value="roleName">Role</option>
		<option value="summary">Summaries</option>
		<option value="abstract">Abstracts</option>
		<option value="desc">Descriptions</option>
		<option value="relation">Relations</option>
		<option value="foliation">Foliation</option>
		<option value="origDate">Origin Dates</option>
		<option value="measure">Measures</option>
		<option value="floruit">Floruit</option>
	</select>
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and
 : filters.js. Scoped to a single institution's manuscripts when
 : target-ins is submitted, matching filters.js's live cascade on
 : #target-ins - previously that cascade rebuilt this same
 : id="target-ms"/name="target-ms" select from scratch client-side via
 : a separate AJAX call instead of scoping this one, which collided
 : with it under the same ids whenever both were present.
 :
 : Without target-ins, renders no options rather than falling through
 : to the full ~20,000-manuscript corpus - forminstitutions.html is
 : always included on every as.html load, so an unscoped fallback here
 : ran app:selectors' per-option exptit:printTitleID lookup ~20,000
 : times on every page load, unconditionally. Measured:
 : several minutes per request against the real corpus, severe enough
 : to starve concurrent requests waiting on the same title-lookup
 : locks. A flat, unscoped 20,000-option dropdown was never usable UI
 : either way. target-ms alone (no target-ins) still needs its
 : currently-selected manuscript(s) present so they render `selected`.
 :
 : @param $target-ins the request's target-ins parameter, auto-resolved by name
 : @param $target-ms the request's target-ms parameter, auto-resolved by name
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:target-mss(
	$node as node(),
	$model as map(*),
	$context as xs:string*,
	$target-ins as xs:string*,
	$target-ms as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $scoped := if (app:list-param-active($target-ins)) then
		(:
		 : t:repository/@ref is BMurl-prefixed; target-ins submits the
		 : bare id. Multi-select, so match any one value - `||`
		 : concatenating the whole sequence throws err:XPTY0004.
		 :)
		$cont//t:TEI[descendant::t:repository[some $ins in $target-ins satisfies ends-with(@ref, "/" || $ins)]]
	else if (app:list-param-active($target-ms)) then
		$cont//t:TEI[some $ms in $target-ms satisfies @xml:id eq $ms]
	else (
	)
	let $control := app:formcontrol("target-ms", $scoped, "false", "name", $context)

	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootW, $config:data-rootN)") function app:target-works(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := util:eval($context)
	let $control := app:formcontrol("target-work", $cont//t:TEI, "false", "name", $context)

	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootIn)") function app:target-ins(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := util:eval($context)
	let $control := app:formcontrol("target-ins", $cont//t:TEI, "false", "name", $context)

	return templates:form-control($control, $model)
};

(:~
 : Echoes the "institutions" checkbox's state from the request - active
 : whether the user picked an institution (target-ins) or, once that
 : cascade rendered its scoped manuscripts select, one or more specific
 : manuscripts from it (target-ms). Covers the same ground the
 : never-wired "msstargets" facet (formtargetmss.html, its own dead
 : checkbox-less filters.js case) was meant to - folded in here rather
 : than restored separately, since target-mss's own manuscripts select
 : is now part of this same fragment.
 :
 : @param $target-ins the request's target-ins parameter, auto-resolved by name
 : @param $target-ms the request's target-ms parameter, auto-resolved by name
 : @return the checkbox, with @checked set when either is present
 :)
declare function app:institutionsCheckbox(
	$node as node(),
	$model as map(*),
	$target-ins as xs:string*,
	$target-ms as xs:string*
) as element() {
	app:checkbox-state($node, app:list-param-active($target-ins) or app:list-param-active($target-ms))
};

(:~
 : Server-side include of forminstitutions.html's own templated content
 : - see app:includeFoliaForm for the pattern this follows.
 :
 : @param $target-ins the request's target-ins parameter, auto-resolved by name
 : @param $target-ms the request's target-ms parameter, auto-resolved by name
 : @return forminstitutions.html's own root element, hidden when neither is present
 :)
declare function app:includeInstitutionsForm(
	$node as node(),
	$model as map(*),
	$target-ins as xs:string*,
	$target-ms as xs:string*
) as element()? {
	app:include-facet-form(
		$node,
		$model,
		"forms/forminstitutions.html",
		app:list-param-active($target-ins) or app:list-param-active($target-ms)
	)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js MANUSCRIPTS FILTERS for CONTEXT
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:scripts(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $scripts := $app:util-index-lookup($cont//@script, (), function ($key, $count) { $key }, 100, "lucene-index")
	let $control := app:formcontrol("script", $scripts, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:support(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $forms := config:distinct-values($cont//@form)
	let $control := app:formcontrol("support", $forms, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:material(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $materials := config:distinct-values($cont//t:support/t:material/@key)
	let $control := app:formcontrol("material", $materials, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:bmaterial(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $bmaterials := config:distinct-values($cont//t:decoNote[@type eq "bindingMaterial"]/t:material/@key)

	let $control := app:formcontrol("bmaterial", $bmaterials, "false", "values", $context)
	return templates:form-control($control, $model)
};

declare %templates:default("context", "collection($config:data-rootMS)") function app:bindingtype(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $bindings := config:distinct-values($cont//t:binding/@contemporary)
	let $control := app:formcontrol("bindingtype", $bindings, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js PLACES FILTERS for CONTEXT
 :)
declare %templates:default("context", "collection($config:data-rootPl,$config:data-rootIn)") function app:placeType(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := util:eval($context)
	let $placeTypes := config:distinct-values($cont//t:place/@type/tokenize(., "\s+"))
	let $control := app:formcontrol("placeType", $placeTypes, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootPr)") function app:personType(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := util:eval($context)
	let $persTypes := config:distinct-values($cont//t:person//t:occupation/@type/tokenize(., "\s+"))
	let $control := app:formcontrol("persType", $persTypes, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "$exptit:col") function app:relationType(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := util:eval($context)
	let $relTypes := config:distinct-values($cont//t:relation/@name/tokenize(., "\s+"))
	let $control := app:formcontrol("relType", $relTypes, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : Written-lines range slider for forms/formWL.html. Bounds computed
 : from the real corpus (q:max-written-lines) instead of a hand-maintained
 : literal, so the widget's max and the "no filter applied" default
 : value (checked in q:par-wL/list:paramsList) can never drift apart -
 : see q:max-written-lines's own doc for why that drift was a real bug,
 : not just cosmetic.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $wL the request's wL parameter, auto-resolved by name - a
 : "min,max" pair, echoed back as the slider's initial position instead
 : of always resetting to the full range (a real bug: the filter *was*
 : already applied server-side on reload, the widget just silently
 : failed to show that)
 : @return the <input> element for the bootstrap-slider widget, with real min/max/value
 :)
declare function app:writtenLinesInput($node as node(), $model as map(*), $wL as xs:string*) as element(input) {
	let $max := q:max-written-lines()
	let $range := if (exists($wL) and $wL[1] != "") then
		$wL[1]
	else
		"1," || $max
	return <input
		class="span2"
		data-slider-max="{ $max }"
		data-slider-min="1"
		data-slider-step="1"
		data-slider-value="[{ substring-before($range, ",") },{ substring-after($range, ",") }]"
		id="writtenLines"
		name="wL"
		type="text" />
};

(:~
 : Leaf-count range slider for forms/formfolia.html. Bounds computed
 : from the real corpus (q:max-folia) instead of a hand-maintained
 : literal - see q:max-folia's own doc for the EMML5533 data-quality
 : issue its exclusion works around.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $folia the request's folia parameter, auto-resolved by name -
 : a "min,max" pair, echoed back as the slider's initial position
 : instead of always resetting to the full range (a real bug: the
 : filter *was* already applied server-side on reload, the widget just
 : silently failed to show that)
 : @return the <input> element for the bootstrap-slider widget, with real min/max/value
 :)
declare function app:foliaInput($node as node(), $model as map(*), $folia as xs:string*) as element(input) {
	let $max := q:max-folia()
	let $range := if (exists($folia) and $folia[1] != "") then
		$folia[1]
	else
		"1," || $max
	return <input
		class="span2"
		data-slider-max="{ $max }"
		data-slider-min="1"
		data-slider-step="1"
		data-slider-value="[{ substring-before($range, ",") },{ substring-after($range, ",") }]"
		id="folia"
		name="folia"
		type="text" />
};

(:~
 : Whether `folia` carries a real, non-default filter value - the same
 : sentinel q:par-folia uses to decide "no filter applied", shared by
 : every folia-facet templated function below so they can't drift
 : apart from each other or from q:par-folia itself.
 :
 : @param $folia the request's folia parameter
 : @return true if a non-default "min,max" range is present
 :)
declare %private function app:folia-active($folia as xs:string*) as xs:boolean {
	exists($folia) and $folia[1] != "" and $folia[1] != ("1," || q:max-folia())
};

(:~
 : Whether `wL` carries a real, non-default filter value - see
 : app:folia-active, same reasoning for q:par-wL's sentinel.
 :
 : @param $wL the request's wL parameter
 : @return true if a non-default "min,max" range is present
 :)
declare %private function app:wL-active($wL as xs:string*) as xs:boolean {
	exists($wL) and $wL[1] != "" and $wL[1] != ("1," || q:max-written-lines())
};

(:~
 : Echoes the "folia" checkbox's state from the request.
 :
 : @param $folia the request's folia parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a non-default range is active
 :)
declare function app:foliaCheckbox($node as node(), $model as map(*), $folia as xs:string*) as element() {
	app:checkbox-state($node, app:folia-active($folia))
};

(:~
 : Echoes the "writtenLines" checkbox's state from the request.
 :
 : @param $wL the request's wL parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a non-default range is active
 :)
declare function app:writtenLinesCheckbox($node as node(), $model as map(*), $wL as xs:string*) as element() {
	app:checkbox-state($node, app:wL-active($wL))
};

(:~
 : Whether `qn` carries a real, non-default filter value - see
 : app:folia-active, same reasoning for q:par-qn's sentinel.
 :
 : @param $qn the request's qn parameter
 : @return true if a non-default "min,max" range is present
 :)
declare %private function app:qn-active($qn as xs:string*) as xs:boolean {
	exists($qn) and $qn[1] != "" and $qn[1] != "1,100"
};

(:~
 : Whether `qcn` carries a real, non-default filter value - see
 : app:folia-active, same reasoning for q:par-qcn's sentinel.
 :
 : @param $qcn the request's qcn parameter
 : @return true if a non-default "min,max" range is present
 :)
declare %private function app:qcn-active($qcn as xs:string*) as xs:boolean {
	exists($qcn) and $qcn[1] != "" and $qcn[1] != "1,40"
};

(:~
 : Whether `numberOfParts` carries a real filter value - see
 : app:gender-active, same "non-empty is active" reasoning (the
 : dispatcher that reaches q:par's "numberOfParts" case already
 : filters out blank values before it's ever called).
 :
 : @param $numberOfParts the request's numberOfParts parameter
 : @return true if a value is present
 :)
declare %private function app:cuNumber-active($numberOfParts as xs:string*) as xs:boolean {
	exists($numberOfParts) and $numberOfParts[1] != ""
};

(:~
 : Reveals the "Manuscripts Filters" section server-side when one of
 : its facets has an active, non-default request parameter, instead of
 : relying on filters.js's `#collectionfilter` change handler alone
 : (JS-only, lost on reload).
 :
 : Reads every facet's request parameter directly via
 : request:get-parameter rather than taking one auto-resolved parameter
 : per facet, unlike every other *FiltersSection function in this
 : module. That's not a stylistic choice: this section covers by far
 : the most facets (26, after the `dimensions` slice's nine fields),
 : and templates:call's introspection-based dispatch - the mechanism
 : that auto-resolves a templated function's parameters by name -
 : refuses to look up any function past 20 total parameters
 : (`$templates:MAX_ARITY` in the vendored templating package), throwing
 : `templates:NotFound` at request time. Found live-testing the
 : `dimensions` facet: the previous 28-parameter version passed all of
 : its own direct-call XQSuite tests (which bypass templates:call
 : entirely) while being permanently broken on the real page. Reading
 : parameters directly sidesteps the cap - this function is a
 : `data-template` target on `#manuscriptsFilters` itself, so it's
 : still reached by templates:call, but at its own arity of 2 rather
 : than 28. Extend the OR-condition below as more `#mssFilter` facets
 : get the same treatment; no signature change is ever needed again.
 :
 : @return the section, with its `display:none` dropped when active
 :)
declare function app:manuscriptsFiltersSection($node as node(), $model as map(*)) as element() {
	element {node-name($node)} {
		templates:filter-attributes($node, $model) except $node/@style,
		if (
			app:folia-active(request:get-parameter("folia", ())) or
				app:wL-active(request:get-parameter("wL", ())) or
				app:qn-active(request:get-parameter("qn", ())) or
				app:qcn-active(request:get-parameter("qcn", ())) or
				app:cuNumber-active(request:get-parameter("numberOfParts", ())) or
				app:gender-active(request:get-parameter("gender", ())) or
				app:list-param-active(request:get-parameter("scribe", ())) or
				app:list-param-active(request:get-parameter("donor", ())) or
				app:list-param-active(request:get-parameter("patron", ())) or
				app:list-param-active(request:get-parameter("owner", ())) or
				app:list-param-active(request:get-parameter("binder", ())) or
				app:list-param-active(request:get-parameter("support", ())) or
				app:list-param-active(request:get-parameter("content", ())) or
				app:list-param-active(request:get-parameter("bindingtype", ())) or
				app:list-param-active(request:get-parameter("script", ())) or
				app:list-param-active(request:get-parameter("parchmentMaker", ())) or
				app:list-param-active(request:get-parameter("material", ())) or
				app:list-param-active(request:get-parameter("bmaterial", ())) or
				app:list-param-active(request:get-parameter("target-ins", ())) or
				app:list-param-active(request:get-parameter("target-ms", ())) or
				app:dimensions-active(
					request:get-parameter("height", ()),
					request:get-parameter("width", ()),
					request:get-parameter("depth", ()),
					request:get-parameter("columnsNum", ()),
					request:get-parameter("tmargin", ()),
					request:get-parameter("bmargin", ()),
					request:get-parameter("rmargin", ()),
					request:get-parameter("lmargin", ()),
					request:get-parameter("intercolumn", ())
				)
		) then (
		) else
			$node/@style,
		$node/node()!templates:process(., $model)
	}
};

(:~
 : Echoes the "CUnumber" checkbox's state from the request.
 :
 : @param $numberOfParts the request's numberOfParts parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is present
 :)
declare function app:CUnumberCheckbox($node as node(), $model as map(*), $numberOfParts as xs:string*) as element() {
	app:checkbox-state($node, app:cuNumber-active($numberOfParts))
};

(:~
 : Server-side include of formCUnumber.html's own templated content -
 : see app:includeFoliaForm for the pattern this follows. No JS widget
 : involved (formCUnumber.html's own field is a plain
 : templates:form-control target), so no hidden-init concern here.
 :
 : @param $numberOfParts the request's numberOfParts parameter, auto-resolved by name
 : @return formCUnumber.html's own root element, hidden when no filter is active
 :)
declare function app:includeCUnumberForm(
	$node as node(),
	$model as map(*),
	$numberOfParts as xs:string*
) as element()? {
	app:include-facet-form($node, $model, "forms/formCUnumber.html", app:cuNumber-active($numberOfParts))
};

(:~
 : Whether a list-style filter param is active - shared by every
 : facet below whose query predicate (app:query/app:ListQueryParam) is
 : simply "any non-empty value selected", with no default-range
 : sentinel to match against (see app:gender-active/app:cuNumber-active
 : for the same reasoning, kept separate there since they predate this
 : helper and are already shipped).
 :
 : @param $value a request parameter's resolved value(s)
 : @return true if a non-empty value is present
 :)
declare %private function app:list-param-active($value as xs:string*) as xs:boolean {
	exists($value) and $value[1] != ""
};

(:~
 : Shared shape behind every "echo this facet's checkbox state" function:
 : copy $node's attributes except @data-template/@checked, then set
 : @checked when the caller's own activity check says so. Each facet
 : keeps its own activity predicate (app:list-param-active,
 : app:folia-active, a multi-param "or", etc.) - only this boilerplate
 : is shared.
 :
 : @param $node the checkbox's data-template marker node
 : @param $active whether this facet has a real filter value
 : @return the checkbox, with @checked set when $active
 :)
(:~
 : Shared shape behind every "server-render this facet's form fragment
 : when it has state to restore" function: include the form file only
 : when the caller's own activity check says there's something to
 : restore. Each facet keeps its own activity predicate - only this
 : include boilerplate is shared.
 :
 : Renders nothing at all when inactive, rather than including the
 : fragment and hiding it via @style - lib:include runs the facet's own
 : list-building function (e.g. a full corpus scan with a title lookup
 : per option), which every one of these ~30 facets otherwise paid on
 : every single as.html load regardless of whether that facet was ever
 : opened. filters.js's own callformpart already handles the resulting
 : gap correctly with no change needed there: it AJAX-fetches a form
 : fragment on first checkbox click exactly when the fragment's root id
 : isn't already present in the DOM, forwarding the page's own query
 : string so a fragment fetched this way still echoes any submitted
 : value.
 :
 : @param $node the data-template marker node
 : @param $model the current templates model
 : @param $formfile the form fragment's path, e.g. "forms/formscribes.html"
 : @param $active whether this facet has a real filter value
 : @return the form fragment when $active, otherwise nothing
 :)
declare %private function app:include-facet-form(
	$node as node(),
	$model as map(*),
	$formfile as xs:string,
	$active as xs:boolean
) as element()? {
	if ($active) then
		lib:include($node, $model, $formfile)
	else (
	)
};

declare %private function app:checkbox-state($node as node(), $active as xs:boolean) as element() {
	element {node-name($node)} {
		$node/@* except ($node/@data-template, $node/@checked),
		if ($active) then
			attribute checked { "checked" }
		else (
		)
	}
};

(:~
 : Echoes the "scribe" checkbox's state from the request.
 :
 : @param $scribe the request's scribe parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:scribeCheckbox($node as node(), $model as map(*), $scribe as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($scribe))
};

(:~
 : Server-side include of formscribes.html's own templated content -
 : see app:includeFoliaForm for the pattern this follows.
 :
 : @param $scribe the request's scribe parameter, auto-resolved by name
 : @return formscribes.html's own root element, hidden when no filter is active
 :)
declare function app:includeScribeForm($node as node(), $model as map(*), $scribe as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formscribes.html", app:list-param-active($scribe))
};

(:~
 : Echoes the "donor" checkbox's state from the request.
 :
 : @param $donor the request's donor parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:donorCheckbox($node as node(), $model as map(*), $donor as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($donor))
};

(:~
 : Server-side include of formdonor.html's own templated content.
 :
 : @param $donor the request's donor parameter, auto-resolved by name
 : @return formdonor.html's own root element, hidden when no filter is active
 :)
declare function app:includeDonorForm($node as node(), $model as map(*), $donor as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formdonor.html", app:list-param-active($donor))
};

(:~
 : Echoes the "patron" checkbox's state from the request.
 :
 : @param $patron the request's patron parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:patronCheckbox($node as node(), $model as map(*), $patron as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($patron))
};

(:~
 : Server-side include of formpatron.html's own templated content.
 :
 : @param $patron the request's patron parameter, auto-resolved by name
 : @return formpatron.html's own root element, hidden when no filter is active
 :)
declare function app:includePatronForm($node as node(), $model as map(*), $patron as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formpatron.html", app:list-param-active($patron))
};

(:~
 : Echoes the "owner" checkbox's state from the request.
 :
 : @param $owner the request's owner parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:ownerCheckbox($node as node(), $model as map(*), $owner as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($owner))
};

(:~
 : Server-side include of formowner.html's own templated content.
 :
 : @param $owner the request's owner parameter, auto-resolved by name
 : @return formowner.html's own root element, hidden when no filter is active
 :)
declare function app:includeOwnerForm($node as node(), $model as map(*), $owner as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formowner.html", app:list-param-active($owner))
};

(:~
 : Echoes the "binder" checkbox's state from the request.
 :
 : @param $binder the request's binder parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:binderCheckbox($node as node(), $model as map(*), $binder as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($binder))
};

(:~
 : Server-side include of formbinder.html's own templated content.
 :
 : @param $binder the request's binder parameter, auto-resolved by name
 : @return formbinder.html's own root element, hidden when no filter is active
 :)
declare function app:includeBinderForm($node as node(), $model as map(*), $binder as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formbinder.html", app:list-param-active($binder))
};

(:~
 : Echoes the "objectType" checkbox's state from the request - the
 : checkbox's own value differs from the actual request parameter it
 : gates (`support`, see app:support), matching as.html's own label
 : ("support") for this facet.
 :
 : @param $support the request's support parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:objectTypeCheckbox($node as node(), $model as map(*), $support as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($support))
};

(:~
 : Server-side include of formobjecttype.html's own templated content.
 :
 : @param $support the request's support parameter, auto-resolved by name
 : @return formobjecttype.html's own root element, hidden when no filter is active
 :)
declare function app:includeObjectTypeForm($node as node(), $model as map(*), $support as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formobjecttype.html", app:list-param-active($support))
};

(:~
 : Echoes the "contents" checkbox's state from the request - the
 : checkbox's own value ("contents") differs from the actual request
 : parameter it gates (`content`, see app:contents).
 :
 : @param $content the request's content parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:contentsCheckbox($node as node(), $model as map(*), $content as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($content))
};

(:~
 : Server-side include of formcontents.html's own templated content.
 :
 : @param $content the request's content parameter, auto-resolved by name
 : @return formcontents.html's own root element, hidden when no filter is active
 :)
declare function app:includeContentsForm($node as node(), $model as map(*), $content as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formcontents.html", app:list-param-active($content))
};

(:~
 : Echoes the "bindingtype" checkbox's state from the request.
 :
 : @param $bindingtype the request's bindingtype parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:bindingtypeCheckbox($node as node(), $model as map(*), $bindingtype as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($bindingtype))
};

(:~
 : Server-side include of formbind.html's own templated content.
 :
 : @param $bindingtype the request's bindingtype parameter, auto-resolved by name
 : @return formbind.html's own root element, hidden when no filter is active
 :)
declare function app:includeBindingtypeForm(
	$node as node(),
	$model as map(*),
	$bindingtype as xs:string*
) as element()? {
	app:include-facet-form($node, $model, "forms/formbind.html", app:list-param-active($bindingtype))
};

(:~
 : Server-side include of formfolia.html's own templated content,
 : exactly like app:includeRoleForm - a real bootstrap-slider widget
 : is not a blocker here: verified live (2026-08-27) that this
 : library positions its handles with percentages, not cached pixels,
 : so it initializes correctly even while its container starts
 : `display:none` and gets revealed later. Replaces the AJAX-fetch +
 : pre-checked-box-scan approach this facet shipped with initially.
 :
 : @param $folia the request's folia parameter, auto-resolved by name
 : @return formfolia.html's own root element, hidden when no filter is active
 :)
declare function app:includeFoliaForm($node as node(), $model as map(*), $folia as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formfolia.html", app:folia-active($folia))
};

(:~
 : Server-side include of formWL.html's own templated content - see
 : app:includeFoliaForm for why the slider widget is not a blocker.
 :
 : @param $wL the request's wL parameter, auto-resolved by name
 : @return formWL.html's own root element, hidden when no filter is active
 :)
declare function app:includeWLForm($node as node(), $model as map(*), $wL as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formWL.html", app:wL-active($wL))
};

(:~
 : Quire-count range slider for forms/formquires.html. Bounds are the
 : same hardcoded "1,100" q:par-qn itself checks against - unlike
 : folia/writtenLines, this facet's bounds weren't found to need
 : corpus-derived correction, only the state-echo this function adds.
 :
 : @param $qn the request's qn parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:quiresInput($node as node(), $model as map(*), $qn as xs:string*) as element(input) {
	let $range := if (exists($qn) and $qn[1] != "") then
		$qn[1]
	else
		"1,100"
	return <input
		class="span2"
		data-slider-max="100"
		data-slider-min="1"
		data-slider-step="1"
		data-slider-value="[{ substring-before($range, ",") },{ substring-after($range, ",") }]"
		id="quires"
		name="qn"
		type="text" />
};

(:~
 : Quire-composition range slider for forms/formquiresComp.html - see
 : app:quiresInput, same reasoning, this facet's own "1,40" sentinel.
 :
 : @param $qcn the request's qcn parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:quiresCompInput($node as node(), $model as map(*), $qcn as xs:string*) as element(input) {
	let $range := if (exists($qcn) and $qcn[1] != "") then
		$qcn[1]
	else
		"1,40"
	return <input
		class="span2"
		data-slider-max="40"
		data-slider-min="1"
		data-slider-step="1"
		data-slider-value="[{ substring-before($range, ",") },{ substring-after($range, ",") }]"
		id="quiresComp"
		name="qcn"
		type="text" />
};

(:~
 : Echoes the "quires" checkbox's state from the request.
 :
 : @param $qn the request's qn parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a non-default range is active
 :)
declare function app:quiresCheckbox($node as node(), $model as map(*), $qn as xs:string*) as element() {
	app:checkbox-state($node, app:qn-active($qn))
};

(:~
 : Echoes the "quiresComp" checkbox's state from the request.
 :
 : @param $qcn the request's qcn parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a non-default range is active
 :)
declare function app:quiresCompCheckbox($node as node(), $model as map(*), $qcn as xs:string*) as element() {
	app:checkbox-state($node, app:qcn-active($qcn))
};

(:~
 : Server-side include of formquires.html's own templated content -
 : see app:includeFoliaForm for why the slider widget is not a blocker.
 :
 : @param $qn the request's qn parameter, auto-resolved by name
 : @return formquires.html's own root element, hidden when no filter is active
 :)
declare function app:includeQuiresForm($node as node(), $model as map(*), $qn as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formquires.html", app:qn-active($qn))
};

(:~
 : Server-side include of formquiresComp.html's own templated content -
 : see app:includeFoliaForm for why the slider widget is not a blocker.
 :
 : @param $qcn the request's qcn parameter, auto-resolved by name
 : @return formquiresComp.html's own root element, hidden when no filter is active
 :)
declare function app:includeQuiresCompForm($node as node(), $model as map(*), $qcn as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formquiresComp.html", app:qcn-active($qcn))
};

(:~
 : Whether a slider-backed range parameter carries a real, non-default
 : value. Generic version of app:folia-active/app:wL-active etc. for
 : the nine formdimensions.html fields, which - unlike folia/wL - don't
 : need a corpus-derived bound (their widget defaults are plain
 : hand-authored physical-measurement bounds, not a data-quality
 : workaround), so a single shared helper taking the default as a
 : parameter is enough.
 :
 : @param $value the request parameter
 : @param $default the "no filter" sentinel, e.g. "1,1000"
 : @return true if a non-default "min,max" range is present
 :)
declare %private function app:range-active($value as xs:string*, $default as xs:string) as xs:boolean {
	exists($value) and $value[1] != "" and $value[1] != $default
};

(:~
 : Whether any of formdimensions.html's nine sliders carries a real
 : filter value - the composite reveal condition for the "dimensions"
 : checkbox/section, same OR-of-per-field-actives shape as
 : app:manuscriptsFiltersSection's own reveal condition.
 :
 : @return true if at least one of the nine fields is non-default
 :)
declare %private function app:dimensions-active(
	$height as xs:string*,
	$width as xs:string*,
	$depth as xs:string*,
	$columnsNum as xs:string*,
	$tmargin as xs:string*,
	$bmargin as xs:string*,
	$rmargin as xs:string*,
	$lmargin as xs:string*,
	$intercolumn as xs:string*
) as xs:boolean {
	app:range-active($height, "1,1000") or
		app:range-active($width, "1,1000") or
		app:range-active($depth, "1,1000") or
		app:range-active($columnsNum, "1,20") or
		app:range-active($tmargin, "1,100") or
		app:range-active($bmargin, "1,100") or
		app:range-active($rmargin, "1,100") or
		app:range-active($lmargin, "1,100") or
		app:range-active($intercolumn, "1,100")
};

(:~
 : Shared builder for formdimensions.html's nine near-identical
 : bootstrap-slider inputs - see app:foliaInput for the pattern (real
 : min/max/value instead of the fragment's own hardcoded, never-echoed
 : default).
 :
 : @param $value the request parameter, auto-resolved by name in each per-field wrapper below
 : @param $id the input's `id` (matches formdimensions.html's original per-field ids, and filters.js's centralized bootstrapSlider init)
 : @param $name the input's `name` (the real request parameter)
 : @param $min the slider's minimum
 : @param $max the slider's maximum
 : @param $step the slider's step
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare %private function app:rangeInput(
	$value as xs:string*,
	$id as xs:string,
	$name as xs:string,
	$min as xs:string,
	$max as xs:string,
	$step as xs:string
) as element(input) {
	let $range := if (exists($value) and $value[1] != "") then
		$value[1]
	else
		$min || "," || $max
	return <input
		class="span2"
		data-slider-max="{ $max }"
		data-slider-min="{ $min }"
		data-slider-step="{ $step }"
		data-slider-value="[{ substring-before($range, ",") },{ substring-after($range, ",") }]"
		id="{ $id }"
		name="{ $name }"
		type="text" />
};

(:~
 : Height slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $height the request's height parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:heightInput($node as node(), $model as map(*), $height as xs:string*) as element(input) {
	app:rangeInput($height, "heightslider", "height", "1", "1000", "10")
};

(:~
 : Width slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $width the request's width parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:widthInput($node as node(), $model as map(*), $width as xs:string*) as element(input) {
	app:rangeInput($width, "widthslider", "width", "1", "1000", "10")
};

(:~
 : Thickness/depth slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $depth the request's depth parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:depthInput($node as node(), $model as map(*), $depth as xs:string*) as element(input) {
	app:rangeInput($depth, "depthslider", "depth", "1", "1000", "10")
};

(:~
 : Columns-per-page slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $columnsNum the request's columnsNum parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:columnsNumInput($node as node(), $model as map(*), $columnsNum as xs:string*) as element(input) {
	app:rangeInput($columnsNum, "NumberOfcolumns", "columnsNum", "1", "20", "1")
};

(:~
 : Top-margin slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $tmargin the request's tmargin parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:tmarginInput($node as node(), $model as map(*), $tmargin as xs:string*) as element(input) {
	app:rangeInput($tmargin, "tMslider", "tmargin", "1", "100", "1")
};

(:~
 : Bottom-margin slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $bmargin the request's bmargin parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:bmarginInput($node as node(), $model as map(*), $bmargin as xs:string*) as element(input) {
	app:rangeInput($bmargin, "bMslider", "bmargin", "1", "100", "1")
};

(:~
 : Right-margin slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $rmargin the request's rmargin parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:rmarginInput($node as node(), $model as map(*), $rmargin as xs:string*) as element(input) {
	app:rangeInput($rmargin, "rMslider", "rmargin", "1", "100", "1")
};

(:~
 : Left-margin slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $lmargin the request's lmargin parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:lmarginInput($node as node(), $model as map(*), $lmargin as xs:string*) as element(input) {
	app:rangeInput($lmargin, "lMslider", "lmargin", "1", "100", "1")
};

(:~
 : Intercolumn slider for forms/formdimensions.html.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $intercolumn the request's intercolumn parameter, auto-resolved by name
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:intercolumnInput($node as node(), $model as map(*), $intercolumn as xs:string*) as element(input) {
	app:rangeInput($intercolumn, "lntercolumnslider", "intercolumn", "1", "100", "1")
};

(:~
 : Echoes the "dimensions" checkbox's state from the request - active
 : when any of the nine formdimensions.html fields carries a non-default
 : value, matching app:manuscriptsFiltersSection's own composite
 : reveal condition.
 :
 : @return the checkbox, with @checked set when any field is active
 :)
declare function app:dimensionsCheckbox(
	$node as node(),
	$model as map(*),
	$height as xs:string*,
	$width as xs:string*,
	$depth as xs:string*,
	$columnsNum as xs:string*,
	$tmargin as xs:string*,
	$bmargin as xs:string*,
	$rmargin as xs:string*,
	$lmargin as xs:string*,
	$intercolumn as xs:string*
) as element() {
	app:checkbox-state(
		$node,
		app:dimensions-active($height, $width, $depth, $columnsNum, $tmargin, $bmargin, $rmargin, $lmargin, $intercolumn)
	)
};

(:~
 : Server-side include of formdimensions.html's own templated content -
 : see app:includeFoliaForm for why the slider widgets are not a
 : blocker.
 :
 : @return formdimensions.html's own root element, hidden when no field is active
 :)
declare function app:includeDimensionsForm(
	$node as node(),
	$model as map(*),
	$height as xs:string*,
	$width as xs:string*,
	$depth as xs:string*,
	$columnsNum as xs:string*,
	$tmargin as xs:string*,
	$bmargin as xs:string*,
	$rmargin as xs:string*,
	$lmargin as xs:string*,
	$intercolumn as xs:string*
) as element()? {
	app:include-facet-form(
		$node,
		$model,
		"forms/formdimensions.html",
		app:dimensions-active($height, $width, $depth, $columnsNum, $tmargin, $bmargin, $rmargin, $lmargin, $intercolumn)
	)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare function app:keywords($node as node(), $model as map(*), $context as xs:string*) {
	let $keywords := doc($config:data-rootA || "/taxonomy.xml")//t:taxonomy
	let $control := app:formcontrol("keyword", $keywords, "false", "keywords", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:languages(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $keywords := config:distinct-values($cont//t:language/@ident)
	let $control := app:formcontrol("language", $keywords, "false", "values", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:scribes(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $elements := $cont//t:persName[@role eq "scribe"][not(@ref eq "PRS00000")][not(@ref eq "PRS0000")]
	let $keywords := config:distinct-values($elements/@ref)
	let $control := app:formcontrol("scribe", $keywords, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:donors(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $elements := $cont//t:persName[@role eq "donor"][not(@ref eq "PRS00000")][not(@ref eq "PRS0000")]
	let $keywords := config:distinct-values($elements/@ref)
	let $control := app:formcontrol("donor", $keywords, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:patrons(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $elements := $cont//t:persName[@role eq "patron"][not(@ref eq "PRS00000")][not(@ref eq "PRS0000")]
	let $keywords := config:distinct-values($elements/@ref)
	let $control := app:formcontrol("patron", $keywords, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:owners(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $elements := $cont//t:persName[@role eq "owner"][not(@ref eq "PRS00000")][not(@ref eq "PRS0000")]
	let $keywords := config:distinct-values($elements/@ref)
	let $control := app:formcontrol("owner", $keywords, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:binders(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $elements := $cont//t:persName[@role eq "binder"][not(@ref eq "PRS00000")][not(@ref eq "PRS0000")]
	let $keywords := config:distinct-values($elements/@ref)
	let $control := app:formcontrol("binder", $keywords, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:parmakers(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $elements := $cont//t:persName[@role eq "parchmentMaker"][not(@ref eq "PRS00000")][not(@ref eq "PRS0000")]
	let $keywords := config:distinct-values($elements/@ref)
	let $control := app:formcontrol("parchmentMaker", $keywords, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:contents(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $elements := $cont//t:msItem[not(contains(@xml:id, "."))]
	let $titles := $elements/t:title/@ref
	let $keywords := config:distinct-values($titles)
	let $control := app:formcontrol("content", $keywords, "false", "hierels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:mss(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := app:eval-mss-context($context)
	let $keywords :=
		for $r in $cont//t:witness/@corresp
		return string($r) || " "
	return app:formcontrol("ms", $keywords, "false", "hierels", $context)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:WorkAuthors(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $works := app:eval-mss-context($context)
	let $attributions :=
		for $rel in
			($works//t:relation[@name eq "saws:isAttributedToAuthor"], $works//t:relation[@name eq "dcterms:creator"])
		let $r := $rel/@passive
		return if (contains($r, " ")) then
			tokenize($r, " ")
		else
			$r
	let $keywords := config:distinct-values($attributions)
	let $control := app:formcontrol("author", $keywords, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js
 :)
declare %templates:default("context", "collection($config:data-rootIn)") function app:tabots(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) {
	let $cont := util:eval($context)
	let $tabots := $cont//t:ab[@type eq "tabot"]
	let $personTabot := config:distinct-values($tabots//t:persName/@ref)
	let $thingsTabot := config:distinct-values($tabots//t:ref/@corresp)
	let $alltabots := ($personTabot, $thingsTabot)
	let $control := app:formcontrol("tabot", $alltabots, "false", "rels", $context)
	return templates:form-control($control, $model)
};

(:~
 : Strips the BMurl prefix from a reference, if present. Expanded-data
 : @ref values are full URLs (https://betamasaheft.eu/PRS...), not
 : bare ids - found live while smoke-testing app:persRoleResults,
 : whose synthetic unit-test fixture used bare ids and missed it: an
 : unstripped ref breaks both the constructed href (double-prefixed,
 : "/https://...") and exptit:printTitleID (expects a bare id, returns
 : empty for a full URL).
 :
 : @param $ref an id or a BMurl-prefixed reference
 : @return the bare id
 :)
declare %private function app:bare-id($ref as xs:string) as xs:string {
	if (starts-with($ref, $config:BMurl)) then
		substring-after($ref, $config:BMurl)
	else
		$ref
};

(:~
 : Corpus-driven "which role" selector, replacing formrole.html's
 : stale hardcoded 10-value list (measured against the real corpus:
 : the single most-used role, "owner" - 2,445 uses - was missing
 : entirely; 3 of the 10 hardcoded values matched nothing). Single-
 : select by design, unlike app:selectors' generic "values" branch
 : (always `multiple="multiple"`) - the results side reads this as
 : one value, not an array.
 :
 : Selection-echoing itself is templates:form-control's job (matches
 : app:keywords/app:languages's own convention elsewhere in this
 : module) rather than hand-rolled, since it already reads "role" from
 : the request by this select's own @name - the zero-JS equivalent of
 : restoring $("#persRole").val() after a page reload, with no need to
 : take $role as its own parameter at all.
 :
 : @param $context a collection expression, resolved via app:eval-mss-context
 : @return a single-select control, name="role" id="persRole"
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:persRole(
	$node as node(),
	$model as map(*),
	$context as xs:string*
) as element() {
	let $cont := app:eval-mss-context($context)
	let $roles := config:distinct-values($cont//t:persName/@role[. != ""])
	let $select := <select class="w3-select w3-border" id="persRole" name="role">
		<option value="">choose</option>
		{
			for $r in $roles
			let $count := count($cont//t:persName[@role eq $r])
			let $label := lower-case(replace($r, "([a-z])([A-Z])", "$1 $2"))
			order by $label
			return <option value="{ $r }">{ $label || " (" || $count || ")" }</option>
		}
	</select>
	return templates:form-control($select, $model)
};

(:~
 : Real, server-rendered replacement for personswithrole.js's first
 : AJAX/JSON round-trip: given a role (submitted by app:persRole),
 : lists every distinct person attested with it, each with a real
 : link (`?role=X&amp;person=Y`) to app:persRolePersonDetail's
 : specific-record breakdown - genuine lazy loading via a real URL,
 : not a client-side fetch.
 :
 : @param $role the role to look up people for; empty renders nothing
 : at all - this must stay lazy, never compute every role's people
 : list up front
 : @return the results markup, or an empty sequence
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:persRoleResults(
	$node as node(),
	$model as map(*),
	$context as xs:string*,
	$role as xs:string*
) as element()* {
	if (empty($role) or $role[1] = "") then (
	) else
		let $cont := app:eval-mss-context($context)
		let $r := $role[1]
		let $attestations := $cont//t:persName[@role eq $r][@ref][not(starts-with(app:bare-id(string(@ref)), "PRS0000"))]
		let $people :=
			for $att in $attestations
			let $id := app:bare-id(string($att/@ref))
			group by $ID := $id
			return map {"id": $ID, "count": count($att)}
		(:
		 : Carries other active facets forward, same convention as
		 : app:pageNav/app:pagesNav's own $params. Needs a real request
		 : (none in direct XQSuite calls, as with
		 : app:manuscriptsFiltersSection) - catch degrades to "nothing
		 : to preserve".
		 :)
		let $preservedParams := try {
			string-join(
				for $param in $app:params
				for $value in request:get-parameter($param, ())
				return if ($param = ("role", "person")) then (
				) else
					encode-for-uri($param) || "=" || encode-for-uri($value),
				"&amp;"
			)
		} catch * { "" }
		return <div class="w3-container" id="persWithRoleResults">
			<h4>There are <span class="w3-tag w3-red w3-round">{ count($people) }</span> persons with a role <span
					class="w3-tag w3-gray w3-round"
				>{ $r }</span>
			</h4>
			{
				for $p in $people
				order by $p?count descending
				return <div class="w3-card-4 w3-padding w3-margin w3-third" data-person="{ $p?id }">
					<header class="w3-container">
						<a href="{ $config:appUrl }/{ $p?id }">{ exptit:printTitleID($p?id) }</a>
					</header>
					<div class="w3-container">is mentioned as { $r || " " || $p?count } times:</div>
					<a
						class="w3-button w3-gray w3-small"
						href="?{
							if ($preservedParams != "") then
								$preservedParams || "&amp;"
							else
								""
						}role={ encode-for-uri($r) }&amp;person={ encode-for-uri($p?id) }"
					>Click to see in which records.</a>
				</div>
			}
		</div>
};

(:~
 : Real, server-rendered replacement for personswithrole.js's second
 : AJAX/JSON round-trip: given a role AND a specific person (both
 : from the request), lists that person's individual source records
 : for that role - computed only when this exact URL is requested,
 : the same genuine lazy loading as app:persRoleResults.
 :
 : @param $role the role being looked up
 : @param $person the specific person's id; empty renders nothing
 : @return the per-record breakdown markup, or an empty sequence
 :)
declare %templates:default("context", "collection($config:data-rootMS)") function app:persRolePersonDetail(
	$node as node(),
	$model as map(*),
	$context as xs:string*,
	$role as xs:string*,
	$person as xs:string*
) as element()* {
	if (empty($role) or $role[1] = "" or empty($person) or $person[1] = "") then (
	) else
		let $cont := app:eval-mss-context($context)
		let $r := $role[1]
		let $p := $person[1]
		let $candidates := $cont//t:persName[@role eq $r][@ref][not(starts-with(app:bare-id(string(@ref)), "PRS0000"))]
		let $atts := $candidates[app:bare-id(string(@ref)) eq $p]
		let $sources :=
			for $att in $atts
			let $root := string(root($att)/t:TEI/@xml:id)
			group by $ROOT := $root
			return map {"source": $ROOT, "count": count($att)}
		return <div class="w3-container" id="persRolePersonDetail">
			<h4>{ exptit:printTitleID($p) } as { $r }, in { count($sources) } source(s):</h4>
			<ul>
				{
					for $s in $sources
					return <li data-source="{ $s?source }">
						<a href="{ $config:appUrl }/{ $s?source }">{ exptit:printTitleID($s?source) }</a> ({ $s?count } times)
					</li>
				}
			</ul>
		</div>
};

(:~
 : Echoes the "role" checkbox's state from the request - zero-JS
 : equivalent of what filters.js's client-side "checked" state used to
 : lose on reload.
 :
 : @param $role the request's role parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a role is selected
 :)
declare function app:roleCheckbox($node as node(), $model as map(*), $role as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($role))
};

(:~
 : Whether `gender` carries a real filter value - unlike the slider
 : facets' "min,max" sentinel, list-style params like this one are
 : simply active when non-empty (q:ListQueryParam-rest's caller
 : already filters out blank values before dispatch, so there's no
 : separate "no filter applied" literal to match against).
 :
 : @param $gender the request's gender parameter
 : @return true if any value is present
 :)
declare %private function app:gender-active($gender as xs:string*) as xs:boolean {
	exists($gender) and $gender[1] != ""
};

(:~
 : Reveals the "Works Filters" section server-side when one of its
 : facets has an active request parameter, instead of relying on
 : filters.js's `#collectionfilter` change handler alone (JS-only,
 : lost on reload). Only `authors` participates so far - extend this
 : parameter list as more `#wFilter` facets get the same treatment.
 :
 : @param $author the request's author parameter, auto-resolved by name
 : @return the section, with its `display:none` dropped when active
 :)
declare function app:worksFiltersSection(
	$node as node(),
	$model as map(*),
	$author as xs:string*,
	$target-work as xs:string*
) as element() {
	element {node-name($node)} {
		templates:filter-attributes($node, $model) except $node/@style,
		if (app:list-param-active($author) or app:list-param-active($target-work)) then (
		) else
			$node/@style,
		$node/node()!templates:process(., $model)
	}
};

(:~
 : Echoes the "authors" checkbox's state from the request - the
 : checkbox's own value ("authors") differs from the actual request
 : parameter it gates (`author`, singular - see app:WorkAuthors).
 :
 : @param $author the request's author parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:authorsCheckbox($node as node(), $model as map(*), $author as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($author))
};

(:~
 : Server-side include of formauthors.html's own templated content.
 :
 : @param $author the request's author parameter, auto-resolved by name
 : @return formauthors.html's own root element, hidden when no filter is active
 :)
declare function app:includeAuthorsForm($node as node(), $model as map(*), $author as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formauthors.html", app:list-param-active($author))
};

(:~
 : Reveals the "Places Filters" section server-side when one of its
 : facets has an active request parameter, instead of relying on
 : filters.js's `#collectionfilter` change handler alone (JS-only,
 : lost on reload). Only `tabots` participates so far - extend this
 : parameter list as more `#plFilter` facets get the same treatment.
 :
 : @param $tabot the request's tabot parameter, auto-resolved by name
 : @return the section, with its `display:none` dropped when active
 :)
declare function app:placesFiltersSection(
	$node as node(),
	$model as map(*),
	$tabot as xs:string*,
	$placeType as xs:string*
) as element() {
	element {node-name($node)} {
		templates:filter-attributes($node, $model) except $node/@style,
		if (app:list-param-active($tabot) or app:list-param-active($placeType)) then (
		) else
			$node/@style,
		$node/node()!templates:process(., $model)
	}
};

(:~
 : Echoes the "tabots" checkbox's state from the request - the
 : checkbox's own value ("tabots") differs from the actual request
 : parameter it gates (`tabot`, singular - see app:tabots).
 :
 : @param $tabot the request's tabot parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:tabotsCheckbox($node as node(), $model as map(*), $tabot as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($tabot))
};

(:~
 : Server-side include of formtabots.html's own templated content.
 :
 : @param $tabot the request's tabot parameter, auto-resolved by name
 : @return formtabots.html's own root element, hidden when no filter is active
 :)
declare function app:includeTabotsForm($node as node(), $model as map(*), $tabot as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formtabots.html", app:list-param-active($tabot))
};

(:~
 : Echoes the "languages" checkbox's state from the request - the
 : checkbox's own value differs from the actual request parameter it
 : gates (`language`, singular - see app:languages). Unlike the
 : Manuscripts/Persons/Works/Places facets, this checkbox lives under
 : "General filters" directly, which has no wrapping reveal section of
 : its own to extend - only the checkbox and its fragment need echoing.
 :
 : @param $language the request's language parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:languagesCheckbox($node as node(), $model as map(*), $language as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($language))
};

(:~
 : Server-side include of formlanguages.html's own templated content.
 :
 : @param $language the request's language parameter, auto-resolved by name
 : @return formlanguages.html's own root element, hidden when no filter is active
 :)
declare function app:includeLanguagesForm($node as node(), $model as map(*), $language as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formlanguages.html", app:list-param-active($language))
};

(:~
 : Echoes the "keywords" checkbox's state from the request - the
 : checkbox's own value differs from the actual request parameter it
 : gates (`keyword`, singular - see app:keywords).
 :
 : @param $keyword the request's keyword parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:keywordsCheckbox($node as node(), $model as map(*), $keyword as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($keyword))
};

(:~
 : Server-side include of formkeywords.html's own templated content.
 :
 : @param $keyword the request's keyword parameter, auto-resolved by name
 : @return formkeywords.html's own root element, hidden when no filter is active
 :)
declare function app:includeKeywordsForm($node as node(), $model as map(*), $keyword as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formkeywords.html", app:list-param-active($keyword))
};

(:~
 : Echoes the "relations" checkbox's state from the request - the
 : checkbox's own value differs from the actual request parameter it
 : gates (`relType` - see app:relationType).
 :
 : @param $relType the request's relType parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:relationsCheckbox($node as node(), $model as map(*), $relType as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($relType))
};

(:~
 : Server-side include of formrelations.html's own templated content.
 :
 : @param $relType the request's relType parameter, auto-resolved by name
 : @return formrelations.html's own root element, hidden when no filter is active
 :)
declare function app:includeRelationsForm($node as node(), $model as map(*), $relType as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formrelations.html", app:list-param-active($relType))
};

(:~
 : Whether `dateRange` carries a real, non-default filter value. Mirrors
 : q:par-date-range's own sentinel exactly: that function - now shared
 : by both queries.xqm's REST-facing case "dateRange" dispatch and
 : app:query's as.html "date" facet, see its doc for why this used to
 : be two divergent implementations - treats a submitted "1,2000" (its
 : full slider range) the same as no filter at all, so the echoed
 : default here must be "1,2000" too, not the fragment's original
 : hardcoded widget preset ("350,1900"): that preset doesn't match the
 : sentinel, so always rendering it (instead of only on click, as the
 : pre-conversion AJAX fetch did) would have silently turned every
 : unfiltered search into one filtered to 350-1900, discarding all
 : undated items. See app:dateInput for where the true default is
 : produced.
 :
 : @param $dateRange the request's dateRange parameter
 : @return true if a non-default "min,max" range is present
 :)
declare %private function app:date-active($dateRange as xs:string*) as xs:boolean {
	exists($dateRange) and $dateRange[1] != "" and $dateRange[1] != "1,2000"
};

(:~
 : Date-range slider for forms/formdates.html. Bounds match
 : q:par-date-range's own hardcoded sentinel (1-2000) rather than the
 : fragment's original "350,1900" widget preset - see app:date-active.
 :
 : @param $node the data-template marker node (unused, part of the templates:apply contract)
 : @param $model unused, part of the templates:apply contract
 : @param $dateRange the request's dateRange parameter, auto-resolved by
 : name - a "min,max" pair, echoed back as the slider's initial position
 : @return the <input> element for the bootstrap-slider widget, with the submitted range echoed
 :)
declare function app:dateInput($node as node(), $model as map(*), $dateRange as xs:string*) as element(input) {
	let $range := if (exists($dateRange) and $dateRange[1] != "") then
		$dateRange[1]
	else
		"1,2000"
	return <input
		class="span2"
		data-slider-max="2000"
		data-slider-min="1"
		data-slider-step="10"
		data-slider-value="[{ substring-before($range, ",") },{ substring-after($range, ",") }]"
		id="dates"
		name="dateRange"
		type="text" />
};

(:~
 : Echoes the "date" checkbox's state from the request - like
 : languages/keywords/relations, this checkbox lives under "General
 : filters" directly, with no wrapping reveal section of its own.
 :
 : @param $dateRange the request's dateRange parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a non-default range is active
 :)
declare function app:dateCheckbox($node as node(), $model as map(*), $dateRange as xs:string*) as element() {
	app:checkbox-state($node, app:date-active($dateRange))
};

(:~
 : Server-side include of formdates.html's own templated content - see
 : app:includeFoliaForm for why the slider widget is not a blocker.
 :
 : @param $dateRange the request's dateRange parameter, auto-resolved by name
 : @return formdates.html's own root element, hidden when no filter is active
 :)
declare function app:includeDateForm($node as node(), $model as map(*), $dateRange as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formdates.html", app:date-active($dateRange))
};

(:~
 : Echoes the "script" checkbox's state from the request.
 :
 : @param $script the request's script parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:scriptCheckbox($node as node(), $model as map(*), $script as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($script))
};

(:~
 : Server-side include of formscripts.html's own templated content.
 :
 : @param $script the request's script parameter, auto-resolved by name
 : @return formscripts.html's own root element, hidden when no filter is active
 :)
declare function app:includeScriptForm($node as node(), $model as map(*), $script as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formscripts.html", app:list-param-active($script))
};

(:~
 : Echoes the "parchmentMaker" checkbox's state from the request.
 :
 : @param $parchmentMaker the request's parchmentMaker parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:parchmentMakerCheckbox(
	$node as node(),
	$model as map(*),
	$parchmentMaker as xs:string*
) as element() {
	app:checkbox-state($node, app:list-param-active($parchmentMaker))
};

(:~
 : Server-side include of formParMaker.html's own templated content.
 :
 : @param $parchmentMaker the request's parchmentMaker parameter, auto-resolved by name
 : @return formParMaker.html's own root element, hidden when no filter is active
 :)
declare function app:includeParchmentMakerForm(
	$node as node(),
	$model as map(*),
	$parchmentMaker as xs:string*
) as element()? {
	app:include-facet-form($node, $model, "forms/formParMaker.html", app:list-param-active($parchmentMaker))
};

(:~
 : Echoes the "material" checkbox's state from the request.
 :
 : @param $material the request's material parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:materialCheckbox($node as node(), $model as map(*), $material as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($material))
};

(:~
 : Server-side include of formmaterial.html's own templated content.
 :
 : @param $material the request's material parameter, auto-resolved by name
 : @return formmaterial.html's own root element, hidden when no filter is active
 :)
declare function app:includeMaterialForm($node as node(), $model as map(*), $material as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formmaterial.html", app:list-param-active($material))
};

(:~
 : Echoes the "bmaterial" checkbox's state from the request.
 :
 : @param $bmaterial the request's bmaterial parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:bmaterialCheckbox($node as node(), $model as map(*), $bmaterial as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($bmaterial))
};

(:~
 : Server-side include of formbmaterial.html's own templated content.
 :
 : @param $bmaterial the request's bmaterial parameter, auto-resolved by name
 : @return formbmaterial.html's own root element, hidden when no filter is active
 :)
declare function app:includeBmaterialForm($node as node(), $model as map(*), $bmaterial as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formbmaterial.html", app:list-param-active($bmaterial))
};

(:~
 : Echoes the "target-works" checkbox's state from the request - the
 : checkbox's own value differs from the actual request parameter it
 : gates (`target-work`, singular - see app:target-works).
 :
 : @param $target-work the request's target-work parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:targetWorksCheckbox($node as node(), $model as map(*), $target-work as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($target-work))
};

(:~
 : Server-side include of formworks.html's own templated content.
 :
 : @param $target-work the request's target-work parameter, auto-resolved by name
 : @return formworks.html's own root element, hidden when no filter is active
 :)
declare function app:includeTargetWorksForm(
	$node as node(),
	$model as map(*),
	$target-work as xs:string*
) as element()? {
	app:include-facet-form($node, $model, "forms/formworks.html", app:list-param-active($target-work))
};

(:~
 : Echoes the "occupation" checkbox's state from the request - the
 : checkbox's own value differs from the actual request parameter it
 : gates (`persType` - see app:personType).
 :
 : @param $persType the request's persType parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:occupationCheckbox($node as node(), $model as map(*), $persType as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($persType))
};

(:~
 : Server-side include of formoccupation.html's own templated content.
 :
 : @param $persType the request's persType parameter, auto-resolved by name
 : @return formoccupation.html's own root element, hidden when no filter is active
 :)
declare function app:includeOccupationForm($node as node(), $model as map(*), $persType as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formoccupation.html", app:list-param-active($persType))
};

(:~
 : Echoes the "placeType" checkbox's state from the request.
 :
 : @param $placeType the request's placeType parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:placeTypeCheckbox($node as node(), $model as map(*), $placeType as xs:string*) as element() {
	app:checkbox-state($node, app:list-param-active($placeType))
};

(:~
 : Server-side include of formplacetype.html's own templated content.
 :
 : @param $placeType the request's placeType parameter, auto-resolved by name
 : @return formplacetype.html's own root element, hidden when no filter is active
 :)
declare function app:includePlaceTypeForm($node as node(), $model as map(*), $placeType as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formplacetype.html", app:list-param-active($placeType))
};

(:~
 : Reveals the "Persons Filters" section server-side when one of its
 : facets has an active request parameter, instead of relying on
 : filters.js's `#collectionfilter` change handler alone (JS-only,
 : lost on reload).
 :
 : Reads each facet's request parameter directly via request:get-parameter
 : rather than taking auto-resolved parameters, same reasoning as
 : app:manuscriptsFiltersSection: templates:call's introspection-based
 : dispatch caps at 20 total parameters, so a growing positional
 : signature is one facet away from the same templates:NotFound failure
 : that broke that function in production. Extend the OR-condition below
 : as more `#pFilter` facets get the same treatment; no signature change
 : is ever needed again.
 :
 : @return the section, with its `display:none` dropped when active
 :)
declare function app:persFiltersSection($node as node(), $model as map(*)) as element() {
	element {node-name($node)} {
		templates:filter-attributes($node, $model) except $node/@style,
		if (
			app:list-param-active(request:get-parameter("role", ())) or
				app:gender-active(request:get-parameter("gender", ())) or
				app:list-param-active(request:get-parameter("persType", ()))
		) then (
		) else
			$node/@style,
		$node/node()!templates:process(., $model)
	}
};

(:~
 : Echoes the "gender" checkbox's state from the request - the outer
 : `#pFilter` toggle, not the two inner Male/Female checkboxes inside
 : formgender.html itself (those go straight through
 : templates:form-control, a real name="gender" checkbox group).
 :
 : @param $gender the request's gender parameter, auto-resolved by name
 : @return the checkbox, with @checked set when a value is selected
 :)
declare function app:genderCheckbox($node as node(), $model as map(*), $gender as xs:string*) as element() {
	app:checkbox-state($node, app:gender-active($gender))
};

(:~
 : Server-side include of formgender.html's own templated content -
 : see app:includeFoliaForm for the pattern this follows. No JS widget
 : involved here at all (formgender.html's own Male/Female checkboxes
 : are plain templates:form-control targets), so there was never a
 : hidden-init concern to check for this one.
 :
 : @param $gender the request's gender parameter, auto-resolved by name
 : @return formgender.html's own root element, hidden when no filter is active
 :)
declare function app:includeGenderForm($node as node(), $model as map(*), $gender as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formgender.html", app:gender-active($gender))
};

(:~
 : Server-side equivalent of filters.js's `callformpart("forms/formrole.html",
 : "roleform")`: includes formrole.html's own templated content directly,
 : so it's already in the page - and already reflects `role`/`person` -
 : on a plain reload with no JS needed. `filters.js`'s existing click
 : handler still works unmodified: `callformpart` only fetches a
 : fragment when its target id isn't already in the page, and toggles
 : visibility otherwise - which is exactly what's wanted once this div
 : is always present.
 :
 : @param $role the request's role parameter, auto-resolved by name
 : @return formrole.html's own root element, hidden when no role is selected
 :)
declare function app:includeRoleForm($node as node(), $model as map(*), $role as xs:string*) as element()? {
	app:include-facet-form($node, $model, "forms/formrole.html", exists($role) and $role[1] != "")
};

(:~
 : called by form*.html files used by advances search form as.html and filters.js IDS, TITLES, PERSNAMES, PLACENAMES, provide lists with guessing based on typing. the list must suggest a name but search for an ID
 :)
declare function app:BuildSearchQuery($element as xs:string, $query as xs:string) {
	let $SearchOptions :=
	"map {
  'default-operator': 'or',
  'phrase-slop' : '0',
  'leading-wildcard' :'yes',
  'filter-rewrite': 'yes'
}"
	return if ($element = "TEI") then
		concat("ft:query(., '", $query, "', ", $SearchOptions, ")")
	else
		concat("descendant::t:", $element, "[ft:query(., '", $query, "', ", $SearchOptions, ")]")
};

(:~
 : a function simply evaluating an xpath entered as string
 :)
declare function app:xpathQuery($node as node(), $model as map(*), $xpath as xs:string?) {
	if (empty($xpath)) then (
	) else
		let $logpath := log:add-log-message($xpath, sm:id()//sm:real/sm:username/string(), "XPath query")
		let $xpath := replace($xpath, "\$config:collection-(\w+)(//.+)", "collection(\$config:data-$1)$2")
		let $hits :=
			for $hit in util:eval($xpath)
			return $hit
		return map {"hits": $hits, "path": $xpath, "total": count($hits)}
};

(:~
 : a function evaluating a sparql query, using the https://github.com/ljo/exist-sparql package
 :)
declare function app:sparqlQuery($node as node(), $model as map(*), $query as xs:string?) {
	if (empty($query)) then
		"Please enter a valid SPARQL query."
	else
		let $prefixes := $config:sparqlPrefixes
		let $allquery := ($prefixes || normalize-space($query))
		let $logpath := log:add-log-message($query, sm:id()//sm:real/sm:username/string(), "SPARQL query")
		let $results := fusekisparql:query("betamasaheft", $allquery)
		return map {"sparqlResult": $results, "q": $query}
};

declare %templates:wrap function app:sparqlRes($node as node(), $model as map(*)) {
	transform:transform($model("sparqlResult"), "xmldb:exist:///db/apps/BetMasWeb/rdfxslt/sparqltable.xsl", ())
};

(:~
 : produces a piece of xpath for the query if the input is a range
 :)
declare function app:paramrange($par, $path as xs:string) {
	let $rangeparam := request:get-parameter($par, ())

	let $from := substring-before($rangeparam, ",")
	let $to := substring-after($rangeparam, ",")
	return if ($rangeparam = "0,2000") then (
	) else if ($rangeparam = "") then (
	) else (
		"[descendant::t:" || $path || "[. ge " || $from || " ][ .  le " || $to || "]]"
	)
};

(:~
 : Builds a q:range-predicate-backed filter for one of formdimensions.html's
 : nine fields, or the empty sequence when the field is absent or at its
 : default. Not app:paramrange: that function's sentinel is a hardcoded
 : "0,2000", which matches none of these fields' real defaults ("1,1000",
 : "1,20", "1,100"), so every one of them would have been treated as an
 : always-active filter the moment a value - even an untouched
 : slider default - was submitted. q:range-predicate's own quoted,
 : guarded comparison also avoids the crash class found and fixed in
 : q:par-date-range's sibling bug (see that function's doc): real
 : `t:height`/`t:width` values include non-numeric content like "1975 m"
 : (a unit suffix left in the text), which an unguarded `[. ge 1975]`
 : comparison can't safely evaluate.
 :
 : @param $param the request parameter name
 : @param $pathPrefix an XPath step from the TEI element being filtered, e.g. "descendant::t:dimensions[@type eq 'outer']/t:height"
 : @param $target the predicate's comparison target relative to $pathPrefix, e.g. "." or "@columns"
 : @param $guard an extra predicate restricting $pathPrefix to numeric-looking values, or the empty sequence when the source is already reliably typed
 : @param $default the "no filter" sentinel, e.g. "1,1000"
 : @return an XPath predicate string, or the empty sequence when the field is absent, blank, or at its default
 :)
declare %private function app:range-filter(
	$param as xs:string,
	$pathPrefix as xs:string,
	$target as xs:string,
	$guard as xs:string?,
	$default as xs:string
) as xs:string? {
	let $range := request:get-parameter($param, ())
	return if (empty($range) or $range = "" or $range = $default) then (
	) else
		let $min := substring-before($range, ",")
		let $max := substring-after($range, ",")
		return q:range-predicate($pathPrefix, $target, $guard, $min, $max)
};

(:~
 : Execute the query on TEI, so that facet indexes will be reacheable
 :)
declare function app:facetquery($node as node()*, $model as map(*), $query as xs:string*) {
	if (string-length($query) lt 1) then (
	) else
		let $homophones := "true"
		let $query-string := if ($query != "") then (
			if ($homophones = "true") then
				if (contains($query, "AND")) then
					(
						let $parts :=
							for $qpart in tokenize($query, "AND")
							return all:substitutionsInQuery($qpart)
						return "(" || string-join($parts, ") AND (")
					) ||
						")"
				else if (contains($query, "OR")) then
					(
						let $parts :=
							for $qpart in tokenize($query, "OR")
							return all:substitutionsInQuery($qpart)
						return "(" || string-join($parts, ") OR (")
					) ||
						")"
				else
					all:substitutionsInQuery($query)
			else
				$query
		) else (
		)

		let $populatefacets :=
			for $parm in $app:params[ends-with(., "-facet")]
			let $key := substring-before($parm, "-facet")
			let $values := request:get-parameter($parm, ())
			return map {$key: ($values)}
		let $options := map:merge($populatefacets)
		let $allopts := map {
			"default-operator": "or",
			"phrase-slop": "0",
			"leading-wildcard": "yes",
			"filter-rewrite": "yes",
			"facets": $options
		}
		let $queryExpr := '//t:TEI[descendant::t:change[contains(., "complete")]][ft:query(., (), $allopts)]'
		let $hits := $exptit:col//t:TEI[ft:query(., $query-string, $allopts)]
		return map {"hits": $hits, "q": $query, "type": "matches", "query": $queryExpr}
};

(:~
 : Execute the query. The search results are not output immediately. Instead they
 : are passed to nested templates through the $model parameter.
 :)
declare
	%templates:default("scope", "narrow")
	%templates:default("work-types", "all")
	%templates:default("target-ms", "all")
	%templates:default("target-work", "all")
	%templates:default("homophones", "true")
	%templates:default("numberOfParts", "")
	%templates:default("element", "TEI")
function app:query(
	$node as node()*,
	$model as map(*),
	$query as xs:string*,
	$numberOfParts as xs:string*,
	$work-types as xs:string+,
	$element as xs:string+,
	$target-ms as xs:string+,
	$target-work as xs:string+,
	$homophones as xs:string+
) {
	let $homophones := request:get-parameter("homophones", ())

	let $paramstobelogged :=
		for $p in $app:params
		for $value in request:get-parameter($p, ())
		return ($p || "=" || $value)
	let $logparams := "?" || string-join($paramstobelogged, "&amp;")
	let $log := log:add-log-message($logparams, sm:id()//sm:real/sm:username/string(), "query")
	let $IDpart := app:ListQueryParam("xmlid", "@xml:id", "any", "search")
	let $collection := app:ListQueryParam("work-types", "@type", "any", "search")
	let $script := app:ListQueryParam("script", "t:handNote/@script", "any", "search")
	let $mss := app:ListQueryParam("target-ms", "@xml:id", "any", "search")
	let $texts := app:ListQueryParam("target-work", "@xml:id", "any", "search")
	let $support := app:ListQueryParam("support", "t:objectDesc/@form", "any", "search")
	let $material := app:ListQueryParam("material", "t:support/t:material/@key", "any", "search")
	let $bmaterial := app:ListQueryParam(
		"bmaterial",
		"t:decoNote[@type eq 'bindingMaterial']/t:material/@key",
		"any",
		"search"
	)
	let $bindingtype := app:ListQueryParam("bindingtype", "t:binding/@contemporary", "any", "search")
	let $placeType := app:ListQueryParam("placeType", "t:place/@type", "any", "search")
	let $personType := app:ListQueryParam("persType", "t:person//t:occupation/@type", "any", "search")
	let $relationType := app:ListQueryParam("relType", "t:relation/@name", "any", "search")
	let $repository := app:ListQueryParam("target-ins", "t:repository/@ref ", "any", "search")
	let $keyword := app:ListQueryParam("keyword", "t:term/@key ", "any", "search")
	let $languages := app:ListQueryParam("language", "t:language/@ident", "any", "search")
	let $scribes := app:ListQueryParam("scribe", "t:persName[@role eq 'scribe']/@ref", "any", "search")
	let $donors := app:ListQueryParam("donor", "t:persName[@role eq 'donor']/@ref", "any", "search")
	let $patrons := app:ListQueryParam("patron", "t:persName[@role eq 'patron']/@ref", "any", "search")
	let $owners := app:ListQueryParam("owner", "t:persName[@role eq 'owner']/@ref", "any", "search")
	let $parchmentMakers := app:ListQueryParam(
		"parchmentMaker",
		"t:persName[@role eq 'parchmentMaker']/@ref",
		"any",
		"search"
	)
	let $binders := app:ListQueryParam("binder", "t:persName[@role eq 'binder']/@ref", "any", "search")
	let $contents := app:ListQueryParam("content", "t:title/@ref", "any", "search")
	let $wits := app:ListQueryParam("ms", "t:witness/@corresp", "any", "search")
	let $authors := app:ListQueryParam(
		"author",
		"t:relation[@name eq 'saws:isAttributedToAuthor']/@passive",
		"any",
		"search"
	)
	(: let $authorsCertain := app:ListQueryParam('author', "t:relation[@name='dcterms:creator']/@passive", 'any', 'search') :)
	let $tabots := app:ListQueryParam("tabot", "t:ab[@type eq 'tabot']/t:*/(@ref|@corresp)", "any", "search")
	let $references := if (contains($app:params, "references")) then
		let $refs :=
			for $ref in tokenize(request:get-parameter("references", ()), ",")
			return "[descendant::t:*/@*[not(name() eq 'xml:id')] ='" || $ref || "' ]"
		return string-join($refs, "")
	else (
	)
	let $genders := if (contains($app:params, "gender")) then
		(:
		 : @sex is stored as a string ("1"/"2") - the unquoted literal here
		 : previously compared it against an xs:integer, which XPath's `eq`
		 : (unlike `=`) refuses to promote, throwing XPTY0004 on every real
		 : search with this filter active. Multiple genders selected are a
		 : checkbox group over one field's distinct values, so OR them
		 : together like every other multi-value filter in this function
		 : does, not AND (which could only ever match zero records).
		 :)
		let $values := request:get-parameter("gender", ())
		let $predicates :=
			for $v in $values
			return "descendant::t:person/@sex eq '" || $v || "'"
		return "[" || string-join($predicates, " or ") || "]"
	else (
	)
	(:
	 : Sentinel values ("is this the default, unfiltered range") derive
	 : from q:max-folia/q:max-written-lines rather than a hardcoded
	 : literal, matching q:par-folia/q:par-wL and list:paramsList - this
	 : block used to hardcode "1,1000" for both (a copy-paste bug in the
	 : wL block below: "1,1000" is folia's own old default, not wL's
	 : "1,100" - meaning the wL sentinel check here was never actually
	 : reachable). Fixed alongside the drift risk shared with the other
	 : two implementations of this same filter.
	 :)
	let $leaves := if (contains($app:params, "folia")) then (
		let $range := request:get-parameter("folia", ())
		let $min := substring-before($range, ",")
		let $max := substring-after($range, ",")
		return if ($range = "1," || q:max-folia()) then (
		) else if (empty($range)) then (
		) else
			(: [matches(.,'^\d+$')] guards against non-integer-formatted values, same as before. :)
			q:range-predicate(
				"descendant::t:extent/t:measure[@unit eq 'leaf'][not(@type)]",
				".",
				"[matches(.,'^\d+$')]",
				$min,
				$max
			)
	) else (
	)
	let $wL := if (contains($app:params, "wL")) then
		q:computed-written-lines-filter(request:get-parameter("wL", ()))
	else (
	)
	let $quires := if (contains($app:params, "qn")) then (
		let $range := request:get-parameter("qn", ())
		return if ($range = "1,100") then (
		) else
			app:paramrange("qn", "extent/t:measure[@unit eq 'quire'][not(@type)][matches(.,'^\d+$')]")
	) else (
	)
	let $quiresComp := if (contains($app:params, "qcn")) then (
		let $range := request:get-parameter("qcn", ())
		return if ($range = "1,40") then (
		) else
			app:paramrange("qcn", "collation//t:dim[@unit eq 'leaf']")
	) else (
	)
	(:
	 : Delegates to q:par-date-range (see its own doc) rather than
	 : maintaining a second, divergent implementation here. The previous
	 : local version had two real bugs, both found live-testing this
	 : slice: it guarded on `contains($app:params, "dataRange")` (typo
	 : for "dateRange", so the filter never actually ran for any real
	 : request), and its predicate applied to `descendant::t:*` with
	 : unquoted integer literals, which crashed with `XPTY0004` on any
	 : element carrying a non-numeric `@notBefore`/`@notAfter`.
	 :)
	let $dateRange := q:par-date-range("origDate", request:get-parameter("dateRange", ()))
	(:
	 : This whole block used to run through app:paramrange, which has
	 : three real bugs found live-testing this facet: a hardcoded
	 : "0,2000" sentinel matching none of these fields' actual defaults
	 : (so an untouched slider default was treated as an active filter);
	 : an unquoted numeric comparison, unsafe against real data (`t:height`
	 : includes values like "1975 m", a unit suffix left in the text);
	 : and - specific to the four margin fields - a copy-paste bug where
	 : bmargin/rmargin/lmargin each read the "tmargin" request parameter
	 : instead of their own, so only the top-margin slider's value ever
	 : reached any of the four margin filters. The path itself was also
	 : wrong: real data uses `t:dimensions` (see below), not the
	 : `t:dimension` this block searched for, so the margin filters
	 : matched nothing at all regardless of the other bugs. See
	 : app:range-filter's own doc for why it replaces app:paramrange here
	 : specifically rather than patching it in place.
	 :
	 : height/width/depth filters target expand-emitted computed siblings
	 : (`@subtype='computed'`, mm `@quantity`) — see BetMasWeb#113.
	 :)
	let $height := q:computed-height-filter(request:get-parameter("height", ()))
	let $width := q:computed-width-filter(request:get-parameter("width", ()))
	let $depth := q:computed-depth-filter(request:get-parameter("depth", ()))
	(:
	 : Not wired to any filter at all before this fix - the "Columns per
	 : page" slider submitted `columnsNum`, but no code anywhere read it.
	 : Target is an explicit xs:integer(@columns) cast, not the bare
	 : attribute: unlike the other eight dimension fields (plain element
	 : text content, untypedAtomic, general-comparison-promotes to
	 : numeric automatically), `@columns` is schema-typed as xs:string,
	 : so `[@columns ge 1]` throws `XPTY0004` ("can not compare
	 : xs:string('2') with xs:integer('1')") on every value, guard or
	 : not - found live-testing, not hypothetical.
	 :)
	let $columnsNum := if (contains($app:params, "columnsNum")) then
		q:computed-columns-filter(string(request:get-parameter("columnsNum", ())))
	else (
	)
	let $marginTop := q:computed-margin-filter(request:get-parameter("tmargin", ()), "top")
	let $marginBot := q:computed-margin-filter(request:get-parameter("bmargin", ()), "bottom")
	let $marginR := q:computed-margin-filter(request:get-parameter("rmargin", ()), "right")
	let $marginL := q:computed-margin-filter(request:get-parameter("lmargin", ()), "left")
	let $marginIntercolumn := q:computed-margin-filter(request:get-parameter("intercolumn", ()), "intercolumn")

	let $query-string := if ($query != "") then (
		if ($homophones = "true") then
			if (contains($query, "AND")) then
				(
					let $parts :=
						for $qpart in tokenize($query, "AND")
						return all:substitutionsInQuery($qpart)
					return "(" || string-join($parts, ") AND (")
				) ||
					")"
			else if (contains($query, "OR")) then
				(
					let $parts :=
						for $qpart in tokenize($query, "OR")
						return all:substitutionsInQuery($qpart)
					return "(" || string-join($parts, ") OR (")
				) ||
					")"
			else
				all:substitutionsInQuery($query)
		else
			$query
	) else (
	)

	let $eachworktype :=
		for $wtype in request:get-parameter("work-types", ())
		return "@type='" ||
			$wtype ||
			"'" ||
			(
				(: in case there is only one collection parameter selected and this is equal to place, search also institutions :)
				if (
					count(request:get-parameter("work-types", ())) eq 1 and request:get-parameter("work-types", ()) = "place"
				) then (
					"or @type='ins'"
				) else
					""
			)

	let $wt := if (contains($app:params, "work-types")) then
		"[" || string-join($eachworktype, " or ") || "]"
	else (
	)
	let $nOfP := q:ms-parts-count-filter($numberOfParts)

	let $allfilters := concat(
		$IDpart,
		$wt,
		$repository,
		$mss,
		$texts,
		$script,
		$support,
		$material,
		$bmaterial,
		$bindingtype,
		$placeType,
		$personType,
		$relationType,
		$keyword,
		$languages,
		$scribes,
		$donors,
		$patrons,
		$owners,
		$parchmentMakers,
		$binders,
		$contents,
		$authors,
		$tabots,
		$genders,
		$dateRange,
		$leaves,
		$wL,
		$quires,
		$quiresComp,
		$references,
		$height,
		$width,
		$depth,
		$columnsNum,
		$marginTop,
		$marginBot,
		$marginL,
		$marginR,
		$marginIntercolumn
	)

	(: the evalutaion of the entire string for the query makes it impossible to use range indexes in a proper way,
the same for the elements evaluated with the OR operator in one argument for the path.
this should update the query results for each parameter, updating the variable step by step
for the elements to be searched it should search one by one AFTER applying the filters, so only in the items filter out and then
union the sequences of results and remove the doubles from the union
 :)
	let $queryExpr := $query-string
	return if (empty($queryExpr) or $queryExpr = "") then (
		if (empty($app:params)) then (
		) else (
			let $hits :=
				let $path := concat("$exptit:col", "//t:TEI", $allfilters, $nOfP)
				for $hit in util:eval($path)
				return $hit

			return map {"hits": $hits, "type": "records"}
		)
	) else
		let $hits :=
			let $elements :=
				for $e in $element
				return app:BuildSearchQuery($e, $query-string)

			let $allels := string-join($elements, " or ")
			let $path := concat("$exptit:col", "//t:TEI[", $allels, "]", $allfilters)
			let $log := util:log("info", $path)
			let $logpath := log:add-log-message($path, sm:id()//sm:real/sm:username/string(), "XPath")
			let $hits := util:eval($path)
			for $hit in $hits
			order by ft:score($hit) descending
			return $hit

		let $store := (session:set-attribute("apps.BetMas", $hits), session:set-attribute("apps.BetMas.query", $queryExpr))

		return (: Process nested templates :) map {"hits": $hits, "q": $query, "type": "matches", "query": $queryExpr}
};

(:~
 : Helper function: create a lucene query from the user input
 :)
declare function app:create-query($query-string as xs:string?, $mode as xs:string) {
	let $query-string := if ($query-string) then
		app:sanitize-lucene-query($query-string)
	else
		""
	let $query-string := normalize-space($query-string)
	let $query-string := if (contains($query-string, "s")) then
		let $options := replace($query-string, "s", "ḍ")
		return ($query-string || " " || $options)
	else
		$query-string
	let $query-string := if (contains($query-string, "e")) then
		let $options := (replace($query-string, "e", "ǝ"), replace($query-string, "e", "ē"))
		return ($query-string || " " || string-join($options, " "))
	else
		$query-string

	(: Remove/ignore ayn and alef :)
	let $query-string := if (contains($query-string, "ʾ")) then
		let $options := replace($query-string, "ʾ", "")
		return ($query-string || " " || string-join($options, " "))
	else
		$query-string
	let $query-string := if (contains($query-string, "ʿ")) then
		let $options := replace($query-string, "ʿ", "")
		return ($query-string || " " || string-join($options, " "))
	else
		$query-string

	let $query :=
	(: If the query contains any operator used in sandard lucene searches or regex searches, pass it on to the query parser; :)
	if (
		functx:contains-any-of(
			$query-string,
			("AND", "OR", "NOT", "+", "-", "!", "~", "^", ".", "?", "*", "|", "{", "[", "(", "<", "@", "#", "&amp;")
		) and
			$mode eq "any"
	) then
		let $luceneParse := app:parse-lucene($query-string)
		let $luceneXML := parse-xml($query-string)
		let $lucene2xml := app:lucene2xml($luceneXML/node(), $mode)
		return $lucene2xml
	(: otherwise the query is performed by selecting one of the special options (any, all, phrase, near, fuzzy, wildcard or regex) :)
	else
		let $query-string := tokenize($query-string, "\s")
		let $last-item := $query-string[last()]
		let $query-string := if ($last-item castable as xs:integer) then
			string-join(subsequence($query-string, 1, count($query-string) - 1), " ")
		else
			string-join($query-string, " ")

		let $query := <query>
			{
				if ($mode eq "any") then
					for $term in tokenize($query-string, "\s")
					return <term occur="should">{ $term }</term>
				else if ($mode eq "all") then
					<bool>
						{
							for $term in tokenize($query-string, "\s")
							return <term occur="must">{ $term }</term>
						}
					</bool>
				else if ($mode eq "phrase") then
					<phrase>{ $query-string }</phrase>
				else if ($mode eq "near-unordered") then
					<near
						ordered="no"
						slop="{
							if ($last-item castable as xs:integer) then
								$last-item
							else
								5
						}"
					>{ $query-string }</near>
				else if ($mode eq "near-ordered") then
					<near
						ordered="yes"
						slop="{
							if ($last-item castable as xs:integer) then
								$last-item
							else
								5
						}"
					>{ $query-string }</near>
				else if ($mode eq "fuzzy") then
					<fuzzy
						max-edits="{
							if ($last-item castable as xs:integer and number($last-item) < 3) then
								$last-item
							else
								2
						}"
					>{ $query-string }</fuzzy>
				else if ($mode eq "wildcard") then
					<wildcard>{ $query-string }</wildcard>
				else if ($mode eq "regex") then
					<regex>{ $query-string }</regex>
				else (
				)
			}
		</query>
		return $query
	return $query
};

(: SIMPLE search :)

(:~
 : FROM SHAKESPEAR
 : Create a span with the number of items in the current search result.
 :)
declare function app:hit-count($node as node()*, $model as map(*)) {
	<div class="w3-panel w3-card-4">
		{
			if ($model("type") = "bibliography") then
				<h3>There are <span xmlns="http://www.w3.org/1999/xhtml" class="w3-tag w3-gray" id="hit-count">
						{ count($model("hits")) }
					</span> distinct bibliographical references</h3>
			else if ($model("type") = "matches") then
				<h3>You found <span class="w3-tag w3-gray">{ $app:searchphrase }</span> in <span
						xmlns="http://www.w3.org/1999/xhtml"
						class="w3-tag w3-gray"
						id="hit-count"
					>{ count($model("hits")) }</span> results</h3>
			else (
				<h3> There are <span xmlns="http://www.w3.org/1999/xhtml" class="w3-tag w3-gray" id="hit-count">
						{ count($model("hits")) }
					</span> entities matching your query. </h3>
			)
		}
	</div>
};

declare function app:hit-params($node as node()*, $model as map(*)) {
	<div>
		{
			for $param in distinct-values($app:params)
			let $values := request:get-parameter($param, ())
			return if (count($values) = 2 and ((string-join($values, ",") != "0,2000") or (string-join($values) = ""))) then (
				<span class="w3-tag w3-gray w3-round ">
					{ $param }
					{
						" between ",
						<span class="w3-badge">{ $values[1] }</span>,
						" and ",
						<span class="w3-badge">{ $values[2] }</span>
					}
				</span>
			) else
				for $value in $values
				return if ($value = "") then (
				) else if ($param = "start") then (
				) else if ($param = "query") then (
				) else if (ends-with($param, "-operator-field")) then (
				) else
					<span class="w3-tag w3-gray w3-round " style="word-break:break-all">
						{ ($param || ": ", <span class="w3-badge">{ $value }</span>) }
					</span>
		}
	</div>
};

declare function app:gotoadvanced($node as node()*, $model as map(*)) {
	let $query := request:get-parameter("query", ())
	return <div class="w3-bar">
		<a
			class="w3-button w3-red w3-margin w3-bar-item"
			href="{ $config:appUrl }/as.html?query={ $query }"
		>Repeat search in the Advanced search.</a>
	</div>
};

declare function app:list-count($node as node()*, $model as map(*)) {
	<h3>
		{ $app:collection || " " }
		{
			string-join(
				for $param in $app:params
				for $value in request:get-parameter($param, ())
				return if ($param = "start") then (
				) else if ($param = "collection") then (
				) else if ($param = "dateRange") then (
					"between " ||
						substring-before(request:get-parameter("dateRange", ()), ",") ||
						" and " ||
						substring-after(request:get-parameter("dateRange", ()), ",")
				) else
					$param || ": " || $value,
				", "
			)
		}: <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count">{ count($model("hits")) }</span>
	</h3>
};

(:~
 : FROM SHAKESPEAR
 : Create a bootstrap pagination element to navigate through the hits.
 :)

declare
	%templates:wrap
	%templates:default("start", 1)
	%templates:default("per-page", 20)
	%templates:default("min-hits", 0)
	%templates:default("max-pages", 20)
function app:paginate(
	$node as node(),
	$model as map(*),
	$start as xs:int,
	$per-page as xs:int,
	$min-hits as xs:int,
	$max-pages as xs:int
) {
	if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
		let $types := if ($model("type") = "bibliography" or $model("type") = "indexes") then (
			count($model("hits"))
		) else
			for $x in $model("hits")
			group by $t := root($x)/t:TEI/@type
			return count($x)
		let $count := xs:integer(ceiling(max($types)) div $per-page) + 1
		let $middle := ($max-pages + 1) idiv 2
		let $params := string-join(
			for $param in $app:params
			for $value in request:get-parameter($param, ())
			return if ($param = "start") then (
			) else if ($param = "collection") then (
			) else
				$param || "=" || $value,
			"&amp;"
		)
		return (
			if ($start = 1) then (
				<li class="disabled"><a><i class="glyphicon glyphicon-fast-backward" /></a></li>,
				<li class="disabled"><a><i class="glyphicon glyphicon-backward" /></a></li>
			) else (
				<li><a href="?{ $params }&amp;start=1"><i class="glyphicon glyphicon-fast-backward" /></a></li>,
				<li>
					<a href="?{ $params }&amp;start={ max(($start - $per-page, 1)) }">
						<i class="glyphicon glyphicon-backward" />
					</a>
				</li>
			),
			let $startPage := xs:integer(ceiling($start div $per-page))
			let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
			let $upperBound := min(($lowerBound + $max-pages - 1, $count))
			let $lowerBound := max(($upperBound - $max-pages + 1, 1))
			for $i in $lowerBound to $upperBound
			return if ($i = ceiling($start div $per-page)) then
				<li class="active"><a href="?{ $params }&amp;start={ max((($i - 1) * $per-page + 1, 1)) }">{ $i }</a></li>
			else
				<li><a href="?{ $params }&amp;start={ max((($i - 1) * $per-page + 1, 1)) }">{ $i }</a></li>,
			if ($start + $per-page < count($model("hits"))) then (
				<li><a href="?{ $params }&amp;start={ $start + $per-page }"><i class="glyphicon glyphicon-forward" /></a></li>,
				<li>
					<a href="?{ $params }&amp;start={ max((($count - 1) * $per-page + 1, 1)) }">
						<i class="glyphicon glyphicon-fast-forward" />
					</a>
				</li>
			) else (
				<li class="disabled"><a><i class="glyphicon glyphicon-forward" /></a></li>,
				<li><a><i class="glyphicon glyphicon-fast-forward" /></a></li>
			)
		)
	else (
	)
};

declare
	%templates:wrap
	%templates:default("start", 1)
	%templates:default("per-page", 20)
	%templates:default("min-hits", 0)
	%templates:default("max-pages", 20)
function app:paginateNew(
	$node as node(),
	$model as map(*),
	$start as xs:int,
	$per-page as xs:int,
	$min-hits as xs:int,
	$max-pages as xs:int
) {
	if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
		let $types := if ($model("type") = "bibliography" or $model("type") = "indexes") then (
			count($model("hits"))
		) else
			for $x in $model("hits")
			group by $t := string((root($x)/t:TEI/@type)[1])
			return count($x)
		let $count := xs:integer(ceiling(max($types)) div $per-page) + 1
		let $middle := ($max-pages + 1) idiv 2
		let $params := string-join(
			for $param in $app:params
			for $value in request:get-parameter($param, ())
			return if ($param = "start") then (
			) else if ($param = "collection") then (
			) else
				$param || "=" || $value,
			"&amp;"
		)
		return (
			(: backwarding arrows, disabled if not available :)
			if ($start = 1) then (
				<a class="w3-button w3-disabled"><i class="fa fa-fast-backward" /></a>,
				<a class="w3-button w3-disabled"><i class="fa fa-backward" /></a>
			) else (
				<a class="w3-button " href="?{ $params }&amp;start=1"><i class="fa fa-fast-backward" /></a>,
				<a class="w3-button " href="?{ $params }&amp;start={ max(($start - $per-page, 1)) }">
					<i class="fa fa-backward" />
				</a>
			),
			(: numbers :)
			let $startPage := xs:integer(ceiling($start div $per-page))
			let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
			let $upperBound := min(($lowerBound + $max-pages - 1, $count))
			let $lowerBound := max(($upperBound - $max-pages + 1, 1))
			for $i in $lowerBound to $upperBound
			return if ($i = ceiling($start div $per-page)) then
				<a class="w3-button" href="?{ $params }&amp;start={ max((($i - 1) * $per-page + 1, 1)) }">{ $i }</a>
			else
				<a class="w3-button" href="?{ $params }&amp;start={ max((($i - 1) * $per-page + 1, 1)) }">{ $i }</a>,
			(: forwarding arrows, disabled if not available :)
			if ($start + $per-page < count($model("hits"))) then (
				<a class="w3-button" href="?{ $params }&amp;start={ $start + $per-page }"><i class="fa fa-forward" /></a>,
				<a class="w3-button" href="?{ $params }&amp;start={ max((($count - 1) * $per-page + 1, 1)) }">
					<i class="fa fa-fast-forward" />
				</a>
			) else (
				<a class="w3-button w3-disabled"><i class="fa fa-forward" /></a>,
				<a class="w3-button w3-disabled"><i class="fa fa-fast-forward" /></a>
			)
		)
	else (
	)
};

declare %templates:wrap %templates:default("start", 1) %templates:default("per-page", 40) function app:facetSearchRes(
	$node as node()*,
	$model as map(*),
	$start as xs:integer,
	$per-page as xs:integer
) {
	<div class="w3-row w3-border-bottom w3-margin-bottom w3-gray">
		<div class="w3-third">
			<div class="w3-col" style="width:15%"><span class="number">score</span></div>
			<div class="w3-col" style="width:70%">
               title
              </div>
			<div class="w3-col" style="width:15%">
                hits count
              </div>
		</div>
		<div class="w3-twothird">
			<div class="w3-twothird">first three keywords in context</div>
			<div class="w3-third">item-type specific options</div>
		</div>
	</div>,
	for $text at $p in subsequence($model("hits"), $start, $per-page)
	let $queryText := request:get-parameter("query", ())

	let $expanded := kwic:expand($text)
	let $firstancestorwithID := ($expanded//exist:match/(ancestor::t:*[(@xml:id | @n)] | ancestor::t:text))[last()]
	let $test := console:log($firstancestorwithID)
	let $firstancestorwithIDid := $firstancestorwithID/string(@xml:id)
	let $view := if ($firstancestorwithID[ancestor-or-self::t:text]) then
		"text"
	else
		"main"
	let $firstancestorwithIDanchor := if ($view = "main") then
		"#" || $firstancestorwithIDid
	else (
	)

	let $count := count($expanded//exist:match)
	let $root := root($text)
	let $item := $root/t:TEI
	let $t := $root/t:TEI/@type
	let $id := data($root/t:TEI/@xml:id)
	let $collection := switch2:col($t)
	let $score as xs:float := ft:score($text)
	let $tokvalues :=
		for $tokenInQuery in tokenize($queryText, "\s")
		return if ($text[contains(., $tokenInQuery)]) then
			5
		else
			0
	let $values := sum($tokvalues)
	let $enrichedScore := $score +
		$values +
		(count($text//node()) div 100) +
		(
			if ($text//t:ab[node()]) then
				4
			else if ($text//t:occupation) then
				2
			else if ($text/ancestor::t:TEI//t:change[contains(., "complete")]) then
				1
			else (
			)
		)
	order by $enrichedScore descending
	return <div class="w3-row w3-border-bottom w3-margin-bottom">
		<div class="w3-third">
			<div class="w3-col" style="width:15%">
				<span class="w3-tag w3-red">{ $enrichedScore }</span>
				<span class="w3-tag w3-red">
					{
						if ($item//t:change[contains(., "complete")]) then (
							attribute style { "background-color:rgb(172, 169, 166, 0.4)" }, "complete"
						) else if ($item//t:change[contains(., "review")]) then (
							attribute style { "background-color:white" }, "reviewed"
						) else (
							attribute style { "background-color:rgb(213, 75, 10, 0.4)" }, "stub"
						)
					}
				</span>
			</div>
			<div class="w3-col" style="width:70%">
				<span class="w3-tag w3-gray">{ $collection }</span>
				<span class="w3-tag w3-gray" style="word-break: break-all; text-align: left;">{ $id }</span>
				<span class="w3-tag w3-red">
					<a href="{ $config:appUrl }/{ ("/tei/" || $id || ".xml") }" target="_blank">TEI</a>
				</span>
				<!-- <span class="w3-tag w3-red"><a href="{$config:appUrl}/{$id}.pdf" target="_blank" >PDF</a></span><br/>-->
				<a href="{ $config:appUrl }/{ $collection }/{ $id }/main" target="_blank">
					<b>
						{
							if (starts-with($id, "corpus")) then
								$root//t:titleStmt/t:title[1]/text()
							else
								try { exptit:printTitleID($id) } catch * { console:log(($text, $id, $err:description)) }
						}
					</b>
				</a>
				<br />
				{
					if ($item//t:facsimile/t:graphic/@url) then
						<a href="{ $config:appUrl }/{ $item//t:facsimile/t:graphic[1]/@url }" target="_blank">Link to images</a>
					else if ($item//t:msIdentifier/t:idno[@facs][@n]) then
						<a href="{ $config:appUrl }/manuscripts/{ $id }/viewer" target="_blank">
							{
								if ($item//t:collection = "Ethio-SPaRe") then
									<img
										class="thumb w3-image"
										src="{
											$config:appUrl ||
												"/iiif/" ||
												string(($item//t:msIdentifier)[1]/t:idno/@facs) ||
												"_001.tif/full/140,/0/default.jpg"
										}" />
								(: laurenziana :)
								else if ($item//t:repository[@ref eq "INS0339BML"]) then
									<img
										class="thumb w3-image"
										src="{
											$config:appUrl ||
												"/iiif/" ||
												string($item//t:msIdentifier/t:idno/@facs) ||
												"005.tif/full/140,/0/default.jpg"
										}" />

								(:
EMIP :)
								else if (($item//t:collection = "EMIP") and $item//t:msIdentifier/t:idno/@n) then
									<img
										class="thumb w3-image"
										src="{
											$config:appUrl ||
												"/iiif/" ||
												string(($item//t:msIdentifier)[1]/t:idno/@facs) ||
												"001.tif/full/140,/0/default.jpg"
										}" />

								(: BNF :)
								else if (($item//t:repository/@ref)[1] eq "INS0303BNF") then
									<img
										class="thumb w3-image"
										src="{
											replace($item//t:msIdentifier/t:idno/@facs, "ark:", "iiif/ark:") || "/f1/full/140,/0/native.jpg"
										}" />
								(: vatican :)
								else if (contains($item//t:msIdentifier/t:idno/@facs, "digi.vat")) then
									<img
										class="thumb w3-image"
										src="{
											replace(
												substring-before($item//t:msIdentifier/t:idno/@facs, "/manifest.json"),
												"iiif",
												"pub/digit"
											) ||
												"/thumb/" ||
												substring-before(
													substring-after($item//t:msIdentifier/t:idno/@facs, "MSS_"),
													"/manifest.json"
												) ||
												"_0001.tif.jpg"
										}" />
								(: bodleian :)
								else if (contains($item//t:msIdentifier/t:idno/@facs, "bodleian")) then (
									"images"
								) else (
									<img
										class="thumb w3-image"
										src="{
											$config:appUrl ||
												"/iiif/" ||
												string($item//t:msIdentifier/t:idno[not(starts-with(@facs, "https"))][1]/@facs) ||
												(
													if (starts-with($item//t:collection, "Ethio")) then
														"_"
													else (
													)
												) ||
												"001.tif/full/140,/0/default.jpg"
										}" />
								)
							}
						</a>

					else (
					)
				}
				{
					if ($collection = "works") then
						apptable:clavisIds($root)
					else (
					)
				}
			</div>
			<div class="w3-col" style="width:15%">
				<span class="w3-badge">{ $count }</span>
                in {
					for $match in config:distinct-values($expanded//exist:match/parent::t:*/name())
					return (<code>{ string($match) }</code>, <br />)
				}
			</div>
		</div>
		<div class="w3-twothird">
			<div class="w3-twothird">
				{
					for $match in subsequence($expanded//exist:match, 1, 3)
					let $matchancestorwithID := ($match/(ancestor::t:*[(@xml:id | @n)] | ancestor::t:text))[last()]
					let $matchancestorwithIDid := $matchancestorwithID/string(@xml:id)
					let $view := if ($matchancestorwithID[ancestor-or-self::t:text]) then
						"text"
					else
						"main"
					let $matchancestorwithIDanchor := if ($view = "main") then
						"#" || $matchancestorwithIDid
					else (
					)

					return let $matchref := replace(app:refname($match), ".$", "")
						let $ref := if ($view = "text" and $matchref != "") then
							"&amp;ref=" || $matchref
						else (
						)
						return <div class="w3-row w3-padding">
							<div class="w3-twothird w3-padding match">
								{ kwic:get-summary($match/parent::node(), $match, <config width="40" />) }
							</div>
							<div class="w3-third w3-padding">
								<a
									href="{ $config:appUrl }/{ $collection }/{ $id }/{ $view }{ $matchancestorwithIDanchor }?hi={
										$queryText
									}{ $ref }"
								>
									{
										" in element " ||
											$match/parent::t:*/name() ||
											" within a " ||
											$matchancestorwithID/name() ||
											(
												if ($view = "text" and $matchref != "") then
													", at " || $matchref
												else if ($view = "main") then
													", with id " || $matchancestorwithIDid
												else (
												)
											)
									}
								</a>
							</div>
						</div>
				}
			</div>
			<div class="w3-third">
				{
					switch ($t)
						case "mss" return
							(
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/IndexPlaces?entity={ $id }"
									role="button"
								>places</a>,
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/IndexPersons?entity={ $id }"
									role="button"
								>persons</a>
							)
						case "pers" return
							()
						case "ins" return
							(
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/manuscripts/{ $id }/list"
									role="button"
								>manuscripts</a>
							)
						case "place" return
							(
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/manuscripts/place/list?place={ $id }"
									role="button"
								>manuscripts</a>
							)
						case "nar" return
							(<a class="w3-button w3-small w3-gray" href="{ $config:appUrl }/collate" role="button">collate</a>)
						case "work" return
							(
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/compare?workid={ $id }"
									role="button"
								>compare</a>,
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/workmap?worksid={ $id }"
									role="button"
								>map of mss</a>,
								<a class="w3-button w3-small w3-gray" href="{ $config:appUrl }/collate" role="button">collate</a>,
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/IndexPlaces?entity={ $id }"
									role="button"
								>places</a>,
								<a
									class="w3-button w3-small w3-gray"
									href="{ $config:appUrl }/IndexPersons?entity={ $id }"
									role="button"
								>persons</a>
							)
						default return
							<a
								class="w3-button w3-small w3-gray"
								href="{ $config:appUrl }/authority-files/list?keyword={ $id }"
								role="button"
							>with this keyword</a>
				}
				<a
					class="w3-button w3-small w3-gray"
					href="{ $config:appUrl }/{ $collection }/{ $id }/analytic"
					role="button"
				>relations</a>
			</div>
		</div>
	</div>
};

(:~
 : copied from  dts: to format and select the references
 :)
declare function app:refname($n) {
	(: has to recurs each level of ancestor of the node which
   has a valid position in the text structure :)
	let $refname := if ($n[name() = "ab"] or $n[name() = "match"]) then (
	) else
		app:rn($n)
	let $this := normalize-space($refname)
	let $ancestors :=
		for $a in $n/ancestor::t:div[@xml:id or @n or @corresp][ancestor::t:div[@type]]
		return app:rn($a)
	let $all := ($ancestors, $this)
	return string-join($all, ".")
};

(:~
 : copied and adapted from dts and called by app:refname to format
 : a single reference starting from a match
 :)
declare function app:rn($n) {
	if ($n[name() = "exist:match"]) then (
	) else if ($n/preceding-sibling::t:cb) then (
		string($n/preceding-sibling::t:pb[@n][1]/@n) || string($n/preceding-sibling::t:cb[@n][1]/@n)
	) else if ($n/name() = "pb" and $n/@corresp) then (
		string($n/@n) || "[" || substring-after($n/@corresp, "#") || "]"
	) else if ($n/@n) then
		string($n/@n)
	else if ($n/@xml:id) then
		string($n/@xml:id)
	else if ($n/@subtype) then
		string($n/@subtype)
	else
		"tei:" || $n/name() || "[" || $n/position() || "]"
};

declare function app:searchResMatches($model, $start, $per-page) {
	for $text at $p in $model("hits")
	let $root := root($text)
	let $t := $root/t:TEI/@type
	group by $type := $t
	let $collection := switch2:col($type)

	return <div class="w3-container w3-panel w3-card-2 w3-padding results{ $collection }">
		<div class="w3-padding">
			<h4>
				{ count($text) } result{
					if (count($text) gt 1) then
						"s"
					else
						""
				} in {
					if ($collection = "institutions") then
						"repositories"
					else
						$collection
				}
			</h4>
			{
				for $tex at $p in subsequence($text, $start, $per-page)
				let $queryText := request:get-parameter("query", ())
				let $root := root($tex)
				let $id := $root/t:TEI/string(@xml:id)
				let $expanded := kwic:expand($tex)
				let $firstancestorwithID := (
					$expanded//exist:match/(ancestor::t:text | ancestor::t:*[(@xml:id | @n)][not(self::t:TEI)])
				)[1]
				let $firstancestorwithIDid := if ($firstancestorwithID/@xml:id) then
					$firstancestorwithID/string(@xml:id)
				else
					" without id "
				let $view := if ($firstancestorwithID[ancestor-or-self::t:text]) then
					"text"
				else
					"main"
				let $firstancestorwithIDanchor := if ($view = "main") then
					"#" || $firstancestorwithIDid
				else (
				)
				let $count := count($expanded//exist:match)
				let $score as xs:float := ft:score($tex)
				return <div class="w3-row reference">
					<div class="w3-third">
						<div class="w3-col w3-padding" style="width:10%"><span class="number">{ $start + $p - 1 }</span></div>
						<div class="w3-col w3-padding" style="width:70%;word-break:break-all">
							{
								if (count($text) gt 50) then
									<a href="{ $config:appUrl }/{ $collection }/{ $id }/main?hi={ $queryText }" target="_blank">
										{ exptit:printTitleID($id) }
									</a>
								else
									<a href="{ $config:appUrl }/{ $collection }/{ $id }/main?hi={ $queryText }" target="_blank">
										{ try { exptit:printTitleID($id) } catch * { console:log($err:description) } }
									</a>
							} ({ $id })
             </div>
						<div class="w3-col w3-padding" style="width:15%;overflow:auto;">
							<span class="w3-badge">{ $count }</span>
						</div>
					</div>
					<div class="w3-twothird">
						{
							for $match in subsequence($expanded//exist:match, 1, 3)
							let $matchref := replace(app:refname($match), ".$", "")
							let $ref := if ($view = "text" and $matchref != "") then
								"&amp;ref=" || $matchref
							else (
							)
							return <div>
								<div class="w3-twothird w3-padding match">
									{ kwic:get-summary($match/parent::node(), $match, <config width="40" />) }
								</div>
								<div class="w3-third w3-padding">
									<a
										href="{ $config:appUrl }/{ $collection }/{ $id }/{ $view }{ $firstancestorwithIDanchor }?hi={
											$queryText
										}{ $ref }"
									>
										{
											" in element " ||
												$firstancestorwithID/name() ||
												(
													if ($view = "text" and $matchref != "") then
														", at " || $matchref
													else if ($view = "main") then
														", with id " || $firstancestorwithIDid
													else (
													)
												)
										}
									</a>
								</div>
							</div>
						}
					</div>
				</div>
			}
		</div>
	</div>
};

declare function app:searchResNotMatches($model, $start, $per-page) {
	for $text in $model("hits")
	let $root := root($text)
	let $t := string($root/t:TEI/@type[1])
	group by $type := $t
	let $collection := switch2:col($type)

	return <div class="w3-container w3-panel w3-card-2 w3-padding results{ $collection }">
		<div class="w3-margin w3-padding">
			<h4>
				{ count($text) } result{
					if (count($text) gt 1) then
						"s"
					else
						""
				} in {
					if ($collection = "institutions") then
						"repositories"
					else
						$collection
				}
			</h4>
			{
				for $tex at $p in subsequence($text, $start, $per-page)
				let $root := root($tex)
				let $id := data($root/t:TEI/@xml:id)
				let $collection := switch2:col($root/t:TEI/@type)
				return <div class="w3-row reference">
					<div class="w3-col" style="width:15%"><span class="number">{ $start + $p - 1 }</span></div>
					<div class="w3-half">
						<a href="{ $config:appUrl }/{ $collection }/{ $id }/main" target="_blank">
							{ exptit:printTitleID($id) }
						</a> ({ $id })</div>
					<div class="w3-rest">{ data($root/t:TEI/@type) }</div>
				</div>
			}
		</div>
	</div>
};

declare %templates:wrap %templates:default("start", 1) %templates:default("per-page", 10) function app:searchRes(
	$node as node()*,
	$model as map(*),
	$start as xs:integer,
	$per-page as xs:integer
) {
	switch ($model("type"))
		(: These will have exist:match and are results of a ft:query :)
		case "matches" return
			app:searchResMatches($model, $start, $per-page)
		(: These are results of a query which does not include ft:query :)
		default return
			app:searchResNotMatches($model, $start, $per-page)
};

declare %templates:wrap function app:xpathresultstitle($node as node(), $model as map(*)) {
	<h2>{ $model("total") } results for { $model("path") }</h2>
};

declare %templates:wrap function app:sparqlresultstitle($node as node(), $model as map(*)) {
	<div class="w3-panel w3-card-2 w3-white">Your query: <span class="w3-tag w3-gray">
			{ $model("q") }
		</span> returned <span class="w3-tag w3-gray">{ count($model("sparqlResult")//sr:result) }</span> results</div>
};

declare %templates:wrap %templates:default("start", 1) %templates:default("per-page", 10) function app:XpathRes(
	$node as node(),
	$model as map(*),
	$start as xs:integer,
	$per-page as xs:integer
) {
	for $text at $p in subsequence($model("hits"), $start, $per-page)
	let $root := root($text)
	let $id := data($root/t:TEI/@xml:id)
	return <div class="w3-row  w3-margin-bottom">
		<div class="w3-col w3-container" style="width:10%"><span class="number">{ $start + $p - 1 }</span></div>
		<div class="w3-col w3-container" style="width:50%">
			<a href="{ $config:appUrl }/{ $id }">{ exptit:printTitleID($id) }</a> ({ $id })</div>
		<div class="w3-col w3-container " style="width:20%">{ data($text/ancestor::t:*[@xml:id][1]/@xml:id) }</div>
		<div class="w3-col w3-container" style="width:20%"><code>{ $text/name() }</code></div>
	</div>
};

(: copy all parameters, needed for search :)

declare function app:copy-params($node as node(), $model as map(*)) {
	element {node-name($node)} {
		$node/@* except $node/@href,
		attribute href {
			let $link := $node/@href
			let $params := string-join(
				for $param in $app:params
				for $value in request:get-parameter($param, ())
				return $param || "=" || $value,
				"&amp;"
			)
			return $link || "?" || $params
		},
		$node/node()
	}
};

(: This functions provides crude way to avoid the most common errors with paired expressions and apostrophes. :)
(: TODO: check order of pairs :)
declare %private function app:sanitize-lucene-query($query-string as xs:string) as xs:string {
	let $query-string := replace($query-string, "'", "''") (: escape apostrophes :)
	(: TODO: notify user if query has been modified. :)(: Remove colons – Lucene fields are not supported. :)
	let $query-string := translate($query-string, ":", " ")
	(: if there is an uneven number of quotation marks, delete all quotation marks. :)
	let $query-string := if (functx:number-of-matches($query-string, '"') mod 2) then
		$query-string
	else
		replace($query-string, '"', " ")
	(: if there is an uneven number of parentheses, delete all parentheses. :)
	let $query-string := if (
		(functx:number-of-matches($query-string, "\(") + functx:number-of-matches($query-string, "\)")) mod 2 eq 0
	) then
		$query-string
	else
		translate($query-string, "()", " ")
	(: if there is an uneven number of brackets, delete all brackets. :)
	let $query-string := if (
		(functx:number-of-matches($query-string, "\[") + functx:number-of-matches($query-string, "\]")) mod 2 eq 0
	) then
		$query-string
	else
		translate($query-string, "[]", " ")
	(: if there is an uneven number of braces, delete all braces. :)
	let $query-string := if (
		(functx:number-of-matches($query-string, "{") + functx:number-of-matches($query-string, "}")) mod 2 eq 0
	) then
		$query-string
	else
		translate($query-string, "{}", " ")
	(: if there is an uneven number of angle brackets, delete all angle brackets. :)
	let $query-string := if (
		(functx:number-of-matches($query-string, "<") + functx:number-of-matches($query-string, ">")) mod 2 eq 0
	) then
		$query-string
	else
		translate($query-string, "<>", " ")
	return $query-string
};

(: Function to translate a Lucene search string to an intermediate string mimicking the XML syntax,
with some additions for later parsing of boolean operators. The resulting intermediary XML search string will be parsed as XML with parse-xml().
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/ :)
(: TODO:
The following cases are not covered:
1)
<query><near slop="10"><first end="4">snake</first><term>fillet</term></near></query>
as opposed to
<query><near slop="10"><first end="4">fillet</first><term>snake</term></near></query>

w(..)+d, w[uiaeo]+d is not treated correctly as regex.
 :)
declare %private function app:parse-lucene($string as xs:string) {
	(: replace all symbolic booleans with lexical counterparts :)
	if (matches($string, "[^\\](\|{2}|&amp;{2}|!) ")) then
		let $rep := replace(replace(replace($string, "&amp;{2} ", "AND "), "\|{2} ", "OR "), "! ", "NOT ")
		return app:parse-lucene($rep)
	else (: replace all booleans with '<AND/>|<OR/>|<NOT/>' :) if (matches($string, "[^<](AND|OR|NOT) ")) then
		let $rep := replace($string, "(AND|OR|NOT) ", "<$1/>")
		return app:parse-lucene($rep)
	else (: replace all '+' modifiers in token-initial position with '<AND/>' :) if (
		matches($string, "(^|[^\w&quot;])\+[\w&quot;(]")
	) then
		let $rep := replace($string, "(^|[^\w&quot;])\+([\w&quot;(])", "$1<AND type=_+_/>$2")
		return app:parse-lucene($rep)
	else (: replace all '-' modifiers in token-initial position with '<NOT/>' :) if (
		matches($string, "(^|[^\w&quot;])-[\w&quot;(]")
	) then
		let $rep := replace($string, "(^|[^\w&quot;])-([\w&quot;(])", "$1<NOT type=_-_/>$2")
		return app:parse-lucene($rep)
	else (: replace parentheses with '<bool></bool>' :) (: NB: regex also uses parentheses! :) if (
		matches($string, "(^|[\W-[\\]]|>)\(.*?[^\\]\)(\^(\d+))?(<|\W|$)")
	) then
		let $rep := (: add @boost attribute when string ends in ^\d :)
		(: if (matches($string, '(^|\W|>)\(.*?\)(\^(\d+))(<|\W|$)'))
                            then replace($string, '(^|\W|>)\((.*?)\)(\^(\d+))(<|\W|$)', '$1<bool boost=_$4_>$2</bool>$5')
                            else :) replace($string, "(^|\W|>)\((.*?)\)(<|\W|$)", "$1<bool>$2</bool>$3")
		return app:parse-lucene($rep)
	else (: replace quoted phrases with '<near slop="0"></bool>' :) if (
		matches($string, "(^|\W|>)(&quot;).*?\2([~^]\d+)?(<|\W|$)")
	) then
		let $rep := (: add @boost attribute when phrase ends in ^\d :)
		(: if (matches($string, '(^|\W|>)(&quot;).*?\2([\^]\d+)?(<|\W|$)'))
                                then replace($string, '(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)', '$1<near boost=_$5_>$3</near>$6')
                                (\: add @slop attribute in other cases :\)
                                else :) replace(
			$string,
			"(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)",
			"$1<near slop=_$5_>$3</near>$6"
		)
		return app:parse-lucene($rep)
	else (: wrap fuzzy search strings in '<fuzzy max-edits=""></fuzzy>' :) if (
		matches($string, "[\w-[<>]]+?~[\d.]*")
	) then
		let $rep := replace($string, "([\w-[<>]]+?)~([\d.]*)", "<fuzzy max-edits=_$2_>$1</fuzzy>")
		return app:parse-lucene($rep)
	else (: wrap resulting string in '<query></query>' :)
		concat("<query>", replace(normalize-space($string), "_", '"'), "</query>")
};

(: Function to transform the intermediary structures in the search query generated through app:parse-lucene() and parse-xml()
to full-fledged boolean expressions employing XML query syntax.
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/ :)
declare %private function app:lucene2xml($node as item(), $mode as xs:string) {
	typeswitch ($node)
		case element(query) return
			element {node-name($node)} { element bool { $node/node()/app:lucene2xml(., $mode) } }
		case element(AND) return
			()
		case element(OR) return
			()
		case element(NOT) return
			()
		case element() return
			let $name := if (($node/self::phrase | $node/self::near)[not(@slop > 0)]) then
				"phrase"
			else
				node-name($node)
			return element {$name} {
				$node/@*,
				if (
					($node/following-sibling::*[1] | $node/preceding-sibling::*[1])[self::AND or
						self::OR or
						self::NOT or
						self::bool]
				) then
					attribute occur {
						if ($node/preceding-sibling::*[1][self::AND]) then
							"must"
						else if ($node/preceding-sibling::*[1][self::NOT]) then
							"not"
						else if ($node[self::bool] and $node/following-sibling::*[1][self::AND]) then
							"must"
						else if ($node/following-sibling::*[1][self::AND or self::OR or self::NOT][not(@type)]) then
							"should" (: must? :)
						else
							"should"
					}
				else (
				),
				$node/node()/app:lucene2xml(., $mode)
			}
		case text() return
			if ($node/parent::*[self::query or self::bool]) then
				for $tok at $p in tokenize($node, "\s+")[normalize-space()]
				(: Here the query switches into regex mode based on whether or not characters used in regex expressions are present in $tok. :)(: It is not possible reliably to distinguish reliably between a wildcard search and a regex search, so switching into wildcard searches is ruled out here. :)(: One could also simply dispense with 'term' and use 'regex' instead - is there a speed penalty? :)
				let $el-name := if (matches($tok, "((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)") or $mode eq "regex") then
					"regex"
				else
					"term"
				return element {$el-name} {
					attribute occur {
						(: if the term follows AND :)
						if ($p = 1 and $node/preceding-sibling::*[1][self::AND]) then
							"must"
						else (: if the term follows NOT :) if ($p = 1 and $node/preceding-sibling::*[1][self::NOT]) then
							"not"
						else (: if the term is preceded by AND :) if (
							$p = 1 and $node/following-sibling::*[1][self::AND][not(@type)]
						) then
							"must"
						(: if the term follows OR and is preceded by OR or NOT, or if it is standing on its own :)
						else
							"should"
					},
					(: ,
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)'))
                    then
                        (\:regex searches have to be lower-cased:\)
                        attribute boost {
                            lower-case(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$3'))
                        }
                    else () :)
					(: regex searches have to be lower-cased :)
					lower-case(normalize-space(replace($tok, "(.*?)(\^(\d+))(\W|$)", "$1")))
				}
			else
				normalize-space($node)

		default return
			$node
};

(: function defined by Wicentowski Joe joewiz@gmail.com on exist open mailing list for the Last created document in the collection :)
declare function app:get-latest-created-document($collection-uri as xs:string) as map(*) {
	if (xmldb:collection-available($collection-uri)) then
		let $documents := xmldb:xcollection($collection-uri)!util:document-name(.)
		return if (exists($documents)) then
			let $latest-created := $documents => sort((), xmldb:created($collection-uri, ?)) => subsequence(last())
			return map {
				"collection-uri": $collection-uri,
				"document-name": $latest-created,
				"created": xmldb:created($collection-uri, $latest-created)
			}
		else
			map {"warning": "No child documents in collection " || $collection-uri}
	else
		map {"warning": "No such collection " || $collection-uri}
};

declare function app:worksforclavis($node as node(), $model as map(*), $xpath as xs:string?) {
	let $hits :=
		for $hit in collection($config:data-rootW)//t:TEI[not(ends-with(@xml:id, "IHA"))]
		order by $hit/@xml:id
		return $hit
	return map {"hits": $hits, "path": $xpath}
};

declare %templates:wrap %templates:default("start", 1) %templates:default("per-page", 20) function app:worksclavis(
	$node as node()*,
	$model as map(*),
	$start as xs:integer,
	$per-page as xs:integer
) {
	for $text at $p in subsequence($model("hits"), $start, $per-page)
	let $root := root($text)
	let $id := data($root/t:TEI/@xml:id)
	let $maintitle := exptit:printTitleID($id)
	let $clavis := apptable:clavisIds($root/t:TEI)
	return <div class="w3-row reference" style="margin-bottom:20px;border-bottom: double;">
		<div class="w3-half w3-padding">
			<div class="w3-half w3-padding">
				<span class="w3-tag w3-gray work">{ $id }</span>
				<h3>{ $maintitle }</h3>
				{ $clavis }
			</div>
			<div class="w3-half w3-padding">
				{
					for $title at $t in $text//t:titleStmt/t:title
					let $dv := $id || "TITLE" || $t
					return <div class="row">
						<div class="w3-threequarter w3-padding"><p data-value="{ $dv }">{ $title/text() }</p></div>
						<div class="w3-quarter w3-padding">
							<button class="w3-button w3-red searchthis" data-value="{ $dv }">search this</button>
						</div>
					</div>
				}
			</div>
		</div>
		<div class="w3-half w3-padding">
			<label>Search PATHs/CMCL project data for matching clavis ids for { $id }</label>
			<input class="form-control querystring" id="{ $id }" type="text" />
			<div class="pathsResults" />
		</div>
	</div>
};
