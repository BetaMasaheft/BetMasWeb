$(".parallelversion").on("click", function () {
	var workid = $(this).data("textid");
	var unit = $(this).data("unit");
	// Web-only path (not Api /api/SPARQL/versions) so editionHtml enrichment always runs
	var getVersions = appBase + "/api/versions/" + workid + "/" + unit;
	$.getJSON(getVersions, function (d) {
		if (d.total >= 1) {
			for (var i = 0; i < d.total; i++) {
				var vers = d.versions[i].version;
				var textwithlinks = addDillmannlinks(vers.text);
				var $block = versionBlock(vers.source.id, vers.source.title);
				if (vers.source.uniqueWitness) {
					$block.find(".version-edition").append(document.createTextNode(vers.source.uniqueWitness));
				} else {
					var editor = vers.source.ed;
					if (isBmTag(editor)) {
						$block.find(".version-edition").append(editionCite(editor, vers.source.editionHtml));
					} else {
						$block.find(".version-edition").append(document.createTextNode(editor || ""));
					}
				}
				$block.append(textwithlinks);
				$("#versions").append($block);
			}
		} else {
			$(".parallelversion").attr("disabled", "disabled");
		}
	});
});

function normalizeBmTag(tag) {
	var s = String(tag == null ? "" : tag);
	return s.indexOf("bm_") === 0 ? "bm:" + s.slice(3) : s;
}

function isBmTag(tag) {
	var s = String(tag == null ? "" : tag);
	return /^bm[:_]/.test(s);
}

function editionCite(editor, editionHtml) {
	var tag = normalizeBmTag(editor);
	var existing = $('span[data-value="' + cssAttrEscape(tag) + '"]');
	if (existing.length >= 1 && existing.first().html()) {
		return existing.first().clone(false);
	}
	var $span = $("<span/>").attr("data-value", tag);
	if (editionHtml) {
		$span.html(editionHtml);
	} else {
		$span.text(tag);
	}
	return $span;
}

function cssAttrEscape(value) {
	// Escape for use inside a double-quoted CSS attribute selector
	return String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function versionBlock(id, title) {
	var $div = $("<div/>")
		.attr("id", "version" + id)
		.addClass("w3-panel w3-gray version");
	$div.append($("<h3/>").text("Version  " + title + " (" + id + ")"));
	$div.append($("<p/>").addClass("w3-large version-edition").text("Edition: "));
	return $div;
}

function addDillmannlinks(textinput) {
	var allword = $("<div/>");
	var normspace = textinput.replace(/\s\s+/g, " ");
	var textinputsplit = normspace.split(" ");
	var countwords = textinputsplit.length;
	$(this).empty();
	var url = "/Dillmann/?mode=fuzzy";
	var parm = "&q=";
	$.each(textinputsplit, function (i, v) {
		var nostops = {};
		if (v.endsWith("፡")) {
			nostops.w = v.substr(0, v.indexOf("፡"));
			nostops.stop = "፡";
		} else if (v.endsWith("።")) {
			nostops.w = v.substr(0, v.indexOf("።"));
			nostops.stop = "።";
		} else {
			nostops.w = v;
			nostops.stop = "";
		}
		if (i === countwords - 1) {
			$(allword).append($("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop));
		} else {
			$(allword).append(
				$("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop + " "),
			);
		}
	});
	return $(allword).html();
}
