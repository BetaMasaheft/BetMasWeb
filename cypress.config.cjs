const { defineConfig } = require("cypress");

module.exports = defineConfig({
	e2e: {
		// hit the app through controller.xql, exactly as a real client would -
		// that's what actually decides which RESTXQ module (if any) serves a
		// given api.json path right now
		baseUrl: "http://localhost:8080/exist/apps/BetMasWeb",
		supportFile: false,
		specPattern: "test/cypress/e2e/**/*.cy.js",
		screenshotsFolder: "test/cypress/screenshots",
		videosFolder: "test/cypress/videos",
		fixturesFolder: "test/cypress/fixtures",
		trashAssetsBeforeRuns: true,
	},
});
