# TwitchIRCClient [![Made for Godot 4.0+][badge]][godot]

A Twitch IRC client for Godot Engine.

An abstraction layer for the Twitch IRC API, over a WebSocket connection, that
makes it possible for games and applications created with Godot Engine to
interact with Twitch channels.

> Before using this add-on in your projects, you must [register a Twitch
> app][twitch-app] and obtain an [OAuth token][tmi] to grant you access to the
> Twitch IRC API.
>
> [twitch-app]: https://dev.twitch.tv/docs/authentication/register-app
> [tmi]: https://twitchapps.com/tmi/


## Example

Below is a minimal reproducible working sample. A more elaborate project can be
found in this repository, inside the `demo` folder.

```gdscript
extends Node

func _ready() -> void:
  # Assuming TwitchIRCClient is a child node of this scene.
  $TwitchIRCClient.authentication_succeeded.connect(_on_authentication_succeeded)
  $TwitchIRCClient.connection_opened.connect(_on_connection_opened)
  $TwitchIRCClient.message_received.connect(_on_message_received)
  $TwitchIRCClient.open_connection()

func _on_connection_opened() -> void:
  # Replace <nick> and <OAuth Token> with actual values.
  $TwitchIRCClient.authenticate("<nick>", "<OAuth Token>")

func _on_authentication_succeeded() -> void:
  # Replace <twitch channel> with an actual value.
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

See the API documentation for more details browsing the "Search Help" function
of the editor.


## License

[MIT](LICENSE.md).

[godot]: https://godotengine.org/
[badge]: https://flat.badgen.net/badge/made%20for/Godot%204.0%2b/478cbf
