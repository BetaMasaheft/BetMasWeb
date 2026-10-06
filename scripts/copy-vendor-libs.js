#!/usr/bin/env node
// Copies the browser-facing files of each package.json "dependencies" entry from
// node_modules into resources/{js,css,fonts}/external, where the app's
// <script>/<link> tags load them from. Run via `npm run vendor:copy` (or
// `npm run vendor`, which also installs first) - this is the file:// end of the
// "npm install" -> "vendor.copy" Ant target in build.xml.
//
// Only the specific dist file(s) actually used by the app are copied, not whole
// packages. Add an entry here whenever a new vendor dependency is added to
// package.json.
//
// resources/{js,css,fonts}/external are reproducible from package.json + this
// script, so they're gitignored. A few libraries can't go through npm at all
// though, because there's no usable package for them - those live in
// resources/js/vendor instead, committed directly since nothing can regenerate
// them:
//   - mapbox.js (legacy Mapbox.js 2.3.0): npm only publishes unbundled CommonJS
//     source, not the browser bundle this app actually loads.
//   - d3sparql.js, leaflet-fusesearch: never published to npm at all.
//   - yui-min.js (YUI 3.8.1): only reference in the codebase is inside a
//     commented-out block in collatex.js - looks dead, kept as-is, not managed.

const fs = require("node:fs");
const path = require("node:path");

const ROOT = path.resolve(__dirname, "..");
const NODE_MODULES = path.join(ROOT, "node_modules");
const DEST_ROOTS = {
	js: path.join(ROOT, "resources", "js", "external"),
	css: path.join(ROOT, "resources", "css", "external"),
	fonts: path.join(ROOT, "resources", "fonts", "external"),
};

// Each entry: [destination subfolder, [ [sourceRelativeToPackage, destFilename, root?, subdir?], ... ]]
// root selects which of DEST_ROOTS the file lands under and defaults to "js" when omitted.
// subdir overrides the package's destination subfolder for just that file - "" puts it
// directly under the root with no subfolder - and defaults to the package's destSubdir.
// Keep a stylesheet together with any asset directory (images/, fonts/) it reaches through a
// relative url() - same root and subfolder - so that relative reference still resolves after
// the copy. Two exceptions:
//   - fontawesome's and bootstrap's webfonts are pulled into the shared "fonts" root instead
//     (flat, no subfolder) rather than duplicated per package; their CSS gets its url()
//     rewritten below to match (see rewriteFontUrls).
//   - cookie-bar's theme CSS/sprite/language files stay under "js" next to its script instead
//     of moving to "css" - cookiebar.min.js locates them at runtime relative to its own
//     <script src>, with no configurable base path, so they have to live wherever the JS does.
const MANIFEST = {
	jquery: ["jquery", [["dist/jquery.min.js", "jquery.min.js"]]],
	"jquery-migrate": ["jquery-migrate", [["dist/jquery-migrate.min.js", "jquery-migrate.min.js"]]],
	"jquery.easing": ["jquery.easing", [["jquery.easing.min.js", "jquery.easing.min.js"]]],
	"jquery-ui-dist": [
		"jquery-ui",
		[
			["jquery-ui.min.js", "jquery-ui.min.js"],
			["jquery-ui.min.css", "jquery-ui.min.css", "css"],
			["jquery-ui.theme.min.css", "jquery-ui.theme.min.css", "css"],
			["images", "images", "css"],
		],
	],
	"datatables.net": ["datatables", [["js/jquery.dataTables.js", "jquery.dataTables.js"]]],
	"datatables.net-bs": [
		"datatables",
		[
			["js/dataTables.bootstrap.js", "dataTables.bootstrap.js"],
			["css/dataTables.bootstrap.css", "dataTables.bootstrap.css", "css"],
		],
	],
	leaflet: [
		"leaflet",
		[
			["dist/leaflet.js", "leaflet.js"],
			["dist/leaflet.css", "leaflet.css", "css"],
		],
	],
	// Leaflet 1.x, used by newindex2.html/newpage.html; "leaflet" above stays on 0.7.7 for the
	// mapbox.js-based item/list pages. leaflet.css finds its images/ through a relative url(), so
	// the two stay together under css.
	"leaflet-v1": [
		"leaflet-v1",
		[
			["dist/leaflet.js", "leaflet.js"],
			["dist/leaflet.css", "leaflet.css", "css"],
			["dist/images", "images", "css"],
		],
	],
	"bootstrap-slider": [
		"bootstrap-slider",
		[
			["dist/bootstrap-slider.min.js", "bootstrap-slider.min.js"],
			["dist/css/bootstrap-slider.min.css", "bootstrap-slider.min.css", "css"],
		],
	],
	"vis-timeline": [
		"vis-timeline",
		[
			["standalone/umd/vis-timeline-graph2d.min.js", "vis-timeline-graph2d.min.js"],
			["styles/vis-timeline-graph2d.min.css", "vis-timeline-graph2d.min.css", "css"],
		],
	],
	// peer/ expects vis-data/vis-util as globals (supplied by the vis-timeline standalone bundle,
	// which must load first); standalone/ is self-contained.
	"vis-network": [
		"vis-network",
		[
			["peer/umd/vis-network.min.js", "vis-network.peer.min.js"],
			["standalone/umd/vis-network.min.js", "vis-network.min.js"],
		],
	],
	"leaflet-search": [
		"leaflet-search",
		[
			["dist/leaflet-search.min.js", "leaflet-search.min.js"],
			["dist/leaflet-search.min.css", "leaflet-search.min.css", "css"],
		],
	],
	"leaflet-fullscreen": [
		"leaflet-fullscreen",
		[
			["dist/Leaflet.fullscreen.min.js", "Leaflet.fullscreen.min.js"],
			["dist/leaflet.fullscreen.css", "leaflet.fullscreen.css", "css"],
			["dist/fullscreen.png", "fullscreen.png", "css"],
			["dist/fullscreen@2x.png", "fullscreen@2x.png", "css"],
		],
	],
	"leaflet-ajax": ["leaflet-ajax", [["dist/leaflet.ajax.min.js", "leaflet.ajax.min.js"]]],
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
			["css/all.min.css", "all.min.css", "css"],
			["webfonts", "", "fonts", ""],
		],
	],
	bootstrap: [
		"bootstrap",
		[
			["dist/css/bootstrap.min.css", "bootstrap.min.css", "css"],
			["dist/js/bootstrap.min.js", "bootstrap.min.js"],
			// bootstrap.min.css references its glyphicon font via url(../fonts/...), same
			// deal as fontawesome above - rewritten below to point at the shared fonts root.
			["dist/fonts/glyphicons-halflings-regular.eot", "glyphicons-halflings-regular.eot", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.svg", "glyphicons-halflings-regular.svg", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.ttf", "glyphicons-halflings-regular.ttf", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.woff", "glyphicons-halflings-regular.woff", "fonts", ""],
			["dist/fonts/glyphicons-halflings-regular.woff2", "glyphicons-halflings-regular.woff2", "fonts", ""],
		],
	],
	colorbrewer: ["colorbrewer", [["index.js", "colorbrewer.js"]]],
	"cookie-bar": [
		"cookie-bar",
		[
			["cookiebar-latest.min.js", "cookiebar.min.js"],
			// cookiebar.min.js finds its own <script src> at runtime and loads its theme CSS,
			// language files and sprite relative to THAT path - it has no configurable base
			// path option - so these have to stay physically next to the JS, not under
			// resources/css/external like every other vendored stylesheet.
			["themes/cookiebar.min.css", "themes/cookiebar.min.css"],
			["themes/images.png", "themes/images.png"],
			["lang", "lang"],
		],
	],
	d3: ["d3", [["dist/d3.min.js", "d3.min.js"]]],
	"d3-v3": ["d3-v3", [["d3.min.js", "d3.min.js"]]],
	"intro.js": [
		"intro.js",
		[
			["minified/intro.min.js", "intro.min.js"],
			["minified/introjs.min.css", "introjs.min.css", "css"],
		],
	],
	"slick-carousel": [
		"slick-carousel",
		[
			["slick/slick.min.js", "slick.min.js"],
			["slick/slick.css", "slick.css", "css"],
			["slick/slick-theme.css", "slick-theme.css", "css"],
			["slick/fonts", "fonts", "css"],
			["slick/ajax-loader.gif", "ajax-loader.gif", "css"],
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
			["dist/css/keyboard-basic.min.css", "keyboard-basic.min.css", "css"],
		],
	],
	"alpheios-embedded": ["alpheios", [["dist/alpheios-embedded.min.js", "alpheios-embedded.min.js"]]],
	"alpheios-components": [
		"alpheios",
		[
			["dist/alpheios-components.min.js", "alpheios-components.min.js"],
			["dist/style/style-components.min.css", "style-components.min.css", "css"],
		],
	],
};

let copied = 0;
for (const [pkg, [destSubdir, files]] of Object.entries(MANIFEST)) {
	const pkgDir = path.join(NODE_MODULES, pkg);
	if (!fs.existsSync(pkgDir)) {
		throw new Error(`${pkg} is listed in the vendor manifest but missing from node_modules - run npm install first`);
	}
	for (const [from, to, root = "js", subdir = destSubdir] of files) {
		const destDir = path.join(DEST_ROOTS[root], subdir);
		fs.mkdirSync(destDir, { recursive: true });
		const src = path.join(pkgDir, from);
		const dest = path.join(destDir, to);
		if (!fs.existsSync(src)) {
			throw new Error(`${pkg}: expected file ${from} not found at ${src}`);
		}
		fs.cpSync(src, dest, { recursive: true });
		copied += 1;
	}
}

// Some vendored stylesheets reference their webfonts via a relative url() that only
// worked when the font files sat right next to the CSS in the original package
// (e.g. css/all.min.css + webfonts/ as siblings). Since every such font now lands
// flat in resources/fonts/external instead, rewrite each of those relative
// references to point there.
function rewriteFontUrls(cssSubdir, cssFilename, oldPrefix) {
	const cssPath = path.join(DEST_ROOTS.css, cssSubdir, cssFilename);
	const fontsRel = path.relative(path.dirname(cssPath), DEST_ROOTS.fonts).split(path.sep).join("/");
	const original = fs.readFileSync(cssPath, "utf8");
	const rewritten = original.split(oldPrefix).join(`${fontsRel}/`);
	if (rewritten === original) {
		throw new Error(
			`${cssPath}: expected to rewrite ${oldPrefix} references, but found none - did the package's CSS change?`,
		);
	}
	fs.writeFileSync(cssPath, rewritten);
}

rewriteFontUrls("fontawesome", "all.min.css", "../webfonts/");
rewriteFontUrls("bootstrap", "bootstrap.min.css", "../fonts/");

console.log(`Copied ${copied} vendor files/dirs into resources/{js,css,fonts}/external`);
