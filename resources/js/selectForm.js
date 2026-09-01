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
	});
}

function initCollectionFilter() {
	$("#collectionfilter").change(function () {
		var val = $(this).val();
		$("#manuscriptsFilters, #worksFilters, #persFilters, #placesFilters").hide();

		if (val === "mss") {
			$("#manuscriptsFilters").show();
			loadFacetFragment("forms/formMssRangeIndexes.html", "mssRangeIndexes");
			loadFacetFragment("forms/formMssPersRoles.html", "mssPersRoles");
			loadFacetFragment("forms/formRoles.html", "rolesLookup");
		} else if (val === "works") {
			$("#worksFilters").show();
			loadFacetFragment("forms/formWorksRangeIndexes.html", "worksRangeIndexes");
			loadFacetFragment("forms/formWorkAuthors.html", "workAuthors");
		} else if (val === "pers") {
			$("#persFilters").show();
			loadFacetFragment("forms/formPersonsRangeIndexes.html", "personsRangeIndexes");
		} else if (val === "places") {
			$("#placesFilters").show();
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
	if (document.getElementById("advanced")) {
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

function callformpart(file, id) {
	// check first that the element is not there already
	var myElem = document.getElementById(id);
	// if it is not there, load it
	if (myElem === null) {
		$.ajax(file, {
			success: function (data) {
				//console.log(data)
				$("#filters").append(data);
			},
		});
	}
	// else it has already been loaded, therefore simply show it.
	var jid = "#" + id;
	$(jid).toggle();
}

/*remove or disable text box for sparql and xpath not to confuse usage.*/
