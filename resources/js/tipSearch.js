/* Search links shown in word and relation tooltips (#178).
 * The anchors carry href="#" so crawlers cannot harvest search URLs; this
 * module builds them and opens the target on click or middle-click.
 * Must load before highlight.js and PointsHere.js. */
(function (window, $) {
	if (window.bmTipSearch) return;

	var targets = [
		{ type: "new-search", path: "/newSearch.html?query=", label: "in Beta maṣāḥǝft" },
		{ type: "morpho-search", path: "/morpho?query=", label: "in the Gǝʿǝz Morphological Parser" },
		{ type: "morpho-corpus-search", path: "/morpho/corpus?type=string&query=", label: "in the TraCES annotations" },
		{ type: "online-lexicon-search", path: "/Dillmann/?mode=fuzzy&q=", label: "in the Online Lexicon" },
	];

	function escapeHtml(s) {
		return String(s)
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;")
			.replace(/"/g, "&quot;")
			.replace(/'/g, "&#39;");
	}

	function url(type, q) {
		var target = targets.filter(function (t) {
			return t.type === type;
		})[0];
		if (!target || q === undefined || q === null) return null;
		var base = typeof window.appBase !== "undefined" ? window.appBase : "";
		return base + target.path + encodeURIComponent(q);
	}

	function links(q) {
		var attr = escapeHtml(q);
		return targets
			.map(function (t) {
				return (
					'<a href="#" class="bm-tip-search" data-type="' + t.type + '" data-q="' + attr + '">' + t.label + "</a><br/>"
				);
			})
			.join("");
	}

	function follow(e) {
		if (e.type === "auxclick" && e.button !== 1) return;
		e.preventDefault();
		var href = url($(this).attr("data-type"), $(this).attr("data-q"));
		if (href) window.open(href, "_blank");
	}

	$(document).on("click auxclick", "a.bm-tip-search", follow);

	window.bmTipSearch = { escapeHtml: escapeHtml, links: links, url: url };
})(window, jQuery);
