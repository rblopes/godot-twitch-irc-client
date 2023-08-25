# TwitchIRCClient [![Made for Godot 4.0+][badge]][godot]

A Twitch IRC client for Godot Engine.

An abstraction layer for the Twitch IRC API, over a WebSocket connection, that
makes it possible for games and applications created with Godot Engine to
interact with Twitch channels.


## Example

Below is a minimal reproducible working sample. A more elaborate project can be
found in this repository, inside the `demo` folder.

> Before testing, you must [register a Twitch app][1] and obtain an [OAuth
> token][2] with at least the `chat:read` and `chat:edit` scopes to grant you
> access to the Twitch IRC API and use it properly. Please refer to the Twitch
> Developers documentation to find out more.
>
> [1]: https://dev.twitch.tv/docs/authentication/register-app/
> [2]: https://dev.twitch.tv/docs/irc/authenticate-bot/

```gdscript
extends Node

func _ready() -> void:
  # Assuming TwitchIRCClient is a child node of this scene.
  $TwitchIRCClient.authentication_succeeded.connect(_on_authentication_succeeded)
  $TwitchIRCClient.connection_opened.connect(_on_connection_opened)
  $TwitchIRCClient.message_received.connect(_on_message_received)
  $TwitchIRCClient.open_connection()

func _on_connection_opened() -> void:
  # Replace <nick> and <OAuth Token> with the account name using the plugin and
  # its generated token.
  $TwitchIRCClient.authenticate("<nick>", "<OAuth Token>")

func _on_authentication_succeeded() -> void:
  # Replace <twitch channel> with the channel name whose chat box you want to
  # read. It must be prefixed by a `#` sign.
  $TwitchIRCClient.join("#<twitch channel>")

func _on_message_received(username, message, tags) -> void:
  var arguments = Array(message.split(" ", false))
  match arguments.pop_front():
    "!helloworld", "!test":
      $TwitchIRCClient.send("Hello, World!")
    "!greet":
      $TwitchIRCClient.send("Welcome, %s!" % tags.get("display-name", username))
    "!list":
      $TwitchIRCClient.send(str("List: ", ", ".join(arguments)))
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
