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


func _on_twitch_irc_client_authentication_failed() -> void:
	printerr("Authentication failed.")


func _on_twitch_irc_client_authentication_succeeded() -> void:
	# Join the desired Twitch channel.
	var channel = $Config.get_value("connection", "channel")
	if channel is String:
		$TwitchIRCClient.join(channel)


func _on_twitch_irc_client_connection_opened() -> void:
	# Login using your bot account and an OAuth token.
	var nick = $Config.get_value("authentication", "nick")
	var oauth_token = $Config.get_value("authentication", "oauth_token")
	if nick is String and oauth_token is String:
		$TwitchIRCClient.authenticate(nick, oauth_token)


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


func _ready() -> void:
	$TwitchIRCClient.open_connection()
