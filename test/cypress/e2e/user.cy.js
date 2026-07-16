// generated from db/apps/BetMasWeb/restviews/user.xqm

it("GET /user/{username} (as /user/testuser)", () => {
	cy.request({ url: "/user/testuser", method: "GET", failOnStatusCode: false }).then((res) => {
		expect(res.status, `GET /user/testuser responded with ${res.status}`).to.not.equal(500);
		expect(res.status, `GET /user/testuser responded with ${res.status}`).to.not.equal(405);
	});
});
