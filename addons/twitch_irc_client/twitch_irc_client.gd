## A Twitch IRC client for Godot Engine.
##
## An abstraction layer for the Twitch IRC API, over a WebSocket connection,
## that makes it possible for games and applications created with
## Godot Engine to interact with Twitch channels.[br]
##
## Before using this add-on in your projects, you must register a Twitch app and
## obtain an OAuth token to get access to the Twitch IRC API.
##
## @tutorial(Register your App | Twitch Developers): https://dev.twitch.tv/docs/authentication/register-app/
## @tutorial(Chat & Chatbots | Twitch Developers): https://dev.twitch.tv/docs/irc/
class_name TwitchIRCClient
extends Node

## The authentication with the given credentials has either succeeded or failed.
signal authentication_completed(was_successful: bool)

## The client is being notified about a channel event (e.g.: follows, raids,
## subscriptions etc.)
signal channel_event_received(message: String, tags: Dictionary)

## The connection has been closed. Not emitted when the server requests to
## reconnect.
signal connection_closed()

## The client has successfully connected to the server.
signal connection_opened()

## The client has joined the specified [member channel].
signal joined()

## Emitted for raw messages and events.
signal logger(message: String, timestamp: String)

## The client has received a message from the channel.
signal message_received(message: String, username: String, tags: Dictionary)

## The server replied with a notice.
signal notice_received(message: String, tags: Dictionary)

## The client has parted from [member channel].
signal parted()

## The server has requested the client to reconnect: it might not be possible to
## receive or send messages until connection is restored.
signal reconnect_requested()

## The possible rate limits, defined as messages sent per 30 seconds.
enum RateLimit {
	UNDEFINED = 0,                        ## No rate limit defined
	FOR_REGULAR_ACCOUNTS = 20,            ## The client's account is not a broadcaster or moderator
	FOR_MODERATORS_OR_BROADCASTERS = 100, ## The client's account is the channel broadcaster or moderator
}

## Twitch WebSocket API Endpoint.
const TWITCH_WS_API_URL := "wss://irc-ws.chat.twitch.tv:443"

## The Twitch channel to connect to. It must be preceeded by a pound sign (#),
## e.g. [code]#gdq[/code].
@export_placeholder("#mychannel")
var channel: String = ""


func _on_message_handler_message_parsed(command: String, params: String, trailing: String, username: String, tags: Dictionary) -> void:
	match command:
		"001":
			authentication_completed.emit(true)
		"JOIN":
			$ChannelState.register(params)
			joined.emit()
		"NOTICE":
			if $MessageHandler.is_auth_failed_notice(trailing):
				authentication_completed.emit(false)
				logger.emit("*** IRC API authentication failed. ***", Time.get_datetime_string_from_system())
			else:
				notice_received.emit(trailing, tags)
		"PART":
			$ChannelState.clear()
			parted.emit()
		"PING":
			$MessageQueue.add($MessageFormatter.get_pong_message(params))
		"PRIVMSG":
			message_received.emit(trailing, username, tags)
		"RECONNECT":
			reconnect_requested.emit()
		"USERNOTICE":
			channel_event_received.emit(trailing, tags)
		"USERSTATE":
			$ChannelState.set_user_state(params, tags)


func _on_message_queue_dispatch_requested(message: String) -> void:
	$WebSocket.send(message)
	# Filter OAuth token when logging.
	if message.begins_with("PASS"):
		logger.emit("PASS oauth:******************************", Time.get_datetime_string_from_system())
	else:
		logger.emit(message.strip_edges(), Time.get_datetime_string_from_system())


func _on_ping_timeout() -> void:
	$MessageQueue.add($MessageFormatter.get_ping_twitch_message())


func _on_web_socket_connected_to_server() -> void:
	$MessageQueue.start()
	$Ping.start()
	connection_opened.emit()
	logger.emit("*** WebSocket connection established. ***", Time.get_datetime_string_from_system())


func _on_web_socket_connection_closed() -> void:
	$MessageQueue.stop()
	$Ping.stop()
	connection_closed.emit()
	logger.emit("*** WebSocket connection closed. ***", Time.get_datetime_string_from_system())


func _on_web_socket_message_received(message: String) -> void:
	logger.emit(message, Time.get_datetime_string_from_system())


## Login using a Twitch account and its OAuth access token.
## Use [signal authentication_completed] to check if an authentication attempt
## failed or concluded successfully.
func authenticate(nick: String, oauth_token: String) -> void:
	$MessageQueue.add($MessageFormatter.get_cap_req_message())
	$MessageQueue.add($MessageFormatter.get_pass_message(oauth_token))
	$MessageQueue.add($MessageFormatter.get_nick_message(nick.to_lower()))


## Closes the connection to the Twitch IRC server.
func close_connection() -> void:
	$WebSocket.close()


## How many messages can be sent by the client within an interval of 30 seconds.
func get_rate_limit() -> RateLimit:
	return $ChannelState.get_rate_limit(channel)


## Returns whether the client has joined [member channel] or not.
func has_joined(p_channel: String = channel) -> bool:
	return $ChannelState.has_joined(p_channel)


## Returns true if the WebSocket connection is open.
func is_connection_open() -> bool:
	return $WebSocket.get_ready_state() == WebSocketPeer.STATE_OPEN


## Tells if the client is currently allowed to send more chat messages or not.
func is_within_rate_limit() -> bool:
	return $RateLimit.is_within_limit($ChannelState.get_rate_limit(channel))


## Joins a given Twitch [param p_channel]. The channel name must be preceeded by
## a pound sign, e.g. "[code]#gdq[/code]". If omitted, [param p_channel]
## defaults to [member channel].
func join(p_channel: String = channel) -> void:
	channel = p_channel
	assert(len(channel) > 1 and channel.begins_with("#") and not "," in channel, "Invalid channel.")
	if not $ChannelState.has_joined(channel):
		$MessageQueue.add($MessageFormatter.get_join_message(channel))


## Parts from the previoulsy joined Twitch [member channel].
func leave() -> void:
	assert(len(channel) > 1 and channel.begins_with("#") and not "," in channel, "Invalid channel.")
	if $ChannelState.has_joined(channel):
		$MessageQueue.add($MessageFormatter.get_part_message(channel))


## Establishes a connection to the Twitch IRC API.
func open_connection() -> Error:
	if $WebSocket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		return ERR_ALREADY_IN_USE
	$MessageQueue.clear()
	$WebSocket.clear()
	var error: Error = $WebSocket.connect_to_url(TWITCH_WS_API_URL)
	if error != OK:
		push_error("Failed to open WebSocket connection.")
	return error


## Sends a [param message] to the [member channel] with its respective [param
## tags], if any, respecting the rate limit. If that limit is exceeded, the
## message is silently dropped to prevent a suspension.
## Returns [code]true[/code] if the message was queued for delivery.
func send(message: String, tags: Dictionary = {}) -> bool:
	assert(len(channel) > 1 and channel.begins_with("#") and not "," in channel, "Invalid channel.")
	var rate_limit: int = $ChannelState.get_rate_limit(channel)
	var result: bool = $ChannelState.has_joined(channel) and $RateLimit.is_within_limit(rate_limit)
	if result:
		$RateLimit.count()
		$MessageQueue.add($MessageFormatter.get_privmsg_message(channel, message, tags))
	return result
