$(document).on({
	ajaxStart: function () {
		$("img#loading").show();
	},
	ajaxStop: function () {
		$("img#loading").hide();
	},
});

$("#loadcatalogues").click(function () {
	$("#loadcatalogues").attr("disabled", "disabled");
	$("#GoToCatalogue").load(appBase + "/api/cataloguesZotero");
	$("#clickandgotoCatalogueID").removeAttr("disabled");
});

$("#loadrepositories").click(function () {
	$("#loadrepositories").attr("disabled", "disabled");
	$("#GoToRepo").load(appBase + "/api/listRepositoriesName");
	$("#clickandgotoRepoID").removeAttr("disabled");
});
