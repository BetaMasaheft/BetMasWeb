// Text tab: the "Editions and translations" bar links each edition on this
// host, and ?edition= renders that edition rather than the first one.
// https://github.com/BetaMasaheft/BetMasWeb/issues/161

const work = "/works/LIT1709Kebran/text";

it("edition bar links stay on this host", () => {
	cy.request({ url: work, timeout: 90000 }).then((res) => {
		expect(res.status).to.eq(200);
		const bar = res.body.slice(res.body.indexOf("Editions and translations"));
		expect(bar).to.include("/works/LIT1709Kebran/text?edition=_ED_traces");
		expect(bar.slice(0, 2000)).to.not.include('href="https://betamasaheft.eu/LIT1709Kebran_ED_');
	});
});

["traces", "rhced"].forEach((edition) => {
	it(`?edition=_ED_${edition} renders that edition`, () => {
		cy.request({ url: `${work}?edition=_ED_${edition}`, timeout: 90000 }).then((res) => {
			expect(res.status).to.eq(200);
			expect(res.body).to.include(`id="transcription${edition}"`);
		});
	});
});
