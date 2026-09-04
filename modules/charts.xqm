xquery version "3.1" encoding "UTF-8";

(:~
 : module used by text search query functions to provide alternative
 : strings to the search, based on known homophones.
 :
 : @author Pietro Liuzzo
 :)
module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace fusekisparql = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/sparqlfuseki" at "xmldb:exist:///db/apps/BetMasWeb/fuseki/fuseki.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";

declare variable $charts:computed-subtype := "computed";

(:~
 : Prefer expand-emitted mm @quantity; fall back to cataloguer text for pre-re-expand data.
 :)
declare %private function charts:outer-axis-mm($extent as element(), $axis as xs:string) as xs:string {
	let $computed := $extent/t:dimensions[@subtype = $charts:computed-subtype][@type eq "outer"]
	return if ($computed/*[local-name() = $axis]/@quantity) then
		string($computed/*[local-name() = $axis]/@quantity)
	else
		let $catalogue := $extent/t:dimensions[@type eq "outer"][not(@subtype = $charts:computed-subtype)]
		return if ($catalogue/*[local-name() = $axis]/text()) then
			string-join($catalogue/*[local-name() = $axis]/text(), " ")
		else
			"0"
};

declare %private function charts:layout-written-lines($layout as element(t:layout)) as xs:string {
	let $computed := (
		$layout/following-sibling::t:layout[@subtype = $charts:computed-subtype],
		$layout/preceding-sibling::t:layout[@subtype = $charts:computed-subtype]
	)[1]
	return if ($computed/t:writtenLines/@quantity) then
		string($computed/t:writtenLines/@quantity)
	else if ($layout/@writtenLines) then
		if (contains($layout/@writtenLines, " ")) then
			string(
				avg(
					for $x in tokenize($layout/@writtenLines, " ")
					return number($x)
				)
			)
		else
			string($layout/@writtenLines)
	else
		"0"
};

declare function charts:mssSankey($itemid) {
	let $query := (
		$config:sparqlPrefixes ||
			"
  SELECT DISTINCT ?from ?to ?weight
  WHERE {
          BIND('" ||
			$itemid ||
			"' as ?id)
          {
              ?from sdc:constituteUnit ?to .
              BIND(1 as ?weight)
            }
        UNION
        {
              ?from sdc:undergoesTransformation ?tr .
              ?tr sdc:resultsIn ?to .
              BIND(2 as ?weight)
            }
        UNION
        {
              ?from sdc:undergoesTransformation ?tr .
              ?tr sdc:produces ?to .
              BIND(2 as ?weight)
            }
        UNION
        {
              ?from skos:exactMatch ?to .
              ?to a sdc:UniCirc .
              BIND(4 as ?weight)
            }
  BIND(STR(?from) as ?strform)
  BIND(STR(?to) as ?strto)
  FILTER(contains(?strform, ?id))
  FILTER(contains(?strto, ?id))
   }"
	)

	let $sparqlresults := fusekisparql:query("betamasaheft", $query)
	let $results :=
		for $result in $sparqlresults//sr:result
		let $from := substring-after($result//sr:binding[1]/sr:uri, $config:BMurl)
		let $to := substring-after($result//sr:binding[2]/sr:uri, $config:BMurl)
		let $w := $result//sr:binding[3]/sr:literal
		return '["' || $from || '", "' || $to || '", ' || $w || "]"

	let $table := "[" || string-join($results, ", ") || "]"
	(: https://github.com/google/google-visualization-issues/issues/1657 :)
	return (
		<script src="//cdn.rawgit.com/newrelic-forks/d3-plugins-sankey/master/sankey.js" />,
		<script type="text/javascript">
			{
				"google.charts.load('current', {'packages':['sankey']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = new google.visualization.DataTable();
        data.addColumn('string', 'From');
        data.addColumn('string', 'To');
        data.addColumn('number', 'Weight');
        data.addRows(" ||
					$table ||
					");
     
var options = {
      sankey: {
        node: { label: {
                         bold: true } } },
    };

       var chart = new google.visualization.Sankey(document.getElementById('sankey_basic'));
       chart.draw(data, options);
     }
     "
			}
		</script>,
		<div id="sankey_basic" style="width: 100%; height: 300px;" />
	)
};

declare function charts:pieAttestations($itemid, $name) {
	let $path := "$exptit:col//t:" || $name || "[@ref eq $itemid][text()]"
	let $attestations := util:eval($path)
	let $forms :=
		for $att in $attestations
		let $groupkey := normalize-space(string-join($att/text(), " "))
		group by $gk := $groupkey
		return '["' || $gk || '", ' || count($att) || "]"

	let $table := '[["form","total"],' || string-join($forms, ", ") || "]"

	return (
		<script type="text/javascript">
			{
				'google.charts.load("current", {packages:["corechart"]});
        google.charts.setOnLoadCallback(drawChart);
        function drawChart() {
          var data = google.visualization.arrayToDataTable(' ||
					$table ||
					");

          var options = {
            title: 'percentual breakdown of " ||
					count($attestations) ||
					" attested forms',
          };

          var chart = new google.visualization.PieChart(document.getElementById('piechart" ||
					$itemid ||
					"'));
          chart.draw(data, options);
        }"
			}
		</script>,
		<div id="piechart{ $itemid }" style="width: 100%; height: 500px;" />
	)
};

(:~
 : Every notBefore/notAfter year found on $hit's descendant::t:origDate
 : elements, normalized the same way charts:dateFilter's bucket test
 : compares them (a full date truncated at its first "-", numeric NaN
 : for anything else). Computed once per hit and reused across all 13 of
 : charts:chart's date buckets, instead of each bucket re-scanning every
 : hit's subtree from scratch - that repeated scan measured ~13.6s for
 : 170 hits before this change.
 :
 : @return the candidate years; NaN and blank bounds are already
 : filtered out, since NaN never satisfies charts:dateFilter's range
 : test either way
 :)
declare function charts:hit-years($hit as element()) as xs:double* {
	for $origDate in $hit/descendant::t:origDate
	for $bound in ($origDate/@notBefore, $origDate/@notAfter)
	let $year := if (contains($bound, "-")) then
		substring-before($bound, "-")
	else
		string($bound)
	where $year != ""
	return number($year)
};

(:~
 : Whether any of $hit's origDate years (see charts:hit-years) falls
 : within [$from, $to].
 :
 : @param $years-by-hit generate-id($hit) -> charts:hit-years($hit), built
 : once per charts:chart call and shared across all 13 bucket tests
 :)
declare function charts:dateFilter($from, $to, $hits, $years-by-hit as map(*)) {
	$hits[some $year in $years-by-hit(generate-id(.)) satisfies ($year ge $from and $year le $to)]
};

(:~
 : Escapes a string for safe embedding inside a single- or double-quoted
 : JavaScript string literal built by string concatenation (the pattern
 : every chart-building function in this module uses). Corpus free-text
 : fields (e.g. `t:decoNote` content) routinely carry embedded
 : newlines/indentation from the source TEI's mixed content, which breaks
 : the literal outright rather than just mis-rendering - so whitespace is
 : collapsed, not merely escaped. Also neutralizes `</script` so a value
 : can't terminate the enclosing `<script>` element early.
 :
 : @param $value the raw string to embed; the empty sequence returns ""
 : @return a string safe to concatenate directly inside a JS string literal
 :)
declare function charts:js-string-escape($value as xs:string?) as xs:string {
	let $normalized := normalize-space(($value, "")[1])
	let $backslashesEscaped := replace($normalized, "\\", "\\\\")
	let $quotesEscaped := replace($backslashesEscaped, '"', '\\"')
	return replace($quotesEscaped, "</(script)", "<\\/$1", "i")
};

(:~
 : Shared shape behind charts:chart's 6 support-function chart blocks
 : (sp/spat/TM/BM/OT/MM) - each was ~75-80 duplicated lines: 14
 : per-bucket support-fn calls aggregated into a Google Charts JSON
 : table, plus an almost-identical ColumnChart <script> + wrapper
 : <div>. Only the support function, this family's own per-bucket
 : labels, $values, count, title/axis text, and target div id varied.
 :
 : @param $buckets the 14 date-bucket node-sets (Aks/Paks1/Paks2/Gon/ZaMe/MoPe/1-299/300-599/600-899/900-1199/1200-1499/1500-1799/1800-2099/NotDated, in that order)
 : @param $labels this family's own label text per bucket, same order as $buckets - not unified across families (e.g. the sp block's own "Post-aksumite 2" wording is kept verbatim here rather than forced to match the other 5 blocks' "Post-aksumite II")
 : @param $support-fn ($mss, $rangeName, $values) -> a Google Charts row string, e.g. charts:spsupport#3
 : @param $table-title the JSON table's own first column header
 : @param $chart-title-prefix chart title text before the item count (" manuscripts with this type of data..." is common to all 6 and appended here)
 : @param $vaxis-title the vertical-axis title
 : @param $div-id the target <div>'s id, matched by the <script>'s getElementById call
 : @param $empty-message shown instead of a chart when $count is 0
 :)
declare %private function charts:support-column-chart(
	$buckets as array(*),
	$labels as xs:string*,
	$values as xs:string*,
	$count as xs:integer,
	$support-fn as function (item()*, xs:string, xs:string*) as xs:string?,
	$table-title as xs:string,
	$chart-title-prefix as xs:string,
	$vaxis-title as xs:string,
	$div-id as xs:string,
	$empty-message as xs:string
) as element()* {
	if ($count = 0) then
		<div class="w3-half w3-panel w3-red w3-padding"><p>{ $empty-message }</p></div>
	else
		let $series :=
			for $i in 1 to array:size($buckets)
			return $support-fn($buckets($i), $labels[$i], $values)
		let $headings :=
			for $value in $values
			return ',"' || charts:js-string-escape($value) || '"'
		let $table := '[["' || $table-title || '" ' || string-join($headings) || "]," || string-join($series, ", ") || "]"
		return (
			<script type="text/javascript">
				{
					'
google.charts.load("current", {packages:["corechart"]});
google.charts.setOnLoadCallback(drawChart);
function drawChart() {
var data = google.visualization.arrayToDataTable(
' ||
						$table ||
						'
);

var view = new google.visualization.DataView(data);

var options = { title: "' ||
						$chart-title-prefix ||
						$count ||
						' manuscripts with this type of data in the current results.",
                  isStacked: "percent",
                  height: 300,
                  legend: {position: "top", maxLines: 3},
                  hAxis:{title:"Periods"},
                  vAxis: {
                    title:"' ||
						$vaxis-title ||
						'",
                    minValue: 0,
                    ticks: [0, .25, .5, .75, 1]
                  }
                };
var chart = new google.visualization.ColumnChart(document.getElementById("' ||
						$div-id ||
						'"));
chart.draw(view, options);
}'
				}
			</script>,
			<div class="w3-half" id="{ $div-id }" style="height: 500px;" />
		)
};

declare function charts:chart($hits) {
	let $years-by-hit := map:merge($hits!map:entry(generate-id(.), charts:hit-years(.)))
	let $taglias-by-hit := map:merge($hits!map:entry(generate-id(.), charts:hit-taglias(.)))

	let $mssAks := charts:dateFilter(0300, 0700, $hits, $years-by-hit)
	let $mssPaks1 := charts:dateFilter(1200, 1433, $hits, $years-by-hit)
	let $mssPaks2 := charts:dateFilter(1434, 1632, $hits, $years-by-hit)
	let $mssGon := charts:dateFilter(1632, 1769, $hits, $years-by-hit)
	let $mssZaMe := charts:dateFilter(1769, 1855, $hits, $years-by-hit)
	let $mssMoPe := charts:dateFilter(1855, 1974, $hits, $years-by-hit)

	let $mss1-299 := charts:dateFilter(0001, 0299, $hits, $years-by-hit)
	let $mss300-599 := charts:dateFilter(0300, 0599, $hits, $years-by-hit)
	let $mss600-899 := charts:dateFilter(0600, 0899, $hits, $years-by-hit)
	let $mss900-1199 := charts:dateFilter(0900, 1199, $hits, $years-by-hit)
	let $mss1200-1499 := charts:dateFilter(1200, 1499, $hits, $years-by-hit)
	let $mss1500-1799 := charts:dateFilter(1500, 1799, $hits, $years-by-hit)
	let $mss1800-2099 := charts:dateFilter(1800, 2099, $hits, $years-by-hit)

	let $mssNotDated := $hits[not(descendant::t:origDate)]

	let $countAks := count($mssAks)
	let $t := util:log("info", $countAks)
	let $countPaks1 := count($mssPaks1)
	let $countPaks2 := count($mssPaks2)
	let $countGon := count($mssGon)
	let $countZaMe := count($mssZaMe)
	let $countMoPe := count($mssMoPe)

	let $count1-299 := count($mss1-299)
	let $count300-599 := count($mss300-599)
	let $count600-899 := count($mss600-899)
	let $count900-1199 := count($mss900-1199)
	let $count1200-1499 := count($mss1200-1499)
	let $count1500-1799 := count($mss1500-1799)
	let $count1800-2099 := count($mss1800-2099)

	let $countNotDated := count($mssNotDated)

	let $countmswithSSta := count($hits[descendant::t:decoNote[@type = "SewingStations"]])

	let $t := util:log("info", $countmswithSSta)
	let $spvalues := config:distinct-values($hits//t:decoNote[@type = "SewingStations"])

	let $countmswithSPat := count($hits[descendant::t:term[starts-with(@key, "pattern")]])
	let $spatvalues := config:distinct-values($hits//t:term[starts-with(@key, "pattern")]/@key)

	let $countmswithThreadMat := count(
		$hits[descendant::t:term[ends-with(@key, "Thread") or contains(@key, "tannedSkin")]]
	)
	let $TMvalues := config:distinct-values($hits//t:term[ends-with(@key, "Thread") or contains(@key, "tannedSkin")]/@key)

	let $countmswithbindingMat := count($hits[descendant::t:decoNote[parent::t:binding][t:material]])
	let $BMvalues := config:distinct-values($hits//t:decoNote[parent::t:binding]/t:material/@key)

	let $countmswithMainMat := count($hits[descendant::t:support[t:material]])
	let $MMvalues := config:distinct-values($hits//t:support/t:material/@key)

	let $countmsObjTyp := count($hits[descendant::t:objectDesc])
	let $OTvalues := config:distinct-values($hits//t:objectDesc/@form)

	let $numberQuiresIns := count($hits//t:collation[descendant::t:item])
	let $dimensions := $hits//t:extent[descendant::t:dimensions[@type eq "outer"][t:height][t:width][t:depth]]
	let $units := ($dimensions/t:dimensions[@type eq "outer"]/@unit, $dimensions/t:dimensions[@type eq "outer"]/t:*/@unit)
	let $unit := config:distinct-values($units)
	let $countDim := count($dimensions)
	let $layoutdimensions := $hits//t:layoutDesc/t:layout[descendant::t:dimensions[t:height][t:width]]
	let $countLayout := count($layoutdimensions)

	let $rulingpattern := $hits//t:ab[@type eq "ruling"][@subtype eq "pattern"]
	let $countRulPat := count($rulingpattern)

	(: shared across all 6 charts:support-column-chart calls below - see its own docs :)
	let $date-buckets := [
		$mssAks,
		$mssPaks1,
		$mssPaks2,
		$mssGon,
		$mssZaMe,
		$mssMoPe,
		$mss1-299,
		$mss300-599,
		$mss600-899,
		$mss900-1199,
		$mss1200-1499,
		$mss1500-1799,
		$mss1800-2099,
		$mssNotDated
	]

	return (
		if ($numberQuiresIns ge 1) then (
			if ($numberQuiresIns ge 1050) then (
				<div class="w3-half w3-panel w3-red w3-padding w3-padding">
					<p>
    We think that a chart with data from {
							$numberQuiresIns
						} items would be impossible to read and not useful. Filter your search to limit the number of items, with less then 1000 we will print also the charts.
  </p>
				</div>
			) else
				let $dimensionOfQuiresINS := config:distinct-values($hits//t:collation//t:item/t:dim[@unit eq "leaf"])
				let $percents :=
					for $dim in $dimensionOfQuiresINS
					let $test := $hits//t:collation//t:item
					let $numberQuiresThisDim := count($test/t:dim[@unit eq "leaf"][. = $dim])
					order by $numberQuiresThisDim descending
					return '["' || $dim || ' leaves ", ' || $numberQuiresThisDim || "]"
				let $collations := '[["Composition","Quantity"],' || string-join($percents, ", ") || "]"

				return (
					<script type="text/javascript">
						{
							'google.charts.load("current", {packages:["corechart"]});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable(' ||
								$collations ||
								");

        var options = {
          title: 'Quires Distribution for the " ||
								$numberQuiresIns ||
								" codicological units in this selection which have a collation with quire descriptions',
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart'));
        chart.draw(data, options);
      }"
						}
					</script>,
					<div class="w3-half" id="piechart" style="height: 500px;" />
				)
		) else (
			<div class="w3-half w3-panel w3-red w3-padding">
				<p>There are no collations for this selection of manuscripts.</p>
			</div>
		),
		if ($countDim ge 1) then (
			if ($countDim ge 1050) then (
				<div class="w3-half w3-panel w3-red w3-padding">
					<p>
  We think that a chart with data from {
							$countDim
						} items would be impossible to read and not useful. Filter your search to limit the number of items, with less then 1000 we will print also the graphs.
</p>
				</div>
			) else if (count($unit) gt 1) then (
				<div class="w3-half w3-panel w3-red w3-padding">
					<p
					>Unfortunately we cannot put on a chart the dimensions of the manuscripts, because they are provided using different units of measure ({
							string-join($unit, ", ")
						})</p>
				</div>
			) else
				let $dims :=
					for $d in $dimensions
					let $allwithar := $d/t:dimensions[@type eq "outer"]
					let $all := $allwithar[not(@xml:lang = "ar")]
					let $SM := $d//ancestor::t:TEI//t:msIdentifier/t:idno/text()
					let $title := exptit:printTitle($d)
					let $h := charts:outer-axis-mm($d, "height")
					let $w := charts:outer-axis-mm($d, "width")
					let $dep := charts:outer-axis-mm($d, "depth")
					return '["' || $SM || '",' || $w || "," || $h || ',"' || $title || '",' || $dep || "]"

				let $dimensionsTable := '[["shelf mark","width","height","title","depth"],' || string-join($dims, ", ") || "]"

				let $taglie :=
					for $d in $hits//t:extent[descendant::t:dimensions[@type eq "outer"][t:height][t:width][t:depth]]

					let $allwithar := $d/t:dimensions[@type eq "outer"]
					let $all := $allwithar[not(@xml:lang = "ar")]
					let $h := charts:outer-axis-mm($d, "height")
					let $w := charts:outer-axis-mm($d, "width")
					let $realtaglia := number($h) + number($w)

					let $grouppedtaglia := if ($realtaglia lt 200) then
						"0-200"
					else if (($realtaglia ge 200) and ($realtaglia le 249)) then
						"200-249"
					else if (($realtaglia ge 250) and ($realtaglia le 299)) then
						"250-299"
					else if (($realtaglia ge 300) and ($realtaglia le 349)) then
						"300-349"
					else if (($realtaglia ge 350) and ($realtaglia le 399)) then
						"350-399"
					else if (($realtaglia ge 400) and ($realtaglia le 449)) then
						"400-449"
					else if (($realtaglia ge 450) and ($realtaglia le 499)) then
						"450-499"
					else if (($realtaglia ge 500) and ($realtaglia le 549)) then
						"500-549"
					else if (($realtaglia ge 550) and ($realtaglia le 599)) then
						"550-599"
					else if (($realtaglia ge 600) and ($realtaglia le 649)) then
						"600-649"
					else if (($realtaglia ge 650) and ($realtaglia le 699)) then
						"650-699"
					else
						"700-2000"
					group by $GT := $grouppedtaglia
					order by $GT
					let $from := number(substring-before($GT, "-"))
					let $to := number(substring-after($GT, "-"))
					let $percAks := if ($countAks ge 1) then (
						charts:tagliasupport($mssAks, $countAks, $from, $to, $taglias-by-hit)
					) else
						0
					let $percPaks1 := if ($countPaks1 ge 1) then (
						charts:tagliasupport($mssPaks1, $countPaks1, $from, $to, $taglias-by-hit)
					) else
						0
					let $percPaks2 := if ($countPaks2 ge 1) then (
						charts:tagliasupport($mssPaks2, $countPaks2, $from, $to, $taglias-by-hit)
					) else
						0
					let $percGon := if ($countGon ge 1) then (
						charts:tagliasupport($mssGon, $countGon, $from, $to, $taglias-by-hit)
					) else
						0
					let $percZaMe := if ($countZaMe ge 1) then (
						charts:tagliasupport($mssZaMe, $countZaMe, $from, $to, $taglias-by-hit)
					) else
						0
					let $percMoPe := if ($countMoPe ge 1) then (
						charts:tagliasupport($mssMoPe, $countMoPe, $from, $to, $taglias-by-hit)
					) else
						0

					let $perc1-299 := if ($count1-299 ge 1) then (
						charts:tagliasupport($mss1-299, $count1-299, $from, $to, $taglias-by-hit)
					) else
						0
					let $perc300-599 := if ($count300-599 ge 1) then (
						charts:tagliasupport($mss300-599, $count300-599, $from, $to, $taglias-by-hit)
					) else
						0
					let $perc600-899 := if ($count600-899 ge 1) then (
						charts:tagliasupport($mss600-899, $count600-899, $from, $to, $taglias-by-hit)
					) else
						0
					let $perc900-1199 := if ($count900-1199 ge 1) then (
						charts:tagliasupport($mss900-1199, $count900-1199, $from, $to, $taglias-by-hit)
					) else
						0
					let $perc1200-1499 := if ($count1200-1499 ge 1) then (
						charts:tagliasupport($mss1200-1499, $count1200-1499, $from, $to, $taglias-by-hit)
					) else
						0
					let $perc1500-1799 := if ($count1500-1799 ge 1) then (
						charts:tagliasupport($mss1500-1799, $count1500-1799, $from, $to, $taglias-by-hit)
					) else
						0
					let $perc1800-2099 := if ($count1800-2099 ge 1) then (
						charts:tagliasupport($mss1800-2099, $count1800-2099, $from, $to, $taglias-by-hit)
					) else
						0
					let $percNotDated := if ($countNotDated ge 1) then (
						charts:tagliasupport($mssNotDated, $countNotDated, $from, $to, $taglias-by-hit)
					) else
						0
					return '["' ||
						$GT ||
						'",' ||
						$percAks ||
						"," ||
						$percPaks1 ||
						"," ||
						$percPaks2 ||
						"," ||
						$percGon ||
						"," ||
						$percZaMe ||
						"," ||
						$percMoPe ||
						"," ||
						$perc1-299 ||
						"," ||
						$perc300-599 ||
						"," ||
						$perc600-899 ||
						"," ||
						$perc900-1199 ||
						"," ||
						$perc1200-1499 ||
						"," ||
						$perc1500-1799 ||
						"," ||
						$perc1800-2099 ||
						"," ||
						$percNotDated ||
						"]"
				let $taglieChart :=
				'[["taglia","Aksumite","Post-aksumite I","Post-aksumite II","Gondarine","Zamana Masāfǝnt","Modern Period","I-III","IV-VI","VI-IX","X-XII","XIII-XV","XVI-XVIII","XIX-XXI","not dated"],' ||
					string-join($taglie, ", ") ||
					"]"

				return (
					<script type="text/javascript">
						{
							'google.charts.load("current", {"packages":["corechart"]});
      google.charts.setOnLoadCallback(drawSeriesChart);

    function drawSeriesChart() {

      var data = google.visualization.arrayToDataTable(
      ' ||
								$dimensionsTable ||
								'
      );

      var options = {
        title: "Ratio of dimensions of the ' ||
								$countDim ||
								" codicological units which have all outer dimensions recorded (in " ||
								$unit ||
								') ",
        hAxis: {title: "width"},
        vAxis: {title: "height"},
        bubble: {textStyle: {fontSize: 11}}
      };

      var chart = new google.visualization.BubbleChart(document.getElementById("series_chart_div"));
      chart.draw(data, options);
    }
    '
						}
					</script>,
					<div class="w3-half" id="series_chart_div" style="height: 500px;" />,
					<script type="text/javascript">
						{
							"google.charts.load('current', {'packages':['line']});
      google.charts.setOnLoadCallback(drawChart);

      function drawChart() {
        var data = google.visualization.arrayToDataTable(" ||
								$taglieChart ||
								");

        var options = {
          title: 'Distribution of the size (height + width) as in Maniaci 2012, 486.',
          vAxis:{title:'percentage of manuscripts'},
         hAxis:{title:'size ranges (height + width)'},
          curveType: 'function',
          legend: { position: 'bottom' }
        };

        var chart = new google.visualization.LineChart(document.getElementById('maniaci_chart'));

        chart.draw(data, options);
      }"
						}
					</script>,
					<div class="w3-half" id="maniaci_chart" style="height: 500px;" />
				)
		) else (
			<div class="w3-half w3-panel w3-red w3-padding">
				<p>There are no outer dimensions for this selection of manuscripts.</p>
			</div>
		),
		charts:support-column-chart(
			$date-buckets,
			(
				"Aksumite",
				"Post-aksumite I",
				"Post-aksumite 2",
				"Gondarine",
				"Zamana Masāfǝnt",
				"Modern Period",
				"1-299",
				"300-599",
				"600-899",
				"900-1199",
				"1200-1499",
				"1500-1799",
				"1800-2099",
				"Not Dated"
			),
			$spvalues,
			$countmswithSSta,
			charts:spsupport#3,
			"Sewing stations",
			"Number of sewing Stations by date range for ",
			"percentage of total with number of sewing stations",
			"columnchart_values",
			"There are no sewing stations values for this selection of manuscripts."
		),
		charts:support-column-chart(
			$date-buckets,
			(
				"Aksumite",
				"Post-aksumite I",
				"Post-aksumite II",
				"Gondarine",
				"Zamana Masāfǝnt",
				"Modern Period",
				"1-299",
				"300-599",
				"600-899",
				"900-1199",
				"1200-1499",
				"1500-1799",
				"1800-2099",
				"Not Dated"
			),
			$spatvalues,
			$countmswithSPat,
			charts:spatsupport#3,
			"Sewing Patterns",
			"Sewing Patterns by date range for ",
			"percentage of the total using sewing pattern",
			"columnchart_SPvalues",
			"There are no sewing pattern values for this selection of manuscripts."
		),
		charts:support-column-chart(
			$date-buckets,
			(
				"Aksumite",
				"Post-aksumite I",
				"Post-aksumite II",
				"Gondarine",
				"Zamana Masāfǝnt",
				"Modern Period",
				"1-299",
				"300-599",
				"600-899",
				"900-1199",
				"1200-1499",
				"1500-1799",
				"1800-2099",
				"Not Dated"
			),
			$TMvalues,
			$countmswithThreadMat,
			charts:TMsupport#3,
			"Thread Materials",
			"Thread Materials used by date range for ",
			"percentage of the total using thread material",
			"columnchart_Threadvalues",
			"There are no thread material values for this selection of manuscripts."
		),
		charts:support-column-chart(
			$date-buckets,
			(
				"Aksumite",
				"Post-aksumite I",
				"Post-aksumite II",
				"Gondarine",
				"Zamana Masāfǝnt",
				"Modern Period",
				"1-299",
				"300-599",
				"600-899",
				"900-1199",
				"1200-1499",
				"1500-1799",
				"1800-2099",
				"Not Dated"
			),
			$BMvalues,
			$countmswithbindingMat,
			charts:BMsupport#3,
			(: was "Thread Materials" - a copy-paste leftover from the TM block above, wrong for a Binding Materials chart :)
			"Binding Materials",
			"Binding Materials used by date range  for ",
			"percentage of the total using binding material",
			"columnchart_BMvalues",
			"There are no binding material values for this selection of manuscripts."
		),
		charts:support-column-chart(
			$date-buckets,
			(
				"Aksumite",
				"Post-aksumite I",
				"Post-aksumite II",
				"Gondarine",
				"Zamana Masāfǝnt",
				"Modern Period",
				"1-299",
				"300-599",
				"600-899",
				"900-1199",
				"1200-1499",
				"1500-1799",
				"1800-2099",
				"Not Dated"
			),
			$OTvalues,
			$countmsObjTyp,
			charts:OTsupport#3,
			"Form of support",
			"Form of support used by date range for ",
			"percentage of the total with specific form of support",
			"columnchart_OTvalues",
			"There are no object form values for this selection of manuscripts."
		),
		charts:support-column-chart(
			$date-buckets,
			(
				"Aksumite",
				"Post-aksumite I",
				"Post-aksumite II",
				"Gondarine",
				"Zamana Masāfǝnt",
				"Modern Period",
				"1-299",
				"300-599",
				"600-899",
				"900-1199",
				"1200-1499",
				"1500-1799",
				"1800-2099",
				"Not Dated"
			),
			$MMvalues,
			$countmswithMainMat,
			charts:MMsupport#3,
			"Material",
			"Support Materials used by date range  for ",
			"percentage of the total using support material",
			"columnchart_MMvalues",
			"There are no support material values for this selection of manuscripts."
		),
		if ($countRulPat ge 1) then (
			let $patterns :=
				for $ruling in $rulingpattern
				return <mss>
					<id>{ string($ruling/ancestor::t:TEI/@xml:id) }</id>
					<pattern>{ analyze-string($ruling, "(([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+))") }</pattern>
				</mss>
			let $fullpatterns :=
				for $p in $patterns//s:group[@nr = 1]
				return string-join($p//text())
			let $verticals := $patterns//s:group[@nr = 2]
			let $Hmarginals := $patterns//s:group[@nr = 3]
			let $RectricesMajs := $patterns//s:group[@nr = 4]
			let $Rectrices := $patterns//s:group[@nr = 5]
			return (
				(: pie total diversity distribution :)
				let $distinct-patterns := config:distinct-values($fullpatterns)
				let $matcher :=
					for $p in $patterns
					return string-join($p//s:group[@nr = 1]//text())
				let $data :=
					for $pat in $distinct-patterns
					let $count := count($matcher[. = $pat])
					return '["' || $pat || '", ' || $count || "]"
				let $patts := '[["Ruling Pattern","Quantity"],' || string-join($data, ", ") || "]"

				return (
					<script type="text/javascript">
						{
							'google.charts.load("current", {packages:["corechart"]});
      google.charts.setOnLoadCallback(drawChart);
      function drawChart() {
        var data = google.visualization.arrayToDataTable(' ||
								$patts ||
								");

        var options = {
          title: 'Diversity of Ruling Pattern on " ||
								$countRulPat ||
								" manuscripts, based on ANALYSE DES RÉGLURES by D. MUZERELLE.',
        };

        var chart = new google.visualization.PieChart(document.getElementById('piechart_ruling'));
        chart.draw(data, options);
      }"
						}
					</script>,
					<div class="w3-half" id="piechart_ruling" style="height: 500px;" />
				),
				for $formulaZone in 2 to 5
				return (: column charts :) (: Zone I = 2= verticals :) (: ZoneII = 3= Horizontal marginals :) (: Zone III = 4=Rectrices Majeures :) (: Zone IV = 5=Rectices :) let $RPZvalues :=
					config:distinct-values($patterns//s:group[@nr = $formulaZone])
					let $formulaZoneName := switch ($formulaZone)
						case 2 return
							"Zone I (Verticales)"
						case 3 return
							"Zone II (Horizontales marginales)"
						case 4 return
							"Zone III (Rectrices majeures)"
						case 5 return
							"Zone IV (Rectrices)"
						default return
							""
					let $RPZAks := charts:RulingSupport($mssAks, "Aksumite", $RPZvalues, $formulaZone)
					let $RPZPaks1 := charts:RulingSupport($mssPaks1, "Post-aksumite I", $RPZvalues, $formulaZone)
					let $RPZPaks2 := charts:RulingSupport($mssPaks2, "Post-aksumite II", $RPZvalues, $formulaZone)
					let $RPZGon := charts:RulingSupport($mssGon, "Gondarine", $RPZvalues, $formulaZone)
					let $RPZZaMe := charts:RulingSupport($mssZaMe, "Zamana Masāfǝnt", $RPZvalues, $formulaZone)
					let $RPZMoPe := charts:RulingSupport($mssMoPe, "Modern Period", $RPZvalues, $formulaZone)
					let $RPZ1-299 := charts:RulingSupport($mss1-299, "1-299", $RPZvalues, $formulaZone)
					let $RPZ300-599 := charts:RulingSupport($mss300-599, "300-599", $RPZvalues, $formulaZone)
					let $RPZ600-899 := charts:RulingSupport($mss600-899, "600-899", $RPZvalues, $formulaZone)
					let $RPZ900-1199 := charts:RulingSupport($mss900-1199, "900-1199", $RPZvalues, $formulaZone)
					let $RPZ1200-1499 := charts:RulingSupport($mss1200-1499, "1200-1499", $RPZvalues, $formulaZone)
					let $RPZ1500-1799 := charts:RulingSupport($mss1500-1799, "1500-1799", $RPZvalues, $formulaZone)
					let $RPZ1800-2099 := charts:RulingSupport($mss1800-2099, "1800-2099", $RPZvalues, $formulaZone)
					let $RPZNotDated := charts:RulingSupport($mssNotDated, "Not Dated", $RPZvalues, $formulaZone)
					let $RulingPatterns := (
						$RPZAks,
						$RPZPaks1,
						$RPZPaks2,
						$RPZGon,
						$RPZZaMe,
						$RPZMoPe,
						$RPZ1-299,
						$RPZ300-599,
						$RPZ600-899,
						$RPZ900-1199,
						$RPZ1200-1499,
						$RPZ1500-1799,
						$RPZ1800-2099,
						$RPZNotDated
					)
					let $headings :=
						for $value in $RPZvalues
						return ',"' || charts:js-string-escape($value) || '"'
					let $RPZColumnChart := '[["Ruling Pattern ' ||
						$formulaZoneName ||
						'" ' ||
						string-join($headings) ||
						"]," ||
						string-join($RulingPatterns, ", ") ||
						"]"
					return (
						<script type="text/javascript">
							{
								'
google.charts.load("current", {packages:["bar"]});
google.charts.setOnLoadCallback(drawChart);
function drawChart() {
var data = google.visualization.arrayToDataTable(
' ||
									$RPZColumnChart ||
									'
);

var view = new google.visualization.DataView(data);

var options = { title: "Ruling pattern ' ||
									$formulaZoneName ||
									" by date range  for " ||
									$countRulPat ||
									' patterns registered in the current results."
                 
                };
var chart = new google.visualization.ColumnChart(document.getElementById("columnchart_ruling' ||
									$formulaZone ||
									'"));
chart.draw(data, google.charts.Bar.convertOptions(options));
}'
							}
						</script>,
						<div class="w3-half" id="columnchart_ruling{ $formulaZone }" style="height: 500px;" />
					)
			)
		) else (
			<div class="w3-half w3-panel w3-red w3-padding">
				<p>There are no Ruling Patterns for this selection of manuscripts.</p>
			</div>
		),
		if ($countLayout ge 1) then (
			let $dims :=
				for $d in $layoutdimensions

				let $allwithar := $d/t:dimensions[@type eq "outer"]
				let $all := $allwithar[not(@xml:lang = "ar")]
				let $SM := string-join($d/ancestor::t:TEI//t:msIdentifier/t:idno/text(), " / ")
				let $title := exptit:printTitle($d)
				let $h := charts:outer-axis-mm($d, "height")
				let $w := charts:outer-axis-mm($d, "width")
				let $writtenlines := charts:layout-written-lines($d)
				return '["' || $SM || '",' || $w || "," || $h || ',"' || $title || '", ' || $writtenlines || "]"

			let $dimensionsTable := '[["shelf mark","width","height","title","written lines"],
    ' ||
				string-join($dims, ",
    ") ||
				"]"

			return (
				<script type="text/javascript">
					{
						'google.charts.load("current", {"packages":["corechart"]});
      google.charts.setOnLoadCallback(drawSeriesChart);

    function drawSeriesChart() {

      var data = google.visualization.arrayToDataTable(
      ' ||
							$dimensionsTable ||
							'
      );

      var options = {
        title: "Ratio of writing area dimensions of the ' ||
							$countLayout ||
							' manuscripts which have layout dimensions recorded. One bubble for each such layout encoded, so, possibly more then one for each manuscript. ",
        hAxis: {title: "width"},
        vAxis: {title: "height"},
        bubble: {textStyle: {fontSize: 11}}
      };

      var chart = new google.visualization.BubbleChart(document.getElementById("series_chart_div_layout"));
      chart.draw(data, options);
    }
    '
					}
				</script>,
				<div class="w3-half" id="series_chart_div_layout" style="height: 500px;" />
			)
		) else (
			<div class="w3-half w3-panel w3-red w3-padding">
				<p>There are no manuscript with layout dimensions for this selection of manuscripts.</p>
			</div>
		)
	)
};

(:~
 : Every matching extent's height+width (mm) on $hit - "matching" being
 : descendant::t:dimensions[@type eq "outer"][t:height][t:width][t:depth],
 : the same predicate charts:tagliasupport used to re-apply on every one
 : of its ~168 calls per results page (13 date buckets x up to 12 taglia
 : groups). Computed once per hit and reused across all of them - that
 : repeated rescan measured ~12.6s of a ~13.8s charts:chart call for 170
 : hits.
 :
 : @return one value per matching extent (a hit with several counts
 : several times, same as the original scan)
 :)
declare function charts:hit-taglias($hit as element()) as xs:double* {
	for $extent in $hit//t:extent[descendant::t:dimensions[@type eq "outer"][t:height][t:width][t:depth]]
	let $h := charts:outer-axis-mm($extent, "height")
	let $w := charts:outer-axis-mm($extent, "width")
	return number($h) + number($w)
};

(:~
 : Share of $mssDate's matching extents (see charts:hit-taglias) whose
 : height+width falls within [$from, $to], out of $totcount.
 :
 : @param $taglias-by-hit generate-id($hit) -> charts:hit-taglias($hit),
 : built once per charts:chart call and shared across every bucket/group
 : pair
 :)
declare function charts:tagliasupport($mssDate, $totcount, $from, $to, $taglias-by-hit as map(*)) {
	let $mssDateThisTaglia := sum(
		for $ms in $mssDate
		for $taglia in $taglias-by-hit(generate-id($ms))
		where $taglia ge $from and $taglia le $to
		return 1
	)
	let $div := ($mssDateThisTaglia div $totcount)
	return format-number($div, "#.#")
};

(:~
 : Shared shape behind spsupport/spatsupport/TMsupport/BMsupport/
 : MMsupport/OTsupport: what fraction of $mss's matching elements have
 : each of $values, as a Google Charts row string. Each of the 6
 : wrappers below differed only in $selector (which elements count as
 : "this period's data") and $match (how a candidate value is tested
 : against them) - was ~14 duplicated lines per wrapper (84 total).
 :
 : @param $selector $mss -> the elements to count against
 : @param $match ($selector's result, one candidate value) -> the subset matching that value
 :)
declare %private function charts:support(
	$mss,
	$rangeName,
	$values,
	$selector as function (item()*) as node()*,
	$match as function (node()*, xs:string) as node()*
) {
	let $mssthisperiod := $selector($mss)
	return if (count($mssthisperiod) = 0) then (
	) else
		let $total := count($mssthisperiod)
		let $columns :=
			for $value in $values
			let $countms := count($match($mssthisperiod, $value))
			let $div := ($countms div $total)
			let $perc := format-number($div, "#.#")
			return "," || $perc
		return '["' || $rangeName || '"' || string-join($columns) || "]"
};

declare function charts:spsupport($mss, $rangeName, $values) {
	charts:support(
		$mss,
		$rangeName,
		$values,
		function ($m) { $m//t:decoNote[@type eq "SewingStations"] },
		function ($set, $value) { $set[. = $value] }
	)
};

declare function charts:spatsupport($mss, $rangeName, $values) {
	charts:support(
		$mss,
		$rangeName,
		$values,
		function ($m) { $m//t:decoNote[t:term[contains(@key, "pattern")]] },
		function ($set, $value) { $set/t:term[@key eq $value] }
	)
};

declare function charts:TMsupport($mss, $rangeName, $values) {
	charts:support(
		$mss,
		$rangeName,
		$values,
		function ($m) { $m//t:decoNote[t:term[ends-with(@key, "Thread") or contains(@key, "tannedSkin")]] },
		function ($set, $value) { $set/t:term[@key eq $value] }
	)
};

declare function charts:BMsupport($mss, $rangeName, $values) {
	charts:support(
		$mss,
		$rangeName,
		$values,
		function ($m) { $m//t:decoNote[parent::t:binding][t:material] },
		function ($set, $value) { $set/t:material[@key eq $value] }
	)
};

declare function charts:MMsupport($mss, $rangeName, $values) {
	charts:support(
		$mss,
		$rangeName,
		$values,
		function ($m) { $m//t:support[t:material] },
		function ($set, $value) { $set/t:material[@key eq $value] }
	)
};

declare function charts:OTsupport($mss, $rangeName, $values) {
	charts:support(
		$mss,
		$rangeName,
		$values,
		function ($m) { $m//t:objectDesc },
		function ($set, $value) { $set[@form eq $value] }
	)
};

declare function charts:RulingSupport($DatedMSS, $rangeName, $values, $formulaZone) {
	let $mssthisperiod := $DatedMSS//t:ab[@type eq "ruling"][@subtype eq "pattern"]
	let $patterns :=
		for $ruling in $mssthisperiod
		return <mss>
			<id>{ string($ruling/ancestor::t:TEI/@xml:id) }</id>
			<pattern>{ analyze-string($ruling, "(([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+))") }</pattern>
		</mss>

	return if (count($mssthisperiod) = 0) then (
	) else
		let $columns :=
			for $value in $values
			let $countms := count($patterns[descendant::s:group[@nr = $formulaZone][. = $value]])
			return "," || $countms
		return '["' || $rangeName || '"' || string-join($columns) || "]"
};
