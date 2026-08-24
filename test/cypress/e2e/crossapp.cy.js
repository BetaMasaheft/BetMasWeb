// modules/crossapp.xqm - dynamic operation lookup for Roaster routes backed
// by another, optionally-installed package. Registered operations are
// documented in api.json/routes.json like any other Roaster route (see
// x-implementation there); this file exercises the lookup mechanism itself.

// This standalone container never installs BetMasApi (confirmed:
// xmldb:collection-available("/db/apps/BetMasApi") is false here), so
// places:json always resolves to crossapp:resolve()'s 501 fallback -
// exercising that path specifically, not the real BetMasApi operation.
// The real-data path (BetMasApi installed) is verified manually/in
// BetMasApi's own assembled compose stack - see BetMasWeb#36.
it("GET /{id}.json (as /BAVet1.json) - BetMasApi not installed, clean 501", () => {
	cy.request({ url: "/BAVet1.json", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1.json responded with ${res.status}`).to.eq(501);
		expect(res.headers["content-type"], "Roaster's own error handler always sets this").to.include("application/json");
		expect(res.body.description, "should explain that BetMasApi isn't installed, not just fail opaquely").to.include(
			"BetMasApi is not installed",
		);
	});
});
