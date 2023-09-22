extends PanelContainer
# =/!\==========================================================================
# Before testing this project, make a copy of the sample config file
# (`demo/config.cfg`) inside the project data folder (open it using the menu
# "Project > Open Project Data Folder"), and modify it following the
# instructions included.
# ==========================================================================/!\=

func _enter_tree() -> void:
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	get_window().set_min_size(Vector2i(width, height))


func _ready() -> void:
	$AuthenticationAgent.client_id = $Config.get_value("authentication", "client_id")
	$AuthenticationAgent.client_secret = $Config.get_value("authentication", "client_secret")
	$AuthenticationAgent.restore_access_token()


func _callback_request_handler(query_parameters: Dictionary) -> HTTPServerResponse:
	var f = func(s: String) -> PackedByteArray: return s.to_utf8_buffer()
	if "error" in query_parameters:
		match query_parameters.get("error"):
			"access_denied":
				return HTTPServerResponse.unauthorized({}, f.call("You need to authorize the application to use the chat bot."))
			"redirect_mismatch":
				return HTTPServerResponse.bad_request({}, f.call("The application redirect URL is not properly set. Please check developer console."))
			_:
				var error_description: String = query_parameters.get("error_description")
				return HTTPServerResponse.unauthorized({}, (f.call("Authorization process failed: %s" % [error_description])))
	if "code" in query_parameters:
		var code: String = query_parameters.get("code")
		$AuthenticationAgent.request_access_token(code)
		return HTTPServerResponse.ok({}, f.call("Authorization code received. You can close this page now."))
	# If, for some reason, we don't receive the expected request.
	return HTTPServerResponse.bad_request({}, f.call("Authorization process failed for an unknown reason."))


func _on_authentication_agent_access_token_failed(reason: String, status: int) -> void:
	push_error("OAuth transaction failed: ", reason, " Status: ", status)
	if $HTTPServer.is_listening():
		$HTTPServer.stop()


func _on_authentication_agent_access_token_missing() -> void:
	$HTTPServer.add_request_handler("callback", _callback_request_handler)
	$HTTPServer.start(3000)
	$AuthenticationAgent.oauth_redirect_url = $HTTPServer.get_route_url("callback")
	$AuthenticationAgent.request_user_authorization()


func _on_authentication_agent_access_token_ready() -> void:
	if $HTTPServer.is_listening():
		$HTTPServer.stop()
	$TwitchIRCClient.open_connection()


func _on_twitch_irc_client_authentication_failed() -> void:
	printerr("Authentication failed.")


func _on_twitch_irc_client_authentication_succeeded() -> void:
	# Join the desired Twitch channel.
	var channel = $Config.get_value("connection", "channel")
	if channel is String:
		$TwitchIRCClient.join(channel)


func _on_twitch_irc_client_connection_opened() -> void:
	# Login using your bot account and the generated OAuth access token.
	var nick = $Config.get_value("authentication", "nick")
	$TwitchIRCClient.authenticate(nick, $AuthenticationAgent.get_access_token())


func _on_twitch_irc_client_message_received(username: String, message: String, tags: Dictionary) -> void:
	var arguments: Array[String] = []; arguments.assign(message.split(" ", false))
	var command_name: String = arguments.pop_front()
	var user_details := UserDetails.new(username, tags)
	var response: Dictionary = $Commands.run(command_name, arguments, user_details)
	if response.is_empty() or response.message.is_empty():
		return
	$TwitchIRCClient.send(response.message, response.get("tags", {}))
	%Events.add_event("Command %s requested by %s." % [command_name, username])


func _on_twitch_irc_client_user_joined(username: String) -> void:
	%Events.add_event("User joined: %s." % username)
	%Users.add_user(username)


func _on_twitch_irc_client_user_parted(username: String) -> void:
	%Events.add_event("User left: %s." % username)
	%Users.remove_user(username)


func _on_twitch_irc_client_username_list_received(usernames: Array[String]) -> void:
	for username in usernames:
		%Users.add_user(username)
