// tinysort 3 throws on an empty match (tinysort 2 only warned), and not every
// page has every one of these selects, so only sort the ones that exist.
[
	"select#element>option",
	"select#wt>option",
	"select#target-ins>option",
	"select#scribe>option",
	"select#patron>option",
	"select#donor>option",
	"select#content>option",
	"select#author>option",
	"select#persType>option",
	"select#placeType>option",
	"select#tabot>option",
].forEach(function (selector) {
	if (document.querySelector(selector)) {
		tinysort(selector);
	}
});
