/*
 * Normalise a list-valued field of an API response into a real array.
 *
 * Two properties of the JSON responses make this necessary:
 *
 *   - a payload holding exactly one entry serialises as a bare object rather
 *     than a one-element array, so `value[0]` and `value.length` are undefined;
 *   - an empty result set may arrive as `null`, or omit the key entirely.
 *
 * Callers must also never loop to the reported `total`: that figure counts
 * every match, which may legitimately exceed the number of entries the server
 * actually sent (see the bounded search responses). Iterating the normalised
 * array is the only safe way to render whatever arrived.
 */
function listItems(value) {
	if (value === undefined || value === null) {
		return [];
	}
	return Array.isArray(value) ? value : [value];
}
