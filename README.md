# TwitchIRCClient [![Made for Godot 4.0+][badge]][godot]

A Twitch IRC client for Godot Engine.

An abstraction layer for the Twitch IRC API, over a WebSocket connection, that
makes it possible for games and applications created with Godot Engine to
interact with Twitch channels.

> NOTE: This a pure GDScript implementation. If you're developing Twitch
> chat integrations with Godot Engine and C#, consider using
> [TwitchLib](https://github.com/TwitchLib) instead.


## Example

Below is a minimal reproducible working sample. A more elaborate project can be
found in this repository, inside the `demo` folder.

> Before testing, you must [register a Twitch app][1] and obtain an [OAuth
> token][2] with at least the `chat:read` and `chat:edit` scopes to access the
> Twitch IRC API. Please read the Twitch Developers documentation to learn more.
>
> [1]: https://dev.twitch.tv/docs/authentication/register-app/
> [2]: https://dev.twitch.tv/docs/irc/authenticate-bot/

```gdscript
extends Node

func _ready() -> void:
  randomize()
  # Assuming TwitchIRCClient is a child node of this scene.
  $TwitchIRCClient.authentication_completed.connect(_on_authentication_completed)
  $TwitchIRCClient.connection_opened.connect(_on_connection_opened)
  $TwitchIRCClient.joined.connect(_on_joined)
  $TwitchIRCClient.message_received.connect(_on_message_received)
  $TwitchIRCClient.logger.connect(_logger)
  $TwitchIRCClient.open_connection()

func _on_connection_opened() -> void:
  # Replace <nick> and <OAuth Token> with the account name using the plugin and
  # its generated token.
  $TwitchIRCClient.authenticate("<nick>", "<OAuth Token>")

func _on_authentication_completed(was_successful: bool) -> void:
  # Replace <twitch channel> with the channel name whose chat box you want to
  # read. It must be prefixed by a `#` sign.
  if was_successful:
    $TwitchIRCClient.join("#<twitch channel>")

func _on_joined() -> void:
  $TwitchIRCClient.send("Bot is ready.")

# Optional: log and inspect received messages.
func _logger(raw_messages: String, timestamp: String) -> void:
  for message in raw_messages.strip_edges().split("\r\n", false):
    prints(timestamp, message)

func _on_message_received(message: String, username: String, tags: Dictionary) -> void:
  # An example how chat "commands" could be handled.
  match message.get_slice(" ", 0).to_lower():
    "gl", "glgl", "glhf": # Tip: prefixes can be anything, or nothing at all!!
      $TwitchIRCClient.send("Thanks!")
    "!hi":
      # Extract messages metadata
      $TwitchIRCClient.send("%s VoHiYo" % tags["display-name"])
    "!dice":
      # Reply to previous messages
      $TwitchIRCClient.send("You rolled a %d" % randi_range(1, 6), {"reply-parent-msg-id": tags["id"]})
```

See the API documentation, browsing the "Search Help" function of the editor,
for more details.


## Limitations

The purpose of this add-on is to manage a single WebSocket connection to the
Twitch's IRC API, providing only the functionality to handle its message flow,
and their respective metadata, sent and received through a channel's chat.

For this reason, some features found in other add-ons are deliberately missing:

- **Chat "commands"**: TwitchIRCClient has no opinion on how you should create
  and provide such interactions. Therefore, developers have complete freedom to
  design their own use cases however they want.

- **Connect and manage other APIs**: connecting to other APIs (e.g. PubSub,
  EventSub etc.) is not supported by this plugin.

- **Manage OAuth access tokens**: TwitchIRCClient should be paired with another
  add-on to obtain, validate and refresh access tokens.

Additionally, the ability to manage multiple channel connections at once will
not be implemented in the library for the time being.


## License

[MIT](LICENSE.md).

[godot]: https://godotengine.org/
[badge]: https://flat.badgen.net/badge/made%20for/Godot%204.0%2b/478cbf
