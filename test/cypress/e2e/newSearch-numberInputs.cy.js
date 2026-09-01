// newSearch.html now loads filters.js on every page load (not only after
// opening the advanced panel). filters.js's document.ready unconditionally
// calls bootstrapSlider() on #folia, #writtenLines, #quiresComp, etc.
// Those fields are plain <input type="number"> on newSearch - as.html uses
// sliders for the same ids, but newSearch must keep number boxes.

function assertPlainNumberInput(selector) {
	cy.get(selector).should("have.attr", "type", "number").and("not.have.css", "display", "none");
	cy.get(selector).parent().find(".slider").should("not.exist");
}

it("GET /newSearch.html keeps #folia and #writtenLines as plain number inputs (not bootstrap sliders)", () => {
	cy.visit("/newSearch.html?searchType=text&query=Mary");
	cy.get("#showfilters").click();
	cy.get("#collectionfilter").select("mss");
	cy.get("#manuscriptsFilters").should("be.visible");
	assertPlainNumberInput("#folia");
	assertPlainNumberInput("#writtenLines");
	assertPlainNumberInput("#quiresComp");
});

it("GET /newSearch.html?script=geez keeps echoed range fields as plain number inputs on reload", () => {
	cy.visit("/newSearch.html?searchType=text&work-types=mss&script=geez");
	cy.get("#manuscriptsFilters").should("be.visible");
	assertPlainNumberInput("#folia");
	assertPlainNumberInput("#writtenLines");
});
