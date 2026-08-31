// resources/js/filters.js - checkbox check/uncheck toggling its form
// fragment. objectType's callformpart target id didn't match
// forms/formobjecttype.html's real root id ("ot", not "otform"), so
// neither check nor uncheck ever found the element. CUnumber's uncheck
// switch had no case at all, so unchecking never hid its fragment.
//
// as.html renders all ~30 filter facets inline on every load - real
// corpus-scale work, well past Cypress's defaults. cy.visit()'s own
// `timeout` option (page-load wait) isn't enough on its own: the
// underlying proxied navigation request is also bound by Cypress's
// responseTimeout (30s default), which throws a raw ESOCKETTIMEDOUT
// before cy.visit()'s timeout ever gets a chance to apply - confirmed
// live, this was still failing with only `{ timeout: 90000 }` set.
// Both need raising together, via per-test config.

it("objectType checkbox shows/hides its fragment", { responseTimeout: 90000 }, () => {
	cy.visit("/as.html?work-types=mss", { timeout: 90000 });
	cy.get("#collectionfilter").select("mss");
	cy.get('input[type="checkbox"][value="objectType"]').check({ force: true });
	cy.get("#ot").should("be.visible");
	cy.get('input[type="checkbox"][value="objectType"]').uncheck({ force: true });
	cy.get("#ot").should("not.be.visible");
});

it("CUnumber checkbox shows/hides its fragment", { responseTimeout: 90000 }, () => {
	cy.visit("/as.html?work-types=mss", { timeout: 90000 });
	cy.get("#collectionfilter").select("mss");
	cy.get('input[type="checkbox"][value="CUnumber"]').check({ force: true });
	cy.get("#CUform").should("be.visible");
	cy.get('input[type="checkbox"][value="CUnumber"]').uncheck({ force: true });
	cy.get("#CUform").should("not.be.visible");
});
