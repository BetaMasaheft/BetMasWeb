#!/usr/bin/env node
// Copies the browser-facing files of each package.json "dependencies" entry from
// node_modules into resources/js/external, where the app's <script>/<link> tags
// load them from. Run via `npm run vendor:copy` (or `npm run vendor`, which also
// installs first) - this is the file:// end of the "npm install" -> "vendor.copy"
// Ant target in build.xml.
//
// Only the specific dist file(s) actually used by the app are copied, not whole
// packages. Add an entry here whenever a new vendor dependency is added to
// package.json.
//
// resources/js/external is reproducible from package.json + this script, so it's
// gitignored. A few libraries can't go through npm at all though, because there's
// no usable package for them - those live in resources/js/vendor instead, committed
// directly since nothing can regenerate them:
//   - mapbox.js (legacy Mapbox.js 2.3.0): npm only publishes unbundled CommonJS
//     source, not the browser bundle this app actually loads.
//   - d3sparql.js, leaflet-fusesearch: never published to npm at all.
//   - yui-min.js (YUI 3.8.1): only reference in the codebase is inside a
//     commented-out block in collatex.js - looks dead, kept as-is, not managed.

const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const NODE_MODULES = path.join(ROOT, "node_modules");
const DEST_ROOT = path.join(ROOT, "resources", "js", "external");

// Each entry: [destination subfolder, [ [sourceRelativeToPackage, destFilename], ... ]]
const MANIFEST = {
	jquery: ["jquery", [["dist/jquery.min.js", "jquery.min.js"]]],
	"jquery-migrate": ["jquery-migrate", [["dist/jquery-migrate.min.js", "jquery-migrate.min.js"]]],
	"jquery.easing": ["jquery.easing", [["jquery.easing.min.js", "jquery.easing.min.js"]]],
	"jquery-ui-dist": [
		"jquery-ui",
		[
			["jquery-ui.min.js", "jquery-ui.min.js"],
			["jquery-ui.min.css", "jquery-ui.min.css"],
			["jquery-ui.theme.min.css", "jquery-ui.theme.min.css"],
			["images", "images"],
		],
	],
	"datatables.net": ["datatables", [["js/jquery.dataTables.js", "jquery.dataTables.js"]]],
	"datatables.net-bs": [
		"datatables",
		[
			["js/dataTables.bootstrap.js", "dataTables.bootstrap.js"],
			["css/dataTables.bootstrap.css", "dataTables.bootstrap.css"],
		],
	],
	leaflet: [
		"leaflet",
		[
			["dist/leaflet.js", "leaflet.js"],
			["dist/leaflet.css", "leaflet.css"],
		],
	],
	"leaflet-search": [
		"leaflet-search",
		[
			["dist/leaflet-search.min.js", "leaflet-search.min.js"],
			["dist/leaflet-search.min.css", "leaflet-search.min.css"],
		],
	],
	"leaflet-fullscreen": [
		"leaflet-fullscreen",
		[
			["dist/Leaflet.fullscreen.min.js", "Leaflet.fullscreen.min.js"],
			["dist/leaflet.fullscreen.css", "leaflet.fullscreen.css"],
			["dist/fullscreen.png", "fullscreen.png"],
			["dist/fullscreen@2x.png", "fullscreen@2x.png"],
		],
	],
	"leaflet-ajax": ["leaflet-ajax", [["dist/leaflet.ajax.min.js", "leaflet.ajax.min.js"]]],
	"fuse.js": ["fuse", [["dist/fuse.min.js", "fuse.min.js"]]],
	openseadragon: [
		"openseadragon",
		[
			["build/openseadragon/openseadragon.min.js", "openseadragon.min.js"],
			["build/openseadragon/openseadragon.min.js.map", "openseadragon.min.js.map"],
			["build/openseadragon/images", "images"],
		],
	],
	"@fortawesome/fontawesome-free": [
		"fontawesome",
		[
			["css/all.min.css", "all.min.css"],
			["css/v4-shims.min.css", "v4-shims.min.css"],
			["webfonts", "webfonts"],
		],
	],
	bootstrap: ["bootstrap", [["dist/css/bootstrap.min.css", "bootstrap.min.css"]]],
	colorbrewer: ["colorbrewer", [["index.js", "colorbrewer.js"]]],
	"cookie-bar": ["cookie-bar", [["cookiebar-latest.min.js", "cookiebar.min.js"]]],
	d3: ["d3", [["dist/d3.min.js", "d3.min.js"]]],
	"d3-v3": ["d3-v3", [["d3.min.js", "d3.min.js"]]],
	"intro.js": [
		"intro.js",
		[
			["minified/intro.min.js", "intro.min.js"],
			["minified/introjs.min.css", "introjs.min.css"],
		],
	],
	"slick-carousel": [
		"slick-carousel",
		[
			["slick/slick.min.js", "slick.min.js"],
			["slick/slick.css", "slick.css"],
			["slick/slick-theme.css", "slick-theme.css"],
			["slick/fonts", "fonts"],
			["slick/ajax-loader.gif", "ajax-loader.gif"],
		],
	],
	tinysort: ["tinysort", [["dist/tinysort.min.js", "tinysort.min.js"]]],
	"virtual-keyboard": [
		"virtual-keyboard",
		[
			["dist/js/jquery.keyboard.js", "jquery.keyboard.js"],
			["dist/js/jquery.keyboard.extension-altkeyspopup.min.js", "jquery.keyboard.extension-altkeyspopup.min.js"],
			["dist/js/jquery.keyboard.extension-typing.min.js", "jquery.keyboard.extension-typing.min.js"],
			["dist/js/jquery.mousewheel.min.js", "jquery.mousewheel.min.js"],
			["dist/css/keyboard-basic.min.css", "keyboard-basic.min.css"],
		],
	],
	"alpheios-embedded": ["alpheios", [["dist/alpheios-embedded.min.js", "alpheios-embedded.min.js"]]],
	"alpheios-components": [
		"alpheios",
		[
			["dist/alpheios-components.min.js", "alpheios-components.min.js"],
			["dist/style/style-components.min.css", "style-components.min.css"],
		],
	],
};

let copied = 0;
for (const [pkg, [destSubdir, files]] of Object.entries(MANIFEST)) {
	const pkgDir = path.join(NODE_MODULES, pkg);
	if (!fs.existsSync(pkgDir)) {
		throw new Error(`${pkg} is listed in the vendor manifest but missing from node_modules - run npm install first`);
	}
	const destDir = path.join(DEST_ROOT, destSubdir);
	fs.mkdirSync(destDir, { recursive: true });
	for (const [from, to] of files) {
		const src = path.join(pkgDir, from);
		const dest = path.join(destDir, to);
		if (!fs.existsSync(src)) {
			throw new Error(`${pkg}: expected file ${from} not found at ${src}`);
		}
		fs.cpSync(src, dest, { recursive: true });
		copied += 1;
	}
}

console.log(`Copied ${copied} vendor files/dirs into ${path.relative(ROOT, DEST_ROOT)}`);
