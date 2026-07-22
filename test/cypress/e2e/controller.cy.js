// generated from api.json - operations dispatched directly by controller.xql
// (no dedicated x-implementation module: static/view resources, list pages, suffix-based
// content negotiation, etc)

it("GET /{id}.xml (as /BAVet1.xml)", () => {
	cy.request({ url: "/BAVet1.xml", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1.xml responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1.xml responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /tei/{id}.xml (as /tei/BAVet1.xml)", () => {
	cy.request({ url: "/tei/BAVet1.xml", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /tei/BAVet1.xml responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /tei/BAVet1.xml responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}.rdf (as /BAVet1.rdf)", () => {
	cy.request({ url: "/BAVet1.rdf", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1.rdf responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1.rdf responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}.json (as /LOC5374Rome.json)", () => {
	// .json only exists as a geoJson/places branch (forwards to /api/geoJson/places/{id}),
	// not a generic per-id route — use a place id so this actually exercises it
	cy.request({ url: "/LOC5374Rome.json", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /LOC5374Rome.json responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /LOC5374Rome.json responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /CAe{suffix} (as /CAe0001)", () => {
	cy.request({ url: "/CAe0001", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /CAe0001 responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /CAe0001 responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /search.html", () => {
	cy.request({ url: "/search.html", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /search.html responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /search.html responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/list", () => {
	cy.request({ url: "/manuscripts/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /persons/list", () => {
	cy.request({ url: "/persons/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /persons/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /persons/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /institutions/list", () => {
	cy.request({ url: "/institutions/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /institutions/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /institutions/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /ethnic/list", () => {
	cy.request({ url: "/ethnic/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /ethnic/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /ethnic/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /places/list", () => {
	cy.request({ url: "/places/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /places/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /places/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /narratives/list", () => {
	cy.request({ url: "/narratives/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /narratives/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /narratives/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /works/list", () => {
	cy.request({ url: "/works/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /works/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /works/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /studies/list", () => {
	cy.request({ url: "/studies/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /studies/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /studies/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/place/list", () => {
	cy.request({ url: "/manuscripts/place/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/place/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/place/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/{insid}/list (as /manuscripts/INS0003BAV/list)", () => {
	cy.request({ url: "/manuscripts/INS0003BAV/list", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/INS0003BAV/list responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/INS0003BAV/list responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts", () => {
	cy.request({ url: "/manuscripts", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /works", () => {
	cy.request({ url: "/works", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /works responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /works responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /narratives", () => {
	cy.request({ url: "/narratives", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /narratives responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /narratives responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /places", () => {
	cy.request({ url: "/places", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /places responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /places responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /persons", () => {
	cy.request({ url: "/persons", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /persons responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /persons responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /institutions", () => {
	cy.request({ url: "/institutions", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /institutions responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /institutions responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /studies", () => {
	cy.request({ url: "/studies", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /studies responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /studies responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /decorations", () => {
	cy.request({ url: "/decorations", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /decorations responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /decorations responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /titles", () => {
	cy.request({ url: "/titles", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /titles responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /titles responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /paratexts", () => {
	cy.request({ url: "/paratexts", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /paratexts responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /paratexts responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /calendar", () => {
	cy.request({ url: "/calendar", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /calendar responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /calendar responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /bindings", () => {
	cy.request({ url: "/bindings", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /bindings responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /bindings responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /xpath", () => {
	cy.request({ url: "/xpath", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /xpath responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /xpath responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /sparql", () => {
	cy.request({ url: "/sparql", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /sparql responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /sparql responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /bibliography", () => {
	cy.request({ url: "/bibliography", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /bibliography responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /bibliography responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /additions", () => {
	cy.request({ url: "/additions", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /additions responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /additions responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /IndexPlaces", () => {
	cy.request({ url: "/IndexPlaces", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /IndexPlaces responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /IndexPlaces responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /IndexPersons", () => {
	cy.request({ url: "/IndexPersons", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /IndexPersons responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /IndexPersons responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{idWithPassage} (as /LIT1367Exodus_ED_a.xml)", () => {
	cy.request({ url: "/LIT1367Exodus_ED_a.xml", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /LIT1367Exodus_ED_a.xml responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /LIT1367Exodus_ED_a.xml responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /", () => {
	cy.request({ url: "/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET / responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET / responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /manuscripts/", () => {
	cy.request({ url: "/manuscripts/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/ responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/ responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /works/", () => {
	cy.request({ url: "/works/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /works/ responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /works/ responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /narratives/", () => {
	cy.request({ url: "/narratives/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /narratives/ responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /narratives/ responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /places/", () => {
	cy.request({ url: "/places/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /places/ responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /places/ responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /persons/", () => {
	cy.request({ url: "/persons/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /persons/ responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /persons/ responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /institutions/", () => {
	cy.request({ url: "/institutions/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /institutions/ responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /institutions/ responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /studies/", () => {
	cy.request({ url: "/studies/", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /studies/ responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /studies/ responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{collection}/{id}/time (as /manuscripts/BAVet1/time)", () => {
	cy.request({ url: "/manuscripts/BAVet1/time", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /manuscripts/BAVet1/time responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /manuscripts/BAVet1/time responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /morpho/{subpath} (as /morpho/test)", () => {
	cy.request({ url: "/morpho/test", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /morpho/test responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /morpho/test responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /Dillmann/{path} (as /Dillmann/test)", () => {
	cy.request({ url: "/Dillmann/test", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /Dillmann/test responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /Dillmann/test responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}.pdf (as /BAVet1.pdf)", () => {
	cy.request({ url: "/BAVet1.pdf", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1.pdf responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1.pdf responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{id}/time (as /BAVet1/time)", () => {
	cy.request({ url: "/BAVet1/time", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /BAVet1/time responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /BAVet1/time responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /{path}.html (as /test.html)", () => {
	cy.request({ url: "/test.html", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /test.html responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /test.html responded with ${res.status}`).to.not.equal(405);
	});
});

it("GET /openapi/{file}.json (as /openapi/test.json)", () => {
	cy.request({ url: "/openapi/test.json", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /openapi/test.json responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /openapi/test.json responded with ${res.status}`).to.not.equal(405);
	});
});
