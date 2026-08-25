$(".parallelversion").on("click", function () {
	var workid = $(this).data("textid");
	var unit = $(this).data("unit");
	var getVersions = appBase + "/api/SPARQL/versions/" + workid + "/" + unit;
	$.getJSON(getVersions, function (d) {
		if (d.total >= 1) {
			for (var i = 0; i < d.total; i++) {
				var vers = d.versions[i].version;
				var textwithlinks = addDillmannlinks(vers.text);
				var source = "";
				if (vers.source.uniqueWitness) {
					source = vers.source.uniqueWitness;
					$("#versions").append(
						'<div id="version' +
							vers.source.id +
							'" class="w3-panel w3-gray version"><h3>Version ' +
							" " +
							vers.source.title +
							" (" +
							vers.source.id +
							")" +
							'</h3><p class="w3-large">Edition: ' +
							source +
							"</p>" +
							textwithlinks +
							"</div>",
					);
				} else {
					var editor = vers.source.ed;
					if (/bm:/g.test(editor) || /bm_/g.test(editor)) {
						var bibl;
						var existing = $('span[data-value="' + editor + '"]');
						if (existing.length >= 1 && existing.first().html()) {
							bibl = existing.first().html();
						} else if (vers.source.editionHtml) {
							bibl = '<span data-value="' + editor + '">' + vers.source.editionHtml + "</span>";
						} else {
							bibl = editor;
						}
						$("#versions").append(
							'<div id="version' +
								vers.source.id +
								'" class="w3-panel w3-gray version"><h3>Version ' +
								" " +
								vers.source.title +
								" (" +
								vers.source.id +
								")" +
								'</h3><p class="w3-large">Edition: ' +
								bibl +
								"</p>" +
								textwithlinks +
								"</div>",
						);
					} else {
						$("#versions").append(
							'<div id="version' +
								vers.source.id +
								'" class="w3-panel w3-gray version"><h3>Version ' +
								" " +
								vers.source.title +
								" (" +
								vers.source.id +
								")" +
								'</h3><p class="w3-large">Edition: ' +
								editor +
								"</p>" +
								textwithlinks +
								"</div>",
						);
					}
				}
			}
		} else {
			$(".parallelversion").attr("disabled", "disabled");
		}
	});
});

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
		if (i == countwords - 1) {
			$(allword).append($("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop));
		} else {
			$(allword).append(
				$("<a target='_blank' href='" + url + parm + nostops.w + "'/>").text(nostops.w + nostops.stop + " "),
			);
		}
	});
	return $(allword).html();
}
