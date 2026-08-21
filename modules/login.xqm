xquery version "3.1" encoding "UTF-8";

(:~
 : module used by the app for login and logout
 :
 : @author Pietro Liuzzo
 :)
module namespace locallogin = "https://www.betamasaheft.eu/login";

(:~
 : login function to be called from navigation template. if the user is guest, then show login, if not it is a logged user, then show logout
 :)

declare function locallogin:loginNew() {
	if (sm:id()//sm:username/text() = "guest") then
		<div class="w3-dropdown-hover w3-hide-small" id="logging">
			<button class="w3-button" title="Login">Login <i class="fa fa-caret-down" /></button>
			<div class="w3-dropdown-content w3-bar-block w3-card-4" style="width:400px;">
				<form accept-charset="UTF-8" class="w3-bar-item" id="login-nav" method="post" role="form">
					<label for="user">User:</label>
					<input class="w3-input" name="user" required="required" type="text" />
					<label for="password">Password:</label>
					<input class="w3-input" name="password" type="password" />
					<button class="w3-button w3-small w3-red" type="submit">Login</button>
				</form>
			</div>
		</div>
	else
		<form
			accept-charset="UTF-8"
			action=""
			class="w3-bar-item w3-hide-small"
			id="logout-nav"
			method="post"
			role="form"
			style="margin:0;padding:0"
		>
			<button class=" w3-button w3-red" type="submit"><i class="fa fa-sign-out-alt" /></button>
			<input name="logout" type="hidden" value="true" />
		</form>
};
