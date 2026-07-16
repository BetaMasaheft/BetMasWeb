xquery version "3.1" encoding "UTF-8";

(:~
 : module with the main nav bar and the modals it calls
 : @author Pietro Liuzzo
 :)
module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace locallogin = "https://www.betamasaheft.eu/login" at "xmldb:exist:///db/apps/BetMasWeb/modules/login.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

declare function nav:modalsNew() {
	<div class="w3-modal" id="versionInfo">
		<div class="w3-modal-content">
			<div class="w3-container">
				<span
					class="w3-button w3-display-topright"
					onclick="document.getElementById('versionInfo').style.display='none'"
				><i class="fa fa-times" /></span>
				<p> You are looking at work in progress version of this website.
                    For questions <a
						href="mailto:eugenia.sokolinski@uni-hamburg.de?Subject=Issue%20Report%20BetaMasaheft"
					>contact the dev team</a>.</p>
				<p> Hover on words to see search options.</p>
				<p>Double-click to see morphological parsing.</p>
				<p
				> Click on left pointing hands and arrows to load related items and click once more to view the result in a popup.</p>
			</div>
		</div>
	</div>
};

declare function nav:barNew() {
	let $url := try { request:get-url() } catch * { "" }
	return (
		<div class="w3-top">
			<div class="w3-bar w3-black w3-card">
				<a
					class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  w3-hide-medium w3-hide-large w3-left"
					href="javascript:void(0)"
					onclick="myFunction()"
					title="Toggle Navigation Menu"
				><i class="fa fa-bars" /></a>
				{
					(: if (ends-with($url, '.html') or ($url = $config:appUrl) or ($url = 'https://betamasaheft.eu/')  or ($url = 'http://localhost/') or ends-with($url, 'BetMas/')) then :)
					locallogin:loginNew()
				(: else
                        () :)
				}
				<a class="w3-padding w3-hover-red w3-hide-small w3-left" href="{ $config:appUrl }/index.html">
					<i class="fa fa-home" />
				</a>
				<div class="w3-dropdown-hover w3-hide-small" id="introductory">
					<button class=" w3-button" onclick="window.location.href='{ $config:appUrl }/about.html'" title="About">
						{
							if (string-length($url) gt 1) then (
								"Hi " || sm:id()//sm:username/text() || "!"
							) else (
								"About"
							)
						}
						<i class="fa fa-caret-down" />
					</button>
					<div class="w3-dropdown-content" style="background:transparent;">
						<div class="w3-col" style="width:100%">
							<div class="w3-container w3-left-align w3-sand w3-display-container w3-small" id="generalinfo">
								<span
									class="w3-button w3-text-red w3-large w3-display-topright"
									onclick="this.parentElement.style.display='none'"
									style="display:block; background:transparent;"
								>&#x2716;</span>
								<span
									style="display:block;"
								>Here you can explore some general information about the project. See also <a
										href="https://www.betamasaheft.uni-hamburg.de"
										target="_blank"
									>Beta maṣāḥəft</a> institutional web page. Select <a
										href="https://betamasaheft.eu/about.html"
									>About</a> to meet the project team and our partners. Visit the
                    <a
										href="https://betamasaheft.eu/Guidelines"
									>
                        Guidelines</a> section to learn about our encoding principles. The section <a
										href="https://betamasaheft.eu/lod.html"
									>Data</a> contains the Linked Open Data information, and <a
										href="https://betamasaheft.eu/apidoc.html"
									>API</a> the Application Programming Interface documentation for those who want to exchange data with the Beta maṣāḥǝft project. The <a
										href="https://betamasaheft.eu/pid.html"
									>Permalinks</a> section documents the versioning and referencing earlier versions of each record.</span>
							</div>
							<div class="w3-bar w3-card-4 w3-white" id="navexplanationintro">
								{
									if (
										sm:is-authenticated() and contains(sm:get-user-groups(sm:id()//sm:username/text()), "Editors")
									) then (
										<a
											class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
											href="{ $config:appUrl }/user/{ sm:id()//sm:real/sm:username/string() }"
										>Your personal page</a>,
										<a
											class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red"
											href="{ $config:appUrl }/clavismatching.html"
										>Clavis Matching</a>
									) else (
									)
								}
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="back"
									href="{ $config:appUrl }"
								>Home</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="ab"
									href="{ $config:appUrl }/about.html"
								>About</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="guides"
									href="{ $config:appUrl }/Guidelines/"
								>Guidelines</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="loddata"
									href="{ $config:appUrl }/lod.html"
								>Data</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="apidata"
									href="{ $config:appUrl }/apidoc.html"
								>API</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="permlink"
									href="{ $config:appUrl }/pid.html"
								>Permalinks</a>
							</div>
							<div class="w3-row" id="explanationsIntro">
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="back"
								>
                                    Click to get back to the home page.</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="ab"
								>
                                    Here you can find out more about the <a
										href="{ $config:appUrl }/team"
									>project team</a>,
                                    the <a
										href="https://www.betamasaheft.uni-hamburg.de/team/partners.html"
									>cooperating projects</a>,
                                    and the <a
										href="{ $config:appUrl }/contacts"
									>contact information</a>. You can also visit
                                     <a
										href="https://www.betamasaheft.uni-hamburg.de/"
									>our institutional page</a>.
</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="guides"
								>
                                    Find out more about our <a
										href="{ $config:appUrl }/Guidelines"
									>Encoding Guidelines</a>.
</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="loddata"
								>
                                    In this section our Linked Open Data principles are explained.
                                    </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="apidata"
								>
                                    Developers can find our Application Programming Interface documentation here.
                                    </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="permlink"
								>
                                    The page documents the use of permalinks by the project.
                                    </span>
							</div>
						</div>
						<div class="w3-col w3-rest" />
					</div>
				</div>
				<div class="w3-dropdown-hover w3-hide-small" id="mss">
					<button
						class=" w3-button"
						onclick="window.location.href='{ $config:appUrl }/index.html#manuscripts'"
						title="Manuscripts"
					>Manuscripts <i class="fa fa-caret-down" /></button>
					<div class="w3-dropdown-content" style="background:transparent;">
						<div class="w3-col" style="width:100%">
							<div class="w3-container w3-left-align w3-sand w3-display-container w3-small" id="manuscriptsmenuintro">
								<span
									class="w3-button w3-text-red w3-large w3-display-topright"
									onclick="this.parentElement.style.display='none'"
									style="display:block; background:transparent;"
								>&#x2716;</span>
								<span
									style="display:block;"
								>Descriptions of (predominantly) Christian
                                manuscripts from Ethiopia and Eritrea are the core of the Beta maṣāḥǝft project.
                                We (1) gradually encode descriptions from printed catalogues, beginning
                                from the historical ones,
                                (2) incorporate digital descriptions produced by other projects, adjusting
                                them wherever possible,
                                and (3) produce descriptions of previously unknown and/or uncatalogued
                                manuscripts.
                                The encoding follows the TEI XML standards (check our
                                <a
										href="https://betamasaheft.eu/Guidelines/?id=manuscripts"
									>
                                guidelines</a>).</span>
							</div>
							<div class=" w3-bar w3-card-4 w3-white">
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="shelfmarks"
									href="{ $config:appUrl }/manuscripts/browse"
								>Shelf marks (full list)</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="manuscriptsearch"
									href="{ $config:appUrl }/newSearch.html?searchType=text&amp;mode=any&amp;work-types=mss"
								>Manuscripts (search)</a>
								<!--
                             limitation of access to expensive requests (this was actually never requested over a year)
                             <a
                                    class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
                                    data-value="imagesviewer"
                                    href="{$config:appUrl}/manuscripts/viewer">Images Viewer</a>-->
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="digitized"
									href="{ $config:appUrl }/availableImages.html"
								>List of Digitized Manuscripts</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="cataloguesencoded"
									href="{ $config:appUrl }/catalogues/list"
								>Catalogues Encoded</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="inscriptions"
									href="{ $config:appUrl }/newSearch.html?searchType=text&amp;mode=any&amp;form=Inscription"
								>Inscriptions</a>
							</div>
							<div class="w3-row" id="navexplanationsmss">
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="shelfmarks"
								>
                                    Here you can browse a full list of manuscripts available on the platform,
                                    arranged by repositories and shelf marks (clicking on the "show list" button will expand the list for each location). </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="manuscriptsearch"
								>
                                    This menu takes you to the search form listing all manuscripts encoded
                                    by the project. On the left side you get filters based on the indexes for
                                    that type of resources in the database, on the right side you will see your search results in a multi-page table (20 per page). You can refine the results by applying the filters.
</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="digitized"
								>
                                    Here you can view a list of manuscripts that have digitized images available online elsewhere.
</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="cataloguesencoded"
								>
                                    The list of manuscript catalogues that were used as sources for our records.
                                    Clicking on one of the titles will open a list view with all the
                                    manuscripts in that catalogue
                                    that have been encoded.</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="inscriptions"
								>
                                   Inscriptions
                                   are an inseparable part of the manuscript tradition and its direct precursors,
                                   therefore we also offer the encoding of the known inscriptions from Ethiopia and
                                   Eritrea
                                   wherever possible. Part of the encoding is carried out in Hamburg, part is
                                   the result of
                                   cooperation with other projects, such as
                                   <a
										href="http://dasi.cnr.it/"
									>DASI: Digital Archive for the Study of pre-islamic
                                   Arabian Inscriptions</a>.
</span>
							</div>
						</div>
						<div class="w3-col w3-rest" />
					</div>
				</div>
				<div class="w3-dropdown-hover w3-hide-small" id="works">
					<button
						class=" w3-button"
						onclick="window.location.href='{ $config:appUrl }/index.html#texts'"
						title="Works"
					>Texts <i class="fa fa-caret-down" /></button>
					<div class="w3-dropdown-content" style="background:transparent;">
						<div class="w3-col" style="width:100%">
							<div class="w3-container w3-left-align w3-sand w3-display-container w3-small">
								<span
									class="w3-button w3-text-red w3-large w3-display-topright"
									onclick="this.parentElement.style.display='none'"
									style="display:block; background:transparent;"
								>&#x2716;</span>
								<span
									style="display:block;"
								>We identify each unit of content in every manuscript. We consider any
                        text with an independent circulation a work, with its own identification number within
                        the <a
										href="https://betamasaheft.eu/clavis-list.html"
									>Clavis Aethiopica (CAe)</a>. Parts of texts (e.g. chapters)
                        without independent circulation (univocally identifiable by IDs assigned within the records) or recurrent
                        motifs as well as documentary additional texts
                        (identified as <a
										href="https://betamasaheft.eu/narratives/list"
									>Narrative Units</a>)
                        are not part of the CAe. You can also check the list of different <a
										href="titles"
									>types of
                        text titles</a> or various <a
										href="https://betamasaheft.eu/indexeslist.html"
									>Indexes</a>
                        available from the top menu.</span>
							</div>
							<div class="w3-bar w3-card-4 w3-white">
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="clavis"
									href="{ $config:appUrl }/clavis-list.html"
								>Clavis Aethiopica (Works)</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="narratives"
									href="{ $config:appUrl }/narratives/list"
								>Narrative Units</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="documentary"
									href="{ $config:appUrl }/documentcorpora.html"
								>Documentary corpora</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="studies"
									href="{ $config:appUrl }/studies/list"
								>Studies</a>
							</div>
							<div class="w3-row" id="explanationsTexts">
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="clavis"
								>
                                    The clavis is a repertory of all known works relevant for the Ethiopian and Eritrean tradition; the work being defined as any text with an independent circulation.
                                    Each work (as well as known recensions where applicable) receives a unique identifier in the Clavis Aethiopica (CAe).
In the filter search offered here one can search for a work by its title, a keyword, a short quotation, but also directly by its
CAe identifier - or, wherever known and provided, identifier used
by other claves, including Bibliotheca Hagiographica Graeca (BHG),
Clavis Patrum Graecorum (CPG), Clavis Coptica (CC),
Clavis Apocryphorum Veteris Testamenti (CAVT), Clavis Apocryphorum Novi Testamenti (CANT), etc.
                                    </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="narratives"
								>
                                    The project additionally identifies Narrative Units to refer to text types, where no clavis identification is possible or necessary. Recurring motifs or also frequently documentary
                                    additiones are assigned a Narrative Unit ID, or thematically clearly demarkated passages
                                    from various recensions of a larger work.
                                    </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="documentary"
								>
                                    This list view shows the documentary collections encoded by the project <a
										href="https://hal.ird.fr/CEMAF/halshs-01871649v1"
										target="_blank"
									>Ethiopian Manuscript Archives (EMA)</a> and its successor <a
										href="https://anr.fr/en/funded-projects-and-impact/funded-projects/project/funded/project/b2d9d3668f92a3b9fbbf7866072501ef-5ddfbccfcf/"
									>EthioChrisProcess - Christianization and religious interactions in Ethiopia (6th-13th century) : comparative approaches with Nubia and Egypt</a>, which aim to edit the corpus of administrative acts
of the Christian kingdom of Ethiopia, for medieval and modern periods.
See also <a
										href="https://betamasaheft.eu/additions"
									>the list of documents contained in the additiones</a> in the manuscripts described by the Beta maṣāḥǝft project .
</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="studies"
								>
                                   Works of interest to Ethiopian and Eritrean studies.
                                   </span>
							</div>
						</div>
						<div class="w3-col w3-rest" />
					</div>
				</div>
				<div class="w3-dropdown-hover w3-hide-small">
					<button
						class=" w3-button"
						onclick="window.location.href='{ $config:appUrl }/index.html#taxonomy'"
						title="Art"
					>Art Themes <i class="fa fa-caret-down" /></button>
					<div class="w3-dropdown-content" style="background:transparent;">
						<div class="w3-col" style="width:100%">
							<div class="w3-container w3-left-align w3-sand w3-display-container w3-small">
								<span
									class="w3-button w3-text-red w3-large w3-display-topright"
									onclick="this.parentElement.style.display='none'"
									style="display:block; background:transparent;"
								>&#x2716;</span>
								<span
									style="display:block;"
								>While encoding manuscripts, the project Beta maṣāḥǝft aims at creating an
                        exhaustive repertory of art themes and techniques present in Ethiopian
                        and Eritrean Christian tradition. See our <a
										href="https://betamasaheft.eu/Guidelines/?id=decorationDescription"
									>
                        encoding guidelines</a> for details.

Two types of searches for aspects of manuscript decoration are possible,
the decorations filtered search and the general keyword search.</span>
							</div>
							<div class="w3-bar w3-card-4 w3-white">
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="decorations"
									href="{ $config:appUrl }/decorations"
								>Index of decorations</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="artkeywords"
									href="{ $config:appUrl }/art-themes/list"
								>Art Keywords</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="illuminations"
									href="{ $config:appUrl }/decorations?type=miniature"
								>Illuminations</a>
							</div>
							<div class="w3-row" id="explanationsAT">
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="decorations"
								>
                                   The filtered search for decorations, originally designed with Jacopo Gnisci,
                                   looks at decorations and their features only. The filters on the left are relative
                                   only to the selected features, reading the legends will help you to figure out
                                   what you can filter. For example you can search for all encoded decorations of a specific art
                                   theme, or search the encoded legends. If the decorations are present, but not encoded, you
                                   will not get them in the results. If an image is available, you will also find a thumbnail linking
                                   to the image viewer. [NB: The Index of Decorations currently often times out, we are sorry for the inconvenience.]
                                   </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="artkeywords"
								>
                                    You can search for particular motifs or aspects, including style, also through the keyword search. Just click on "Art keywords" and "Art themes" on the left to browse through the options.</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="illuminations"
								>
                                   This is a short cut to a search for all those manuscripts which have miniatures of which we
                                   have images.</span>
							</div>
						</div>
						<div class="w3-col w3-rest" />
					</div>
				</div>
				<div class="w3-dropdown-hover w3-hide-small" id="places">
					<button
						class=" w3-button"
						onclick="window.location.href='{ $config:appUrl }/index.html#gazetteer'"
						title="Places"
					>Places <i class="fa fa-caret-down" /></button>
					<div class="w3-dropdown-content" style="background:transparent;">
						<div class="w3-col" style="width:100%">
							<div class="w3-container w3-left-align w3-sand w3-display-container w3-small">
								<span
									class="w3-button w3-text-red w3-large w3-display-topright"
									onclick="this.parentElement.style.display='none'"
									style="display:block; background:transparent;"
								>&#x2716;</span>
								<span
									style="display:block;"
								>We create metadata for all places associated with the manuscript production and
                        circulation as well as those mentioned in the texts used by the project.
                        The encoding of places in Beta maṣāḥǝft will thus result in a
                        Gazetteer of the Ethiopian tradition. We follow the principles established by
                        <a
										href="https://pleiades.stoa.org/places"
									>Pleiades</a> and lined out in the
                        <a
										href="http://syriaca.org/geo/index.html"
									>Syriaca.org TEI
                        Manual and Schema for Historical Geography</a> which allow us to distinguish
                        between places, locations, and names of places.
See also <a
										href="https://betamasaheft.eu/help.html"
									>Help page</a> fore more guidance.
                       </span>
							</div>
							<div class=" w3-bar w3-card-4 w3-white">
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="pl"
									href="{ $config:appUrl }/places/list"
								>Places</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="repositories"
									href="{ $config:appUrl }/institutions/list"
								>Repositories</a>
							</div>
							<div class="w3-row" id="explanationPl">
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="pl"
								>
                                  This tab offers a filtrable list of all available places.
                                  Geographical references of the type "land inhabited by people XXX"
                                  is encoded with the reference to the corresponding Ethnic unit (see below);
                                  ethnonyms, even those used in geographical contexts, do not appear in this list.
                                  </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="repositories"
								>
                                 Repositories are those locations where manuscripts encoded by the project are or
                                 used to be preserved. While they
                                 are encoded in the same way as all places are, the view offered is different,
                                 showing a list of manuscripts associated with the repository. </span>
							</div>
						</div>
						<div class="w3-col w3-rest" />
					</div>
				</div>
				<div class="w3-dropdown-hover w3-hide-small" id="persons">
					<button
						class="w3-button"
						onclick="window.location.href='{ $config:appUrl }/index.html#prosopography'"
						title="Persons"
					>Persons <i class="fa fa-caret-down" /></button>
					<div class="w3-dropdown-content" style="background:transparent;">
						<div class="w3-col" style="width:100%">
							<div class="w3-container w3-left-align w3-sand w3-display-container w3-small">
								<span
									class="w3-button w3-text-red w3-large w3-display-topright"
									onclick="this.parentElement.style.display='none'"
									style="display:block; background:transparent;"
								>&#x2716;</span>
								<span
									style="display:block;"
								>We create metadata for all persons (and groups of persons) associated with the
                       manuscript production and circulation (rulers, religious authorities, scribes,
                       donors, and commissioners) as well as those mentioned in the texts used by the
                       project. The result will be a
                       comprehensive Prosopography of the Ethiopian and Eritrean tradition.
                       See also <a
										href="https://betamasaheft.eu/help.html"
									>Help page</a> for
                       more guidance.</span>
							</div>
							<div class=" w3-bar w3-card-4 w3-white">
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="pers"
									href="{ $config:appUrl }/persons/list"
								>Persons and groups</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red  explain"
									data-value="ethnics"
									href="{ $config:appUrl }/ethnic/list"
								>Ethnic units</a>
							</div>
							<div class="w3-row" id="explanationPr">
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="pers"
								>
                                  We encode persons according to our
                                  <a
										href="https://betamasaheft.eu/Guidelines/?id=persons"
									>Encoding Guidelines</a>.
                                  The initial list was
                                  inherited from the <a
										href="https://www.aai.uni-hamburg.de/en/ethiostudies/research/encyclopaedia/eae.html"
									>Encyclopaedia Aethiopica</a>,
                                  and there are still many inconsistencies that we are trying to gradually fix.</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="ethnics"
								>
                                  We consider ethnonyms as a subcategory of personal names, even when
                                  many are often used in literary works in the context of the
                                  "land inhabited by **". The present list of records has been mostly
                                  inherited from the <a
										href="https://www.aai.uni-hamburg.de/en/ethiostudies/research/encyclopaedia/eae.html"
									>Encyclopaedia Aethiopica</a>,
                                  and there are still many inconsistencies that we are trying to gradually fix.</span>
							</div>
						</div>
						<div class="w3-col w3-rest" />
					</div>
				</div>
				<div class="w3-dropdown-hover w3-hide-small w3-hide-medium" id="res">
					<button class=" w3-button " title="Resources">Resources <i class="fa fa-caret-down" /></button>
					<div class="w3-dropdown-content" style="background:transparent;">
						<div class="w3-col" style="width:100%">
							<div class="w3-container w3-left-align w3-sand w3-display-container w3-small" id="resourcesintro">
								<span
									class="w3-button w3-text-red w3-large w3-display-topright"
									onclick="this.parentElement.style.display='none'"
									style="display:block; background:transparent;"
								>&#x2716;</span>
								<span
									style="display:block;"
								>This section collects some additional resources offered by the project. Select <a
										href="{ $config:appUrl }/bibliography"
									>Bibliography</a> to explore the references cited in the project records. The
                    <a
										href="{ $config:appUrl }/indexeslist.html"
									>
                        Indexes</a> list different types of project records (persons, places, titles, keywords, etc).
                    Visit <a
										href="{ $config:appUrl }/projects.html"
									>Projects</a> for information on partners that have input data
                    directly in the Beta maṣāḥǝft database. Special ways of exploring the data are offered under
                    <a
										href="{ $config:appUrl }/visualizations.html"
									>Visualizations</a>.
                    Two applications were developed in cooperation with the project
                    <a
										href="https://www.traces.uni-hamburg.de/"
									>TraCES</a>,
                    the <a
										href="{ $config:appUrl }/morpho"
									>Gǝʿǝz Morphological Parser</a> and the
                    <a
										href="{ $config:appUrl }/Dillmann"
									>Online <i>Lexicon Linguae Aethiopicae</i></a>.</span>
							</div>
							<div class=" w3-bar w3-card-4 w3-white">
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="bibl"
									href="{ $config:appUrl }/bibliography"
								>Bibliography</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="ind"
									href="{ $config:appUrl }/indexeslist.html"
								>Indexes</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="proj"
									href="{ $config:appUrl }/projects.html"
								>Projects</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="views"
									href="{ $config:appUrl }/visualizations.html"
								>Visualizations</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="parser"
									href="{ $config:appUrl }/morpho"
								>Gǝʿǝz Morphological Parser</a>
								<a
									class="w3-bar-item w3-button w3-margin w3-padding w3-round w3-border w3-border-red explain"
									data-value="lexicon"
									href="{ $config:appUrl }/Dillmann"
								>Online <i>Lexicon Linguae Aethiopicae</i></a>
							</div>
							<div class="w3-row" id="navexplanationsRes">
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="bibl"
								>
                    Here you can view all references (extracted from Zotero) that have been cited in project records.</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="ind"
								>
                    The Indexes list different types of project records (persons, places, titles, keywords, etc).</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="proj"
								>
                    These associated projects have fed their data directly in the
                    Beta maṣāḥǝft database.  </span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="views"
								>
                    Check some special ways of exploring our data, including comparing manuscripts containing the same work,
                    mapping manuscripts with a given content, collating passages, searching for gender aspects, and many more.</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="parser"
								>
                    The experimental morphological parser was developed in cooperation with the project
                    <a
										href="https://www.traces.uni-hamburg.de/"
									>TraCES: From Translation to Creation: Changes in Ethiopic Style and Lexicon from Late Antiquity to the Middle Ages</a>.</span>
								<span
									class="w3-hide w3-red w3-center w3-padding"
									id="lexicon"
								>
                    This application uses basic techniques to display data from the digitization process of the
                    <i
									>Lexicon Linguae Aethiopicae</i> by August Dillmann, with additions by the
                    team of the project <a
										href="https://www.traces.uni-hamburg.de/"
									>TraCES: From Translation to Creation: Changes in
                    Ethiopic Style and Lexicon from Late Antiquity to the Middle Ages</a>.</span>
							</div>
						</div>
						<div class="w3-col w3-rest" />
					</div>
				</div>
				<a
					class="w3-bar-item w3-button  w3-hide-medium w3-hide-small"
					data-placement="bottom"
					data-toggle="tooltip"
					href="{ $config:appUrl }/help.html"
					title="How to navigate"
				>Help</a>
				{ nav:newentryNew() }
				{
					if (contains($url, "newSearch.html")) then (
					) else
						<a class="w3-padding w3-hover-red w3-hide-small w3-right" href="{ $config:appUrl }/simpleSearch.html">
							<i class="fa fa-search" />
						</a>
				}
			</div>
		</div>,
		<div class="w3-bar-block w3-black w3-hide w3-hide-large w3-hide-medium w3-top" id="navDemo" style="margin-top:46px">
			<a class="w3-bar-item w3-button w3-padding-large" href="{ $config:appUrl }" onclick="myFunction()">Home</a>
			<a
				class="w3-bar-item w3-button w3-padding-large"
				href="{ $config:appUrl }/works/list"
				onclick="myFunction()"
			>Texts</a>
			<a
				class="w3-bar-item w3-button w3-padding-large"
				href="{ $config:appUrl }/manuscripts/list"
				onclick="myFunction()"
			>Manuscripts</a>
			<a
				class="w3-bar-item w3-button w3-padding-large"
				href="{ $config:appUrl }/simpleSearch.html"
				onclick="myFunction()"
			>Search</a>
		</div>
	)
};

declare function nav:newentryNew() {
	if (contains(sm:get-user-groups(sm:id()//sm:real/sm:username/string()), "Editors")) then
		<form
			action="{ $config:appUrl }/newentry.html"
			class="w3-bar-item w3-hide-medium w3-hide-small"
			role="tag"
			style="margin:0;padding:0"
		>
			<select class="w3-bar-item w3-select  w3-twothird" name="collection" required="required">
				<option value="manuscripts">manuscript</option>
				<option value="persons">person</option>
				<option value="works">work</option>
				<option value="narratives">narrative</option>
				<option value="studies">study</option>
				<option value="places">place</option>
				<option value="authority-files">authority file</option>
				<option value="institutions">institution</option>
			</select>
			<button class="w3-bar-item w3-button  w3-red  w3-third" type="submit">new</button>
		</form>
	else (
	)
};

declare function nav:footerNew() {
	<footer class="w3-container w3-padding-64 w3-center w3-small" id="footer">
		<div class="w3-third">
			<div class="w3-margin">
				<p style="margin-left:50;text-align:left;">Copyright © <span
						property="http://purl.org/dc/elements/1.1/publisher"
					>Akademie der Wissenschaften in Hamburg,
                    Hiob-Ludolf-Zentrum für Äthiopistik</span>. Sharing and remixing permitted under terms of the
                    <a
						href="http://creativecommons.org/licenses/by-nc-sa/4.0/"
						property="http://creativecommons.org/ns#license"
						rel="license"
					>Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License <img
							alt="Creative Commons License"
							src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png"
							style="border-width:0" />
					</a>. Project DOI: { $config:DOI }.
               </p>
				<!--      <div id="wcb" class="carbonbadge w3-row"></div>-->
			</div>
		</div>
		<div class="w3-third">
			<div class=" w3-container w3-border-left w3-margin">
				<div class="w3-half">
					<div class="w3-bar-block">
						<a
							class="w3-bar-item"
							href="http://www.awhamburg.de/"
							property="http://purl.org/dc/elements/1.1/publisher"
							target="_blank"
						>
							<img
								alt="Akademie der Wissenschaften in Hamburg logo"
								src="resources/images/logo-adw.png"
								style="border-width:0"
								width="100%" />
						</a>
						<a
							class="w3-bar-item"
							href="https://www.betamasaheft.uni-hamburg.de/"
							property="http://purl.org/dc/elements/1.1/publisher"
							target="_blank"
						>
							<img
								alt="Beta maṣāḥǝft Project logo"
								src="resources/images/logo.png"
								style="border-width:0"
								width="100%" />
						</a>
					</div>
				</div>
				<div class="w3-half">
					<p style="text-align:left;">The domain betamasaheft.eu is hosted by Universität Hamburg.</p>
					<p style="text-align:left;">This website is maintained by the project team at the <a
							href="https://www.aai.uni-hamburg.de/en/ethiostudies.html"
						>Hiob Ludolf Center for Ethiopian and Eritrean Studies</a>.</p>
					<p style="text-align:left;"><a href="{ $config:appUrl }/impressum.html">Impressum.</a></p>
				</div>
			</div>
		</div>
		<div class="w3-third">
			<div class="w3-container w3-margin w3-border-left" style="text-align:left">
				<div class="w3-margin">
					<div class="w3-bar">
						<a class="w3-bar-item" href="http://www.tei-c.org/">
							<img alt="We use TEI" src="resources/images/We-use-TEI.png" width="100" />
						</a>
						<a class="w3-bar-item" href="https://iiif.io/">
							<img
								alt="Providing and resuing images with IIIF presentation API 2.0"
								src="resources/images/iiif.png"
								width="50" />
						</a>
						<a class=" w3-bar-item" href="http://exist-db.org">
							<img alt="Powered by eXist-db" src="$shared/resources/images/powered-by.svg" width="100" />
						</a>
					</div>
					<div class="w3-bar">
						<a class="w3-bar-item" href="https://www.zotero.org/groups/358366/ethiostudies/items">
							<img alt="All bibliography is managed with Zotero." src="resources/images/zotero_logo.png" width="40" />
						</a>
						<a class="w3-bar-item" href="https://github.com/BetaMasaheft">
							<img alt="Our data is all in GitHub!" src="resources/images/GitHub-Mark-120px-plus.png" width="40" />
						</a>
						<a class=" w3-bar-item" href="http://commons.pelagios.org/">
							<img
								alt="Proud members of the Linked Pasts Network"
								src="resources/images/Pelagios-logo.png"
								width="90" />
						</a>
						<a class="w3-bar-item" href="https://iipimage.sourceforge.io/">
							<img alt="We use the IIP Image Server" src="resources/images/iip_logo.png" width="40" />
						</a>
					</div>
					<p>Powered by <a href="https://www.w3schools.com/w3css/default.asp" target="_blank">w3.css</a></p>
					<p
					>Many thanks for their wonderful work to all the developers of free software for the code we use throughout the website.</p>
				</div>
			</div>
		</div>
	</footer>
};
