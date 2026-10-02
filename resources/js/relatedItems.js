$("#seealsoSelector").change(function (showthefilters) {
	var keyword = $("#seealsoSelector").val();
	//    console.log(keyword)
	var element = $("#seealsoSelector option:selected").parent().attr("label");
	var apiurl = appBase + "/api/sharedKeyword/";
	var param = "?element=" + encodeURIComponent(element);
	var call = apiurl + keyword + param;
	$.getJSON(call, function (data) {
		//console.log(data)
		var items = [];
		// Normalise the hits: a single result used to arrive as a bare object
		// rather than a one-element array, which needed a branch of its own.
		var hits = listItems(data.hits);
		if (hits.length === 0) {
			var card =
				"<div class='w3-card-4  w3-margin-bottom w3-gray'><div class='w3-container'><div>no results</div><div class='w3-content'>Sorry, this query returned no result</div></div></div>";
			items.push(card);
		} else {
			for (var i = 0; i < hits.length; i++) {
				var match = hits[i];
				var id = match.id;
				var title = match.title;
				var card =
					"<div class='w3-card-4  w3-margin-bottom w3-gray'><div id='" +
					id +
					"' class='w3-container'><div><a href='/" +
					id +
					"'>" +
					title +
					"</a></div></div></div>";
				items.push(card);
			}
		}
		$("#SeeAlsoResults").empty();
		$("<div/>", {
			class: "card-columns",
			html: items.join(""),
		}).appendTo("#SeeAlsoResults");
	});
});

$(document).on({
	ajaxStart: function () {
		$("img#loading").show();
		$("#mainPDF").attr("disabled", "disabled");
	},
	ajaxStop: function () {
		$("img#loading").hide();

		$("#mainPDF").removeAttr("disabled");
	},
});
