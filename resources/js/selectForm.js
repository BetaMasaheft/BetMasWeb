$("#SType").change(function () {
	var fields = document.getElementById("fields");
	var xpath = document.getElementById("xpath");
	var list = document.getElementById("lists");
	var sparql = document.getElementById("sparqls");
	var otherclavis = document.getElementById("otherclavis");
	if ($(this).val() === "fields") {
		fields.className += " w3-show";
	} else {
		fields.className = fields.className.replace(" w3-show", "");
	}
	if ($(this).val() === "sparql") {
		sparql.className += " w3-show";
		document.getElement('input[@name="query"]').replace(
			'<textarea \
                                         class="w3-input w3-border" id="sparql" \
                                         name="query" style="height:200px" \
                                         placeholder="Please enter a valid SPARQL query.">\
                                        </textarea>',
		);
		/*<input xmlns="" name="query" type="search" class="w3-input  w3-border diacritics ui-keyboard-input ui-widget-content ui-corner-all" placeholder="type here the text you want to search" value="" aria-haspopup="true" role="textbox">     */
	} else {
		sparql.className = sparql.className.replace(" w3-show", "");
	}
	if ($(this).val() === "xpath") {
		xpath.className += " w3-show";
	} else {
		xpath.className = xpath.className.replace(" w3-show", "");
	}
	if ($(this).val() === "otherclavis") {
		otherclavis.className += " w3-show";
	} else {
		otherclavis.className = otherclavis.className.replace(" w3-show", "");
	}
});

// q:includeXXX (modules/queries.xqm) server-renders each corpus-driven
// facet widget only when it has real state to restore, leaving an empty
// `<div id="$id">` placeholder otherwise - so a live "open this section"
// gesture (no reload involved) needs to fetch that one widget itself.
// Mirrors filters.js's callformpart(), but replaces a known placeholder
// id in place instead of appending into as.html's shared #AddFilters
// (newSearch has no single drop zone all these sections could share).
function loadFacetFragment(file, id) {
	var el = document.getElementById(id);
	if (el === null || el.children.length > 0) {
		// already fetched, or the id isn't on the page at all - nothing to do
		return;
	}
	$.ajax(file + window.location.search, {
		success: function (data) {
			$("#" + id).replaceWith(data);
		},
		error: function (xhr, status, error) {
			console.error("Failed to load facet fragment " + file + ":", error);
		},
	});
}

// #manuscriptsFilters/etc. are <fieldset disabled> by default - CSS
// display:none alone doesn't stop a browser from submitting a hidden
// field's value, and #gsf is one form wrapping every panel field, so a
// disabled fieldset is what actually keeps an unopened section's
// hardcoded defaults (dateRange="0001" etc.) out of the next
// submission. Showing/hiding a section here must enable/disable it too,
// or a live "+"-then-pick-a-type click couldn't submit anything.
//
// filters.js (loaded after this file) binds its own, simpler show/hide-
// only handler to this same #collectionfilter, shared with as.html's
// equivalent dropdown. This handler is a strict superset of that one, so
// stopImmediatePropagation() keeps filters.js's from redundantly
// re-running the same show/hide on every change - jQuery fires
// same-element handlers in binding order, and this one binds first.
function initCollectionFilter() {
	$("#collectionfilter").change(function (event) {
		event.stopImmediatePropagation();
		var val = $(this).val();
		var sections = ["manuscriptsFilters", "worksFilters", "persFilters", "placesFilters"];
		sections.forEach(function (id) {
			document.getElementById(id).disabled = true;
		});
		$("#manuscriptsFilters, #worksFilters, #persFilters, #placesFilters").hide();

		function reveal(id) {
			document.getElementById(id).disabled = false;
			$("#" + id).show();
		}

		if (val === "mss") {
			reveal("manuscriptsFilters");
			loadFacetFragment("forms/formMssRangeIndexes.html", "mssRangeIndexes");
			loadFacetFragment("forms/formMssPersRoles.html", "mssPersRoles");
			loadFacetFragment("forms/formRoles.html", "rolesLookup");
		} else if (val === "works") {
			reveal("worksFilters");
			loadFacetFragment("forms/formWorksRangeIndexes.html", "worksRangeIndexes");
			loadFacetFragment("forms/formWorkAuthors.html", "workAuthors");
		} else if (val === "pers") {
			reveal("persFilters");
			loadFacetFragment("forms/formPersonsRangeIndexes.html", "personsRangeIndexes");
		} else if (val === "places") {
			reveal("placesFilters");
			loadFacetFragment("forms/formPlacesRangeIndexes.html", "placesRangeIndexes");
			loadFacetFragment("forms/formTabot.html", "tabotLookup");
		}
	});
}

// #filters' content (work-types/dateRange/collectionfilter/etc.) is
// server-rendered directly into newSearch.html now, not AJAX-fetched
// from filters.html.txt - #collectionfilter exists from page load, so
// its change handler can bind immediately instead of waiting on that
// fetch's success callback.
initCollectionFilter();

$("#showfilters").one("click", function () {
	loadFacetFragment("forms/formGeneralRangeIndexes.html", "generalRangeIndexes");
});

$("#showfilters").click(function () {
	$(".filter").toggle("slow");
	var advanced = document.getElementById("advanced");
	if (advanced) {
		// "General filters" is always relevant once the panel itself is
		// open (unlike the four collection-specific sections, gated
		// separately by #collectionfilter above), so it enables together
		// with #advanced rather than needing its own reveal gesture.
		advanced.disabled = !advanced.disabled;
		document.getElementById("generalFilters").disabled = advanced.disabled;
		$("#advanced").toggle("slow");
	}
});

$("#showfields").click(function () {
	console.log("fields");
	var fields = document.getElementById("fields");
	fields.className += " w3-show";
});

$(document).ready(function () {
	var isAdvancedSearchClick = false;
	$('form button[type="submit"], form input[type="submit"], #searchButton').click(function () {
		isAdvancedSearchClick = true;
	});

	$("form").submit(function () {
		if (!isAdvancedSearchClick) {
			return true;
		}
		$(this)
			.find("#filters input, #filters select, #fields input, #fields select")
			.each(function () {
				var $el = $(this);
				if ($el.val() === "" || $el.is(":hidden") || $el.closest(":hidden").length > 0) {
					$el.removeAttr("name");
				}
			});
		isAdvancedSearchClick = false;
		return true;
	});
});

/*remove or disable text box for sparql and xpath not to confuse usage.*/
