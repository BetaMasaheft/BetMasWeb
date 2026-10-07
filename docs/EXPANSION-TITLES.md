# Expansion and render resolve titles from different collections

Expansion bakes title text into `/db/apps/expanded` by resolving ids against the
**source** collection, `/db/apps/BetMasData`. Rendering re-resolves the same ids
against the **expanded** collection. The two lookups can disagree, so a title
rendered on a page can differ from the text already written into the expanded
document, or come back empty. Nothing in either module records that they must
agree.

## The two chains

**Expansion time** — resolves against source:

- `modules/expand.xqm:1202` `expand:printTitleMainID` → `titles:printTitleMainID`
- `modules/expand.xqm:1198` `expand:teiTitle` → `titles:printTitleID`
- both land in `modules/titlesData.xqm`, whose `$titles:collection-root` is
  `collection($config:bmdata-root)` (`titlesData.xqm:39`) = `/db/apps/BetMasData`
  (`config.xqm:154`)

`expand:xqm` writes its output to `$config:data-root` = `/db/apps/expanded`
(`config.xqm:156`).

**Render time** — resolves against expanded:

- `modules/exptit.xqm:131` `exptit:printTitleID` → `catalog:label`
- `modules/catalog.xqm:218` `catalog:label` dispatches on
  `catalog:backend("exptit")`; the default `legacy` backend
- `modules/catalog-legacy.xqm` `legacy:label` resolves `@xml:id` against
  `$legacy:col` = `collection($config:data-root)` (`catalog-legacy.xqm:26`) —
  lines 112, 141, 162 and 164

So the same `@xml:id` is looked up in `BetMasData` while expanding and in
`expanded` while rendering.

The subtitle _rule_ is already shared: `catalog-selectors.xqm` is used by both
`titlesData` and `exptit`, and the comment at `exptit.xqm:145-148` says so
("only the id resolver differs"). The divergence is entirely in which
collection the id is looked up in.

## Why they can disagree

Stated as reasoning from the code, not as observed output — see "Not
demonstrated" below.

1. **The source lookup almost always succeeds where the expanded one may not.**
   Every record that can be cross-referenced is in `BetMasData` by
   construction, so expansion resolves it. The expanded twin may not exist yet,
   or may exist under a different id shape, at the moment the page is rendered
   or re-resolved. This is the asymmetry that makes expansion look correct in
   its own output while the rendered page disagrees.

2. **`#`-subid handling diverges by construction.** `titles:printTitleID`
   (`titlesData.xqm:198-220`) resolves `$mainID` in the source, then looks for
   `//t:title[@xml:id = $SUBid]` inside that node, and for a non-`t` subid calls
   `titles:printSubtitle` and `titles:updateTUList` — a DB write, the
   `titlesData` exception already recorded in `CATALOG.md`. `legacy:label`
   (`catalog-legacy.xqm:141`) resolves the same `$mainID` in expanded and looks
   for the subid there. Expansion inserts generated titles and ids, so a subid
   that is present in the source is not guaranteed to be present in the
   expanded copy, and the render-time lookup has no equivalent TUList
   fallback.

3. **The TUList is a source-side side channel with no render-side
   equivalent.** A `#`-subid id can resolve at render time only because an
   earlier call recorded it. Clearing or refreshing the list changes what
   renders without any change to the expanded data.

## Not demonstrated

No failing case has been reproduced. The divergence is established by reading
the two chains, not by a test or a user report. Before acting on this, confirm
a concrete id that renders one way and expands another — the natural candidates
are `#`-subid references (`LIT1367Exodus#Ex1`, `PRS5684JesusCh#n2`, both already
used as fixtures at `exptit.xqm:127-128`) and cross-references to records that
have no expanded twin.

This is filed as a suspected defect, not a confirmed one. It is plausibly
related to the "empty titles" reports, but that link is a hypothesis and has not
been checked against the tracker.

## Direction of a fix

Unify the resolver rather than teaching each side about the other. Either:

- give `legacy:label` (and `exptit:printTitleID`) a source fallback for ids
  absent from expanded, so render resolves on the same collection expansion did;
  or
- have expansion resolve through `catalog:label`, so there is one resolver and
  one collection behind it.

The first is the smaller change and preserves current render output for ids that
do exist in expanded. The second removes the class of bug but makes expansion
depend on the expanded collection being populated, which is the ordering
constraint that made the split attractive in the first place. Neither is
implemented here.

## Tests

`test/xqs/ts-queries-idscan.xqm` covers the id-fragment guards in
`modules/queries.xqm` (`q:bmid`, `q:clavis`) and is unrelated to this. A
regression test for the divergence would need a fixture id that resolves
differently in the two collections, which is the thing to identify first.
