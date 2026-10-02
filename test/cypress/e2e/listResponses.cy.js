// resources/js/listResponse.js and the consumers it was extracted for.
//
// Every consumer below hit the same class of bug: the API reports a true
// `total` across the whole corpus but only sends a bounded slice, and a
// response holding exactly one entry serialises as a bare object rather than
// a one-element array. Looping `for (i = 0; i < data.total; i++)` therefore
// ran off the end of the array and threw on the first missing index, leaving
// the widget empty.
//
// The array is what arrived; `truncated` says why it is short; only the array
// may drive a loop. listItems() is the one place that reconciles the two.
//
// These use cy.intercept() with synthetic payloads rather than live queries:
// the bugs need `total` to exceed the number of entries returned, or exactly
// one entry to be returned - both shapes the corpus cannot be relied on to
// produce on demand.

// The helper has to be loaded on every page that runs a consumer, or the
// consumers fail at call time with "listItems is not defined" - which no unit
// test on the helper would catch. The failure it prevents is silent: the page
// loads, the widget just never updates.
//
// Only the pages this container can serve are covered. Item pages redirect to
// a host-root path outside the app mount, so the versions.js / samerole.js /
// allattestations.js / relatedItems.js / hypothesis.js include in
// scriptlinks:ItemFooterScript() cannot be asserted here at all - not by these
// specs and not by XQSuite, since that function needs a request object the test
// runner has no way to supply. Those five consumers are covered by the listItems
// unit tests below; the include itself is unverified in CI and should be
// re-checked by hand against a real item page.
describe("the listResponse helper is loaded wherever its consumers run", () => {
	const HELPER = "resources/js/listResponse.js";
	const PAGES = [
		["advanced search", "/as.html?work-types=mss", ["lookup.js", "filters.js"]],
		["search results", "/newSearch.html?searchType=text&query=Mary", ["filters.js"]],
	];

	PAGES.forEach(([label, url, consumers]) => {
		it(`${label} loads listResponse.js ahead of ${consumers.join(", ")}`, () => {
			cy.request({
				url,
				failOnStatusCode: false,
				timeout: 60000,
			}).then((res) => {
				expect(res.status, `responded with ${res.status}`).to.eq(200);

				const helperAt = res.body.indexOf(HELPER);
				expect(helperAt, `${url} never loads ${HELPER}`).to.be.greaterThan(-1);

				// match the full path: a bare "versions.js" also matches inside
				// "dateConversions.js", which hides the very regression asserted here
				for (const consumer of consumers) {
					const consumerAt = res.body.indexOf(`resources/js/${consumer}`);
					expect(consumerAt, `${url} does not load ${consumer}`).to.be.greaterThan(-1);
					expect(consumerAt, `${consumer} loads before ${HELPER} and would call listItems undefined`).to.be.greaterThan(
						helperAt,
					);
				}
			});
		});
	});
});

const ONE_ITEM = { id: "LitNumberedTitleAbbrev_Sol", title: "One manuscript" };
const TWO_ITEMS = [
	{ id: "LitNumberedTitleAbbrev_Jar", title: "First manuscript" },
	{ id: "LitNumberedTitleAbbrev_Kas", title: "Second manuscript" },
];

describe("listItems", () => {
	beforeEach(() => {
		cy.visit("/as.html?target-ins=1");
	});

	it("wraps a bare object, the shape eXist gives a one-entry sequence", () => {
		cy.window().then((win) => {
			const items = win.listItems(ONE_ITEM);
			expect(items).to.have.length(1);
			expect(items[0].id).to.eq(ONE_ITEM.id);
			expect(items[0].title).to.eq(ONE_ITEM.title);
		});
	});

	it("passes an array through unchanged and leaves the entries alone", () => {
		cy.window().then((win) => {
			const items = win.listItems(TWO_ITEMS);
			expect(items).to.have.length(2);
			expect(items).to.deep.eq(TWO_ITEMS);
		});
	});

	it("treats a missing or null list as empty rather than undefined", () => {
		cy.window().then((win) => {
			expect(win.listItems(null)).to.deep.eq([]);
			expect(win.listItems(undefined)).to.deep.eq([]);
			expect(win.listItems()).to.deep.eq([]);
			// an omitted key reads as undefined
			expect(win.listItems({}.items)).to.deep.eq([]);
		});
	});

	it("is safe to loop over whatever the server sent", () => {
		// the actual failure mode: total is far larger than what arrived
		cy.window().then((win) => {
			const data = { total: 20386, returned: 2, truncated: true, items: TWO_ITEMS };
			const seen = [];
			for (let i = 0; i < win.listItems(data.items).length; i++) {
				seen.push(win.listItems(data.items)[i].id);
			}
			expect(seen).to.deep.eq(TWO_ITEMS.map((m) => m.id));
		});
	});
});

describe("filters.js institution manuscript dropdown", () => {
	// #target-ins and #target-ms only render once the institutions facet is
	// requested; see app:includeInstitutionsForm in modules/app.xqm.
	const PAGE = "/as.html?target-ins=1";

	// the facet is often already showing one value, and re-selecting the
	// selected option fires no change event - move to a different one
	function chooseInstitution() {
		cy.get("#target-ins").then(($sel) => {
			const $other = $sel.find("option").not(":selected").first();
			if ($other.length) {
				$sel.val($other.val()).trigger("change");
			} else {
				$sel.trigger("change");
			}
		});
	}

	it("renders the manuscripts that arrived, not every manuscript counted", () => {
		// perpage caps the response while total counts the whole repository
		cy.intercept("GET", "**/api/manuscripts/list/json**", {
			body: { total: 20386, items: TWO_ITEMS },
		}).as("manuscripts");
		cy.visit(PAGE);
		chooseInstitution();

		cy.wait("@manuscripts");
		cy.get("#target-ms option").should("have.length", 2);
		cy.get("#target-ms option").eq(0).should("have.attr", "value", TWO_ITEMS[0].id);
		cy.get("#target-ms option").eq(1).should("have.attr", "value", TWO_ITEMS[1].id);
	});

	it("renders one manuscript when the single entry arrives as a bare object", () => {
		cy.intercept("GET", "**/api/manuscripts/list/json**", {
			body: { total: 1, items: ONE_ITEM },
		}).as("manuscripts");
		cy.visit(PAGE);
		chooseInstitution();

		cy.wait("@manuscripts");
		cy.get("#target-ms option").should("have.length", 1);
		cy.get("#target-ms option").should("have.attr", "value", ONE_ITEM.id);
	});

	it("leaves the dropdown empty when the repository has no manuscripts", () => {
		cy.intercept("GET", "**/api/manuscripts/list/json**", {
			body: { total: 0, items: [] },
		}).as("manuscripts");
		cy.visit(PAGE);
		chooseInstitution();

		cy.wait("@manuscripts");
		cy.get("#target-ms option").should("have.length", 0);
	});
});

describe("lookup.js title search", () => {
	// #GoTo only queries /api/idlookup while the "ID" radio (value 1) is
	// selected; "Title" (value 2) switches to /api/search, which is the other
	// endpoint that now reports a bounded result set.
	function suggestTitle(needle) {
		cy.visit("/as.html?work-types=mss");
		cy.get('input[name="AttestedInType"][value="2"]').check({ force: true });
		cy.get("#GoTo").type(needle).blur();
	}

	it("says how many matches it withheld when the search was capped", () => {
		cy.intercept("GET", "**/api/search**", {
			body: { total: 2318, returned: 2, truncated: true, items: TWO_ITEMS },
		}).as("titleSearch");
		suggestTitle("manuscript");

		cy.wait("@titleSearch");
		cy.get("#gotohits option").should("have.length", 3); // notice + 2 titles
		cy.get("#gotohits option").first().should("have.attr", "disabled");
		cy.get("#gotohits option").first().should("contain", "showing first 2 of 2318 matches");
		cy.get("#gotohits option:not([disabled])").each(($opt) => {
			expect($opt.attr("value"), "title suggestion has no id").to.match(/^[\w-]+$/);
		});
	});

	it("shows a single title hit without a truncation notice", () => {
		cy.intercept("GET", "**/api/search**", {
			body: { total: 1, returned: 1, truncated: false, items: ONE_ITEM },
		}).as("titleSearch");
		suggestTitle("manuscript");

		cy.wait("@titleSearch");
		cy.get("#gotohits option").should("have.length", 1);
		cy.get("#gotohits option").should("contain", ONE_ITEM.title);
		cy.get("#gotohits option").should("not.contain", "showing first");
	});
});
