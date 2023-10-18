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
	$TwitchIRCClient.open_connection()


func _on_command_handler_command_completed(command: String, reply: String, user: UserDetails, tags: Dictionary) -> void:
	$TwitchIRCClient.send(reply, tags)
	%Events.add_event("Command %s requested by %s." % [command, user.get_display_name()])
	%Users.add_user(user.username)


func _on_twitch_irc_client_authentication_completed(was_successful: bool) -> void:
	if was_successful:
		# Join the desired Twitch channel.
		var channel: String = $Config.get_value("connection", "channel")
		$TwitchIRCClient.join(channel)
	else:
		$TwitchIRCClient.close_connection()


func _on_twitch_irc_client_connection_opened() -> void:
	# Login using your bot account and an OAuth token.
	var nick: String = $Config.get_value("authentication", "nick")
	var oauth_token: String = $Config.get_value("authentication", "oauth_token")
	$TwitchIRCClient.authenticate(nick, oauth_token)


func _on_twitch_irc_client_joined() -> void:
	%Events.add_event("Bot is ready.")


func _on_twitch_irc_client_logger(message: String, timestamp: String) -> void:
	for s in message.strip_edges().split("\r\n"):
		prints(timestamp, s)


func _on_twitch_irc_client_message_received(message: String, username: String, tags: Dictionary) -> void:
	$CommandHandler.run(UserDetails.new(username, tags), message)
