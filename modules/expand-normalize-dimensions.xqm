xquery version "3.1";

module namespace expandnorm = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/expand-normalize-dimensions";

declare namespace t = "http://www.tei-c.org/ns/1.0";

declare variable $expandnorm:computed-subtype := "computed";

declare variable $expandnorm:mm-unit := "mm";

(:~
 : Add computed @subtype siblings for indexable physical measurements (Schema #45).
 : @param $tei expanded TEI root
 : @return TEI with computed dimensions/layout siblings inserted
 :)
declare function expandnorm:normalize-tei($tei as element(t:TEI)) as element(t:TEI) {
	let $normalized := expandnorm:normalize-node(expandnorm:strip-computed($tei))
	return typeswitch ($normalized)
		case element(t:TEI) return
			$normalized

		default return
			error((), "expandnorm:normalize-tei: expected TEI root")
};

(:~
 : Remove expand-derived blocks before re-derive (idempotent re-expand).
 :)
declare function expandnorm:strip-computed($tei as element(t:TEI)) as element(t:TEI) {
	let $stripped := expandnorm:strip-computed-node($tei)
	return typeswitch ($stripped)
		case element(t:TEI) return
			$stripped

		default return
			error((), "expandnorm:strip-computed: expected TEI root")
};

declare function expandnorm:strip-computed-node($node as node()) as node()? {
	typeswitch ($node)
		case element(t:dimensions) return
			if ($node/@subtype = $expandnorm:computed-subtype) then (
			) else
				element {node-name($node)} {
					$node/@*,
					for $child in $node/node()
					return expandnorm:strip-computed-node($child)
				}
		case element(t:layout) return
			if ($node/@subtype = $expandnorm:computed-subtype) then (
			) else
				element {node-name($node)} {
					$node/@*,
					for $child in $node/node()
					return expandnorm:strip-computed-node($child)
				}
		case element() return
			element {node-name($node)} {
				$node/@*,
				for $child in $node/node()
				return expandnorm:strip-computed-node($child)
			}

		default return
			$node
};

declare function expandnorm:normalize-node($node as node()) as node() {
	typeswitch ($node)
		case element(t:layoutDesc) return
			expandnorm:normalize-layoutDesc($node)
		case element(t:layout) return
			expandnorm:normalize-layout($node)
		case element(t:extent) return
			expandnorm:normalize-dimension-children($node)
		case element() return
			element {node-name($node)} {
				$node/@*,
				for $child in $node/node()
				return expandnorm:normalize-node($child)
			}

		default return
			$node
};

declare function expandnorm:normalize-layoutDesc($node as element(t:layoutDesc)) as element(t:layoutDesc) {
	element {node-name($node)} {
		$node/@*,
		for $child in $node/node()
		return typeswitch ($child)
			case element(t:layout) return
				(expandnorm:normalize-layout($child), expandnorm:computed-layout($child))

			default return
				expandnorm:normalize-node($child)
	}
};

declare function expandnorm:normalize-layout($node as element(t:layout)) as element(t:layout) {
	expandnorm:normalize-dimension-children(
		element {node-name($node)} {
			$node/@*,
			for $child in $node/node()
			return if ($child instance of element(t:dimensions)) then
				$child
			else
				expandnorm:normalize-node($child)
		}
	)
};

declare function expandnorm:normalize-dimension-children($node as element()) as element() {
	element {node-name($node)} {
		$node/@*,
		for $child in $node/node()
		return typeswitch ($child)
			case element(t:dimensions) return
				($child, expandnorm:computed-dimensions($child))

			default return
				expandnorm:normalize-node($child)
	}
};

declare function expandnorm:computed-dimensions($src as element(t:dimensions)) as element(t:dimensions)? {
	if ($src/@subtype = $expandnorm:computed-subtype) then (
	) else
		let $block-unit := string($src/@unit)
		let $children := (
			for $axis in $src/(t:height | t:width | t:depth)
			let $built := expandnorm:computed-axis($axis, $block-unit)
			where exists($built)
			return $built,
			for $dim in $src/t:dim
			let $built := expandnorm:computed-dim($dim, $block-unit)
			where exists($built)
			return $built
		)
		return if (exists($children)) then
			<dimensions
				xmlns="http://www.tei-c.org/ns/1.0"
				subtype="{ $expandnorm:computed-subtype }"
				unit="{ $expandnorm:mm-unit }"
			>
				{
					if ($src/@type) then
						attribute type { string($src/@type) }
					else (
					)
				}
				{ $children }
			</dimensions>
		else (
		)
};

declare function expandnorm:computed-layout($src as element(t:layout)) as element(t:layout)? {
	if ($src/@subtype = $expandnorm:computed-subtype) then (
	) else
		let $writtenLines := expandnorm:normalize-written-lines(string($src/@writtenLines))
		return if ($writtenLines) then
			<layout
				xmlns="http://www.tei-c.org/ns/1.0"
				subtype="{ $expandnorm:computed-subtype }"
				type="catalogue"
				writtenLines="{ $writtenLines }"
			>
				{
					if ($src/@columns) then
						attribute columns { string($src/@columns) }
					else (
					)
				}
			</layout>
		else (
		)
};

declare function expandnorm:computed-axis($axis as element(), $block-unit as xs:string) as element()? {
	expandnorm:computed-measure($axis, $block-unit, local-name($axis))
};

declare function expandnorm:computed-dim($dim as element(t:dim), $block-unit as xs:string) as element(t:dim)? {
	let $built := expandnorm:computed-measure($dim, $block-unit, "dim")
	return if (exists($built)) then
		element {fn:QName("http://www.tei-c.org/ns/1.0", "dim")} {
			if ($dim/@type) then
				attribute type { string($dim/@type) }
			else (
			),
			$built/@*
		}
	else (
	)
};

declare function expandnorm:computed-measure(
	$el as element(),
	$block-unit as xs:string,
	$name as xs:string
) as element()? {
	let $text := normalize-space(string($el))
	return if ($text = "" or expandnorm:is-unparseable($text)) then (
	) else
		let $parsed := expandnorm:parse-measure($text, $block-unit)
		let $lo := (
			if ($el/@atLeast castable as xs:double) then
				expandnorm:to-mm(xs:double($el/@atLeast), $block-unit)
			else
				$parsed?atLeast
		)
		let $hi := (
			if ($el/@atMost castable as xs:double) then
				expandnorm:to-mm(xs:double($el/@atMost), $block-unit)
			else
				$parsed?atMost
		)
		let $qty := if ($lo and $hi) then
			($lo + $hi) div 2
		else
			$parsed?quantity
		return if (exists($qty)) then
			element {fn:QName("http://www.tei-c.org/ns/1.0", $name)} {
				attribute quantity { $qty },
				attribute unit { $expandnorm:mm-unit },
				if ($lo) then
					attribute atLeast { $lo }
				else (
				),
				if ($hi) then
					attribute atMost { $hi }
				else (
				)
			}
		else (
		)
};

declare function expandnorm:parse-measure($text as xs:string, $block-unit as xs:string) as map(*)? {
	let $normalized := normalize-space(replace($text, ",", "."))
	let $compact := replace($normalized, "\s*-\s*", "-")
	return if (contains($compact, "-")) then
		let $parts := tokenize($compact, "-")
		let $lo := expandnorm:parse-number($parts[1])
		let $hi := expandnorm:parse-number($parts[2])
		return if (exists($lo) and exists($hi)) then
			map {
				"atLeast": expandnorm:to-mm($lo, $block-unit),
				"atMost": expandnorm:to-mm($hi, $block-unit),
				"quantity": expandnorm:to-mm(($lo + $hi) div 2, $block-unit)
			}
		else (
		)
	else
		let $numeric := replace($compact, "[^0-9.\-].*$", "")
		let $n := if ($numeric castable as xs:double) then
			xs:double($numeric)
		else (
		)
		return if (exists($n)) then
			map {"quantity": expandnorm:to-mm($n, $block-unit)}
		else (
		)
};

declare function expandnorm:parse-number($text as xs:string) as xs:double? {
	let $t := normalize-space(replace($text, ",", "."))
	return if ($t castable as xs:double) then
		xs:double($t)
	else (
	)
};

declare function expandnorm:to-mm($value as xs:double, $unit as xs:string?) as xs:double {
	switch (normalize-space($unit))
		case "cm" return
			$value * 10
		case "in" return
			$value * 25.4
		default return
			$value
};

declare function expandnorm:normalize-written-lines($value as xs:string) as xs:string? {
	let $trimmed := normalize-space($value)
	let $parts := tokenize($trimmed, "\s+")
	return if (count($parts) = 2 and ($parts[1] castable as xs:integer) and ($parts[2] castable as xs:integer)) then
		string(max((xs:integer($parts[1]), xs:integer($parts[2]))))
	else if ($trimmed castable as xs:integer) then
		$trimmed
	else (
	)
};

declare function expandnorm:is-unparseable($text as xs:string) as xs:boolean {
	matches(normalize-space($text), "^\s*ca\.", "i")
};
