$("#gsf").on("submit", function () {
	var controls = this.elements;
	for (var i = 0, iLen = controls.length; i < iLen; i++) {
		controls[i].disabled = controls[i].value == "";
	}
});

/*
 * match the checkbox AttestedInType and check
 * if one is checked, uncheck the other, so that only one is checked at a time
 * from https://stackoverflow.com/questions/17785010/jquery-uncheck-other-checkbox-on-one-checked
 */
$("[id^='AttestedInType']").on("change", function () {
	console.log("you did something");
	$("[id^='AttestedInType']").not(this).prop("checked", false);
});

/*
 * The suggestion lists must be driven by the items that were actually sent,
 * never by ?total. Since both endpoints got a response cap, ?total is the
 * number of matches in the whole corpus and can be far larger than the
 * array - looping to ?total ran off the end of it and threw.
 *
 * A single match also arrives as a bare object rather than a one-element
 * array; listItems() (resources/js/listResponse.js) reconciles both cases.
 */
$(document).on("ready", function () {
	$("#GoTo").on("change paste", function () {
		/*$( document ).ajaxStop(function() {
  $( "#loading" ).hide();
});*/
		var empty = false;
		$("#GoTo").each(function () {
			if ($(this).val() == "") {
				empty = true;
			}
		});
		if (empty) {
			$("#clickandgoto").attr("disabled", "disabled");
			// updated according to http://stackoverflow.com/questions/7637790/how-to-remove-disabled-attribute-with-jquery-ie
		} else {
			$("#clickandgoto").removeAttr("disabled");
			// updated according to http://stackoverflow.com/questions/7637790/how-to-remove-disabled-attribute-with-jquery-ie
		}
		// check what is the checked value
		var type = $("[id^='AttestedInType']:checked").val();
		// check collection
		var collection = $("#GoTo").data("value");
		var searchterm = $("#GoTo").val();
		if (searchterm.length > 4) {
			console.log(searchterm);

			var element = "";
			switch (collection) {
				case "persons":
					element = "persName";
					break;
				case "places":
					element = "placeName";
					break;
				case "institutions":
					element = "placeName";
					break;
				case "all":
					element = "title";
					break;
				default:
					element = "title";
			}
			console.log(searchterm);
			// this will look ONLY in one element for each type of record
			var apiurl = "";
			if (type == 2) {
				apiurl = appBase + "/api/search?element=" + element + "&collection=" + collection + "&q=";
			} else {
				apiurl = appBase + "/api/idlookup?id=";
			}
			var searchurl = apiurl + searchterm;
			console.log(searchurl);
			$.getJSON(searchurl, function (data) {
				console.log(data);

				var options = "";
				var items = listItems(data.items);
				for (var i = 0; i < items.length; i++) {
					var tit = "";
					if (type == 2) {
						tit = items[i].title;
					} else {
						tit = items[i].id;
					}
					var option = '<option value="' + items[i].id + '">' + tit + "</option>";
					options += option;
				}

				if (data.truncated) {
					options =
						'<option value="" disabled>' +
						"showing first " +
						items.length +
						" of " +
						data.total +
						" matches - keep typing to narrow it down</option>" +
						options;
				}

				$("#gotohits").html(options);
			});
		} else {
			console.log("not long enough");
		}
	});

	$("#clickandgoto").on("click", function () {
		url = $("#gotohits").val();
		window.open(url);
	});

	$("#GoToId").on("change paste keyup", function () {
		var collection = $("#GoToId").data("value");
		var searchterm = $("#GoToId").val();
		if (searchterm.length >= 3) {
			// this will look ONLY in one element for each type of record
			var apiurl = appBase + "/api/idlookup?id=";
			var searchurl = apiurl + searchterm;

			$.getJSON(searchurl, function (data) {
				var options = "";
				var items = listItems(data.items);
				for (var i = 0; i < items.length; i++) {
					var option = '<option value="' + items[i].id + '">' + items[i].id + "</option>";
					options += option;
					console.log(option);
				}

				if (data.truncated) {
					options =
						'<option value="" disabled>' +
						"showing first " +
						items.length +
						" of " +
						data.total +
						" matches - keep typing to narrow it down</option>" +
						options;
				}

				$("#gotoID").html(options);
			});
		}
	});

	$("#clickandgotoID").on("click", function () {
		url = $("#GoToId").val();
		window.open(url);
	});
	$("#clickandgotoRepoID").on("click", function () {
		url = $("#GoToRepo").val();
		fullurl = "/manuscripts/" + url + "/list";
		console.log(fullurl);
		window.open(fullurl);
	});
	$("#clickandgotoCatalogueID").on("click", function () {
		url = $("#GoToCatalogue").val();
		fullurl = "/catalogues/" + url + "/list";
		console.log(fullurl);
		window.open(fullurl);
	});
});
