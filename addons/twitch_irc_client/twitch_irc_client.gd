## A Twitch IRC client for Godot Engine.
##
## An abstraction layer for the Twitch IRC API, over a WebSocket connection,
## that makes it possible for games and applications created with
## Godot Engine to interact with Twitch channels.[br]
##
## Before using this add-on in your projects, you must register a Twitch app and
## obtain an [url=https://twitchapps.com/tmi/]OAuth token[/url] to grant you
## access to the Twitch IRC API.
##
## @tutorial(Register your App | Twitch Developers): https://dev.twitch.tv/docs/authentication/register-app/
## @tutorial(Chat & Chatbots | Twitch Developers): https://dev.twitch.tv/docs/irc/
class_name TwitchIRCClient
extends Node

## Authentication with the given credentials has failed.
signal authentication_failed()

## Authentication has succeeded.
signal authentication_succeeded()

## The client is being notified about a channel event (e.g.: follows, raids,
## subscriptions etc.)
signal channel_event_received(message: String, tags: Dictionary)

## The connection has been closed. Not emitted when the server requests to
## reconnect.
signal connection_closed()

## The client has successfully connected to the server.
signal connection_opened()

## The connection to the server has failed.
signal connection_refused()

## The client has received a message from the channel.
signal message_received(username: String, message: String, tags: Dictionary)

## The server replied with a notice.
signal notice_received(message: String, tags: Dictionary)

## The server replied a ping from the client.
signal ping()

## The client replied a ping from the server.
signal pong()

## The client exceeded the [member rate_limit] set and has been prevented from
## sending more chat messages to the channel.
signal rate_limit_exceeded(last_message: String, tags: Dictionary)

## The server has requested the client to reconnect: it might not be possible to
## receive or send messages until connection is restored.
signal reconnect_requested()

## A user has joined the channel.
signal user_joined(username: String)

## A user has left the channel.
signal user_parted(username: String)

## The server sent the list of users joined to the channel. Emitted after
## joining a channel.
signal username_list_received(usernames: Array[String])

## The possible [member rate_limit] values, defined as messages per 30 seconds.
enum RateLimits {
	FOR_REGULAR_ACCOUNTS = 20,            ## The client's account is not a channel's broadcaster or moderator
	FOR_MODERATORS_OR_BROADCASTERS = 100, ## The client's account is the channel's broadcaster or moderator
}

## The notification Twitch sends after an unsuccessful login.
const TWITCH_NOTICE_AUTH_FAILED := "Login authentication failed"

## Twitch WebSocket API Endpoint.
const TWITCH_WS_API_URL := "wss://irc-ws.chat.twitch.tv:443"

## The Twitch channel to connect to. It must be preceeded by a pound sign (#),
## e.g. [code]#gdq[/code].
@export
var channel: String = ""

## Enable the output of incoming and outgoing raw messages to the debug console.
@export
var enable_log: bool = true

## If the client is currently allowed to send more chat messages or not.
var is_within_rate_limit: bool:
	get:
		return _messages_sent_count < rate_limit

## How many messages can be sent by the client within a period of 30 seconds.
@export
var rate_limit: RateLimits = RateLimits.FOR_REGULAR_ACCOUNTS:
	set(value):
		rate_limit = value if value in RateLimits.values() else RateLimits.FOR_REGULAR_ACCOUNTS

var _messages_sent_count: int = 0


func _on_message_handler_message_parsed(command: String, params: String, trailing: String, username: String, tags: Dictionary) -> void:
	match command:
		"001":
			authentication_succeeded.emit()
		"353":
			username_list_received.emit(trailing.split(" ", false))
		"JOIN":
			user_joined.emit(username)
		"NOTICE":
			if trailing == TWITCH_NOTICE_AUTH_FAILED:
				authentication_failed.emit()
			else:
				notice_received.emit(trailing, tags)
		"PART":
			user_parted.emit(username)
		"PING":
			$MessageQueue.add($MessageFormatter.get_pong_message(params))
			pong.emit()
		"PONG":
			ping.emit()
		"PRIVMSG":
			message_received.emit(username, trailing, tags)
		"RECONNECT":
			reconnect_requested.emit()
		"USERNOTICE":
			channel_event_received.emit(trailing, tags)


func _on_message_queue_dispatch_requested(message: String) -> void:
	$WebSocket.send(message)


func _on_ping_timeout() -> void:
	$MessageQueue.add($MessageFormatter.get_ping_twitch_message())


func _on_rate_limit_timeout() -> void:
	_messages_sent_count = 0


func _on_web_socket_connected_to_server() -> void:
	print_debug("Connected to Twitch.")
	$MessageQueue.start()
	$Ping.start()
	connection_opened.emit()


func _on_web_socket_connection_closed() -> void:
	print_debug("Connection closed.")
	$MessageQueue.stop()
	$Ping.stop()
	connection_closed.emit()


## Login using a Twitch account and its OAuth access token.
func authenticate(nick: String, oauth_token: String) -> void:
	$MessageQueue.add($MessageFormatter.get_cap_req_message())
	$MessageQueue.add($MessageFormatter.get_pass_message(oauth_token))
	$MessageQueue.add($MessageFormatter.get_nick_message(nick.to_lower()))


## Closes the connection to the Twitch IRC server.
func close_connection() -> void:
	$WebSocket.close()


## Joins a given Twitch channel. The channel name must be preceeded by a pound
## sign, e.g. "[code]#gdq[/code]". If omitted, [code]p_channel[/code] defaults
## to [member channel].
func join(p_channel: String = channel) -> void:
	channel = p_channel
	assert(len(channel) > 1 and channel.begins_with("#") and not "," in channel, "Invalid channel.")
	$MessageQueue.add($MessageFormatter.get_join_message(channel))


## Parts from the previoulsy joined Twitch [member channel].
func leave() -> void:
	assert(len(channel) > 1 and channel.begins_with("#") and not "," in channel, "Invalid channel.")
	$MessageQueue.add($MessageFormatter.get_part_message(channel))


## Establishes a connection to the Twitch IRC API.
func open_connection() -> void:
	$MessageQueue.clear()
	$WebSocket.clear()
	if $WebSocket.connect_to_url(TWITCH_WS_API_URL) != OK:
		push_error("Could not connect to Twitch.")
		connection_refused.emit()


## Sends [code]message[/code] in the chat with its respective [code]tags[/code],
## if any, respecting the [member rate_limit]. Whenever that limit is exceeded,
## [signal rate_limit_exceeded] is emitted and new messages are ignored.
func send(message: String, tags: Dictionary = {}) -> void:
	assert(len(channel) > 1 and channel.begins_with("#") and not "," in channel, "Invalid channel.")
	if $RateLimit.is_stopped():
		$RateLimit.start()
	if is_within_rate_limit:
		$MessageQueue.add($MessageFormatter.get_privmsg_message(channel, message, tags))
		_messages_sent_count += 1
	else:
		rate_limit_exceeded.emit(message, tags)
