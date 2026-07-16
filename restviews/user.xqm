xquery version "3.1" encoding "UTF-8";

(:~
 : module for the user personal page view
 :
 : @author Pietro Liuzzo
 :)
module namespace user = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/user";

(: For interacting with the TEI document :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: made up namespace for log :)
declare namespace l = "http://log.log";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

declare variable $user:logs := collection("/db/apps/log");

declare function user:personalPage($request as map(*)) {
	let $username as xs:string := $request?parameters?username
	let $un := sm:id()//sm:username/text()

	let $Imap := map {"type": "user", "name": ($un || "/" || $username)}

	return if (
		sm:is-dba($un) or
			(($username = $un) and sm:is-account-enabled($un) and sm:is-authenticated()) or
			doc("/db/apps/lists/editors.xml")//t:item[@n eq $username]
	) then (
		<html xmlns="http://www.w3.org/1999/xhtml">
			<head>
				<script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1" />
				<script src="resources/js/analytics.js" type="text/javascript" />
				<title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
				<link href="resources/images/minilogo.ico" rel="shortcut icon" />
				<meta content="width=device-width, initial-scale=1.0" name="viewport" />
				{ scriptlinks:scriptStyle() }
			</head>
			<body id="body">
				{ nav:barNew() }
				{ nav:modalsNew() }
				<div class="w3-container w3-margin w3-padding-64" id="content">
					<div class="w3-red w3-panel w3-card-4">
						<h2>Dear {
								$username
							}, thank you very much for all
                your nice work for the project! It could have not become this good without you!</h2>
					</div>
					<div class="w3-container">
						<div class="w3-panel w3-card-2 w3-gray">
							<h2>All about you... </h2>
							<p><b>User name: </b>{ $username }</p>
						</div>
						<div class="w3-half w3-padding">
							<div class="w3-margin w3-panel w3-card-4 ">
								{
									let $userinitials := editors:editorNames($username)
									let $changes := $exptit:col//t:change[(@who eq $userinitials) or (@who eq concat("#", $userinitials))]
									let $changed :=
										for $c in $changes
										order by $c/@when descending
										return $c
									return (
										<h3>Your latest 50 changes in files out of {
												count($changes)
											} you recorded in a change element</h3>,
										<div class="userpanel w3-responsive">
											<table class="w3-table w3-hoverable">
												<thead><tr><th>date and time</th><th>item</th><th>change content</th></tr></thead>
												<tbody>
													{
														for $itemchanged in subsequence($changed, 1, 50)
														let $root := root($itemchanged)
														let $id := $root//t:TEI/@xml:id
														group by $ID := $id
														let $title := exptit:printTitleID($ID)
														for $changeToItem in $itemchanged
														order by $changeToItem/@when descending
														return (
															<tr style="border-top: 4px solid #5bc0de">
																<td>{ format-date($changeToItem/@when, "[D01].[M01].[Y1]") }</td>
																<td><a href="/{ string($id[1]) }">{ string($id[1]) }</a></td>
																<td>{ $changeToItem/text() }</td>
															</tr>
														)
													}
												</tbody>
											</table>
										</div>
									)
								}
							</div>
						</div>
						<div class="w3-half w3-padding">
							<div class="w3-margin w3-panel w3-card-4 ">
								<h3>The last 50 pages you visited</h3>
								<div class=" w3-container userpanel w3-responsive">
									<table class="w3-table w3-hoverable">
										<thead><tr><th>type</th><th>date and time</th><th>info</th></tr></thead>
										<tbody>
											{
												let $selection :=
													for $c in
														$user:logs//l:logentry[l:user[. eq $username]][not(l:type eq "query")][not(
															contains(l:type, "XPath")
														)]
													order by $c/@timestamp descending
													return $c
												for $loggedentity in subsequence($selection, 1, 50)
												return <tr>
													<td>{ $loggedentity/l:type/text() }</td>
													<td>{ format-dateTime($loggedentity/@timestamp, "[D01].[M01].[Y1] [H01]:[m01]:[s01]") }</td>
													<td>
														<a
															href="{
																switch ($loggedentity/l:type)
																	case "compare" return
																		$config:appUrl || "/compare" || $loggedentity/l:url/text()
																	default return
																		$loggedentity/l:url/text()
															}"
														>{ $loggedentity/l:url/text() }</a>
													</td>
												</tr>
											}
										</tbody>
									</table>
								</div>
							</div>
						</div>
					</div>
					<div class="w3-container">
						<div class="w3-half w3-padding">
							<div class="w3-margin w3-panel w3-card-4 ">
								<h3>Your queries</h3>
								<div class="w3-container userpanel w3-responsive">
									<table class="w3-table w3-hoverable">
										<thead><tr><th>date</th><th>info</th></tr></thead>
										<tbody>
											{
												let $selection :=
													for $c in $user:logs//l:logentry[l:user[. eq $username]][l:type eq "query"]
													order by $c/@timestamp descending
													return $c
												for $loggedentity in subsequence($selection, 1, 50)
												let $link := "/search.html" || $loggedentity/l:url/text()
												return <tr>
													<td>{ format-dateTime($loggedentity/@timestamp, "[D01].[M01].[Y1] [H01]:[m01]:[s01]") }</td>
													<td><a href="{ $link }">{ $loggedentity/l:url/text() }</a></td>
												</tr>
											}
										</tbody>
									</table>
								</div>
							</div>
						</div>
						<div class="w3-half w3-padding">
							<div class="w3-margin w3-panel w3-card-4 ">
								<h3>Your XPATHs</h3>
								<div class="userpanel w3-responsive">
									<table class="w3-table w3-hoverable">
										<thead><tr><th>date</th><th>info</th></tr></thead>
										<tbody>
											{
												let $selection :=
													for $c in $user:logs//l:logentry[l:user[. eq $username]][contains(l:type, "XPath")]
													order by $c/@timestamp descending
													return $c
												for $loggedentity in subsequence($selection, 1, 50)
												let $link := "/xpath?xpath=" || $loggedentity/l:url/text()
												return <tr>
													<td>{ format-dateTime($loggedentity/@timestamp, "[D01].[M01].[Y1] [H01]:[m01]:[s01]") }</td>
													<td><a href="{ $link }">{ $loggedentity/l:url/text() }</a></td>
												</tr>
											}
										</tbody>
									</table>
								</div>
							</div>
						</div>
					</div>
					{
						if (sm:is-authenticated()) then
							<div class="w3-panel w3-card-4 w3-padding">
								<h3>Manage your account</h3>
								<div class="w3-container">
									<h4>change email</h4>
									<form action="/user/changemail.xql" method="POST">
										<label for="exampleInputEmail1">Email address</label>
										<input
											aria-describedby="emailHelp"
											class="w3-input w3-border"
											id="email"
											name="email"
											placeholder="Enter email"
											type="email" />
										<small id="emailHelp">This is needed for the website notifications.</small>
										<br />
										<button class="w3-button w3-red" type="submit">Submit</button>
									</form>
								</div>
								<div class="w3-container ">
									<h4>Change password</h4>
									<form action="/user/changepw.xql" method="POST">
										<label for="exampleInputEmail1">Email address</label>
										<input
											aria-describedby="emailHelp"
											class="w3-input w3-border"
											id="email"
											name="email"
											placeholder="Enter email"
											type="email" />
										<small
											class="form-text text-muted"
											id="emailHelp"
										>This is needed for the website notifications.</small>
										<label for="exampleInputPassword1">Old Password</label>
										<input
											class="w3-input w3-border"
											id="oldpassword"
											name="oldpassword"
											placeholder="Old Password"
											type="password" />
										<label for="exampleInputPassword1">New Password</label>
										<input
											class="w3-input w3-border"
											id="newpassword"
											name="newpassword"
											placeholder="New Password"
											type="password" />
										<button class="w3-button w3-red" type="submit">Submit</button>
									</form>
								</div>
							</div>
						else (
						)
					}
					{
						if (sm:is-dba(sm:id()//sm:real/sm:username/string())) then (
							<div class="w3-panel w3-card-4 w3-padding">
								<h3>Create new account</h3>
								<form action="/user/createaccount.xql" method="POST">
									<label for="fn">Full name</label>
									<input
										aria-describedby="emailHelp"
										class="form-control"
										id="fn"
										name="fullName"
										placeholder="Enter your full name"
										required="required" />
									<label for="un">user name</label>
									<input
										aria-describedby="emailHelp"
										class="w3-input w3-border"
										id="un"
										name="userName"
										placeholder="select a user name"
										required="required" />
									<small class="form-text text-muted" id="emailHelp">Check that this is not already used!</small>
									<label for="mail">Email address</label>
									<input
										aria-describedby="emailHelp"
										class="w3-input w3-border"
										id="mail"
										name="email"
										placeholder="Enter email"
										required="required"
										type="email" />
									<small
										class="form-text text-muted"
										id="emailHelp"
									>This is needed for the website notifications.</small>
									<label for="pw">Password</label>
									<input
										class="w3-input w3-border"
										id="pw"
										name="password"
										placeholder="Password"
										required="required"
										type="password" />
									<label for="role">Role</label>
									<input
										class="w3-input w3-border"
										id="role"
										name="role"
										placeholder="role description"
										required="required"
										type="text" />
									<label for="primarygroup">Select group</label>
									<select class="w3-select w3-border" id="primarygroup" name="group" required="required">
										<option selected="selected">Please chose</option>
										{
											for $g in sm:list-groups()
											order by count(sm:get-group-members($g)) descending
											return <option value="{ $g }">{ $g }</option>
										}
									</select>
									<label for="group2">Secondary Group</label>
									<select class="w3-select w3-border" id="group2" name="group2">
										<option disabled="disabled" selected="selected">none</option>
										{
											for $g in sm:list-groups()
											return if ($g eq "dba") then (
											) else
												<option value="{ $g }">{ $g }</option>
										}
									</select>
									<button class="w3-button w3-red" type="submit">Submit</button>
								</form>
							</div>,
							<div class="w3-panel w3-card-4 w3-padding">
								<h3>Add user to group</h3>
								<form action="/user/addUsertoGroup.xql" method="POST">
									<label for="group2">user</label>
									<select class="w3-select w3-border" id="user" name="user">
										<option disabled="disabled" selected="selected">none</option>
										{
											for $g in sm:list-users()
											return <option value="{ $g }">{ $g }</option>
										}
									</select>
									<label for="group2">Secondary Group</label>
									<select class="w3-select w3-border" id="group3" name="group3">
										<option disabled="disabled" selected="selected">none</option>
										{
											for $g in sm:list-groups()
											return <option value="{ $g }">{ $g }</option>
										}
									</select>
									<button class="w3-button w3-red" type="submit">Submit</button>
								</form>
							</div>,
							<div class="w3-container">
								<div
									class="w3-half w3-responsive"
								>There are currently the following users in this eXist-db instance

                <table
										class="w3-table w3-hoverable"
									>
										<thead><tr><th>user</th><th>metadata</th></tr></thead>
										<tbody>
											{
												for $u in sm:list-users()
												return (
													<tr>
														<td><span class="w3-large w3-tag w3-red">{ $u }</span></td>
														<td>
															{
																if (sm:is-dba($u)) then
																	"dba"
																else
																	"user"
															}
														</td>
													</tr>,
													<tr>
														<td />
														<td>
															{
																for $x in sm:get-account-metadata-keys($u)
																return <p><b>{ $x }</b>:{ sm:get-account-metadata($u, $x) }</p>
															}
														</td>
													</tr>
												)
											}
										</tbody>
									</table>
								</div>
								<div
									class="w3-half w3-responsive"
								>There are currently the following groups in this eXist-db instance

                <table
										class="w3-table w3-hoverable"
									>
										<thead><tr><th>group</th><th>members</th></tr></thead>
										<tbody>
											{
												for $u in sm:list-groups()
												order by count(sm:get-group-members($u)) descending
												return <tr>
													<td><span class="w3-large w3-tag w3-gray">{ $u }</span></td>
													<td>
														{
															<ul>
																{
																	for $m in sm:get-group-members($u)
																	return <li>{ $m }</li>
																}
															</ul>
														}
													</td>
												</tr>
											}
										</tbody>
									</table>
								</div>
							</div>,
							<div class="w3-container w3-card-4 w3-padding w3-red w3-margin">
								<h3>Delete account</h3>
								<form action="/user/deleteaccount.xql" method="POST">
									<label for="un">user name</label>
									<input
										aria-describedby="emailHelp"
										class="w3-input w3-border"
										id="un"
										name="olduser"
										placeholder="select a user name" />
									<small class="form-text text-muted" id="Help">Be very sure!</small>
									<br />
									<button class="w3-button w3-gray" type="submit">Submit</button>
								</form>
							</div>,
							<div class="w3-container w3-card-4 w3-padding w3-red w3-margin">
								<h3>Delete group</h3>
								<form action="/user/deletegroup.xql" method="POST">
									<label for="grouptobedeleted">Select group to be deleted</label>
									<select class="w3-select w3-border" id="grouptobedeleted" name="oldgroup">
										{
											for $g in sm:list-groups()
											return <option value="{ $g }">{ $g }</option>
										}
									</select>
									<small class="form-text text-muted" id="delgroupHelp">Be very sure!</small>
									<br />
									<button class="w3-button w3-gray" type="submit">Submit</button>
								</form>
							</div>
						) else (
						)
					}
				</div>
			</body>
		</html>
	) else (
		roaster:response(400, "text/html", error:error($Imap))
	)
};
