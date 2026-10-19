// Tooltip search links on tokenised Gǝʿǝz words (highlight.js) and on relation
// popups (PointsHere.js) must not expose crawlable search URLs, since bots
// harvesting them overloaded the server (#178). They carry href="#" and are
// navigated by resources/js/tipSearch.js on click or middle-click, which must
// leave every other link on the page alone.

const page = "/works/LIT4244Prayer/main";

const stubOpen = () =>
	cy.window().then((win) => {
		cy.stub(win, "open").as("open");
	});

it("renders tooltip search links without crawlable search hrefs", () => {
	cy.visit(page);
	cy.get(".word .popuptext a.bm-tip-search").should("have.length.greaterThan", 0);
	cy.get(".word .popuptext a").each(($a) => {
		expect($a.attr("href")).to.eq("#");
	});
	cy.get(".word .popuptext").first().find("a.bm-tip-search").should("have.length", 4);
});

it("opens the search for the clicked word in a new tab", () => {
	cy.visit(page);
	stubOpen();
	cy.get(".word .popuptext a.bm-tip-search[data-type='new-search']")
		.first()
		.then(($a) => {
			const q = $a.attr("data-q");
			cy.wrap($a).click({ force: true });
			cy.window().then((win) => {
				cy.get("@open").should(
					"have.been.calledWith",
					win.appBase + "/newSearch.html?query=" + encodeURIComponent(q),
					"_blank",
				);
			});
		});
});

it("opens the search on middle-click too", () => {
	cy.visit(page);
	stubOpen();
	cy.get(".word .popuptext a.bm-tip-search[data-type='online-lexicon-search']")
		.first()
		.trigger("auxclick", { button: 1, force: true });
	cy.get("@open").should("have.been.calledOnce");
	cy.get("@open").its("firstCall.args.0").should("contain", "/Dillmann/?mode=fuzzy&q=");
});

it("adds the same search links to relation popups", () => {
	cy.intercept("GET", "**/api/SPARQL/relations/*", [
		{ id: "/works/LIT1709Kebran", title: "Kebra", relation: "saws:isRelatedTo" },
	]);
	cy.visit("/persons/PRS10036Wansleb/main");
	cy.get("span[id$='relations']:not([id$='Entrelations'])")
		.first()
		.then(($span) => {
			const q = $span.prev().text();
			cy.wrap($span).click({ force: true });
			cy.wrap($span)
				.find(".popuptext a.bm-tip-search")
				.should("have.length", 4)
				.each(($a) => {
					expect($a.attr("href")).to.eq("#");
					expect($a.attr("data-q")).to.eq(q);
				});
		});
});

it("does not cancel clicks on other links", () => {
	cy.visit(page);
	cy.document().then((doc) => {
		const a = doc.createElement("a");
		a.href = "#elsewhere";
		doc.body.appendChild(a);
		const ev = new MouseEvent("click", { bubbles: true, cancelable: true });
		a.dispatchEvent(ev);
		expect(ev.defaultPrevented).to.eq(false);
	});
});

it("escapes the query in markup and encodes it in the URL", () => {
	cy.visit(page);
	cy.window().then((win) => {
		const q = `a"b'c<d>&e`;
		const div = win.document.createElement("div");
		div.innerHTML = win.bmTipSearch.links(q);
		const links = div.querySelectorAll("a.bm-tip-search");
		expect(links).to.have.length(4);
		links.forEach((a) => {
			expect(a.getAttribute("data-q")).to.eq(q);
		});
		expect(win.bmTipSearch.url("morpho-corpus-search", q)).to.eq(
			win.appBase + "/morpho/corpus?type=string&query=" + encodeURIComponent(q),
		);
		expect(win.bmTipSearch.url("unknown", q)).to.eq(null);
	});
});
