$(function () {
	var url = $("#search");
	var jsonlisturl = $("#jsonlist");
	var baseurl = url.attr("href") || "";
	var jsonlistbaseurl = jsonlisturl.attr("href") || "";

	var colselection = "";
	var scriptselection = "";
	var materialselection = "";
	var keywordselection = "";

	function exampleLabel(path) {
		if (!path) return "";
		if (/^https?:\/\//i.test(path)) return path;
		return "https://betamasaheft.eu" + path;
	}

	function setExampleLink($a, path) {
		if (!$a.length) return;
		$a.attr("href", path);
		$a.text(exampleLabel(path));
	}

	$("#collectionjson").on("change", function () {
		var value = $(this).val();
		var newurl = jsonlistbaseurl.replace("works", value);
		jsonlistbaseurl = newurl;
		setExampleLink(jsonlisturl, newurl);
		getJdata();
	});

	$("#query").on("change paste", function () {
		var value = $(this).val();
		var newq = baseurl.replace("Pierre", value);
		var path = newq + colselection + scriptselection + materialselection + keywordselection;
		setExampleLink(url, path);
		getJdata();
	});

	$("#collection").on("change", function () {
		var value = $(this).val();
		colselection = "&collection=" + value;
		var path = baseurl + colselection + scriptselection + materialselection + keywordselection;
		setExampleLink(url, path);
		getJdata();
	});

	$("#script").on("change", function () {
		var value = $(this).val();
		scriptselection = "&script=" + value;
		var path = baseurl + colselection + scriptselection + materialselection + keywordselection;
		setExampleLink(url, path);
		getJdata();
	});

	$("#material").on("change", function () {
		var value = $(this).val();
		materialselection = "&material=" + value;
		var path = baseurl + colselection + scriptselection + materialselection + keywordselection;
		setExampleLink(url, path);
		getJdata();
	});

	$("#keyword").on("change", function () {
		var value = $(this).val();
		keywordselection = "&keyword=" + value;
		var path = baseurl + colselection + scriptselection + materialselection + keywordselection;
		setExampleLink(url, path);
		getJdata();
	});

	getJdata();
	getXdata();
});

function getJdata() {
	$(".APIexampleJSON").each(function () {
		var $el = $(this);
		var urlid = $el.data("value");
		var apicall = (function () {
			var $a = $("#" + urlid);
			if (!$a.length) return null;
			return $a.attr("href") || null;
		})();

		if (!apicall) {
			$el.text("Example unavailable (missing href)");
			return;
		}

		$.getJSON(apicall)
			.done(function (data) {
				$el.text(JSON.stringify(data, undefined, 4));
			})
			.fail(function (jqXHR, textStatus) {
				if (textStatus === "parsererror") {
					$el.text("Example unavailable (invalid JSON)");
					return;
				}
				if (jqXHR && jqXHR.status) {
					$el.text("Example unavailable (HTTP " + jqXHR.status + ")");
					return;
				}
				$el.text("Example unavailable (network error)");
			});
	});
}

function getXdata() {
	$(".APIexample").each(function () {
		var $el = $(this);
		var urlid = $el.data("value");
		var apicall = (function () {
			var $a = $("#" + urlid);
			if (!$a.length) return null;
			return $a.attr("href") || null;
		})();

		if (!apicall) {
			$el.text("Example unavailable (missing href)");
			return;
		}

		$.ajax({
			url: apicall,
			dataType: "text",
		})
			.done(function (data) {
				$el.text(data);
			})
			.fail(function (jqXHR) {
				if (jqXHR && jqXHR.status) {
					$el.text("Example unavailable (HTTP " + jqXHR.status + ")");
					return;
				}
				$el.text("Example unavailable (network error)");
			});
	});
}
