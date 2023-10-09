## The root command handler.
##
## Available chat bot commands are nested as child nodes of this handler.[br]
##
## [b]Note:[/b] This is only an example of how a chat bot could be implemented.
## Use it as a starting point: try adding and modifying commands yourself.
extends Node

## Emitted after a command was found, run and completed.
signal command_completed(command: String, reply: String, user: UserDetails, tags: Dictionary)

## A regular expression matching lines with the form:
## [code]<prefix>command arg1 arg2 ...[/code], where <prefix> is at least one
## character long and don't contain letters or digits.
const COMMAND_REGEX_PATTERN: String = "^(?<prefix>[^\\w\\h]+)(?<command>\\w+?)(?:\\h+(?<args>.*))?$"

## A standard command prefix. A message is treated as a command only when it
## starts with those symbols (shouldn't contain letters or digits, and must not
## begin with a dot (.) or a forward slash (/).)
@export_placeholder("e.g.: ! or ??")
var command_prefix: String = "!":
	set(val):
		assert(not val.begins_with("/"), "Command prefix must not begin with a /")
		assert(not val.begins_with("."), "Command prefix must not begin with a .")
		command_prefix = val

var _command_regex := RegEx.create_from_string(COMMAND_REGEX_PATTERN)


## Runs the command called by the user, if available.
func run(user: UserDetails, message: String) -> void:
	var regex_match := _command_regex.search(message)
	if _is_command_expression_valid(regex_match):
		var command := _find_command(regex_match.get_string("command").to_lower())
		if is_instance_valid(command) and command.is_available_for(user):
			var args := regex_match.get_string("args").split(" ", false)
			var reply: String = command.run(args, user)
			var tags: Dictionary = user.get_reply_parent_message_id() if command.is_reply else {}
			command.start_cooldown()
			command_completed.emit(command.name, reply, user, tags)


func _find_command(command_name: String) -> Node:
	if has_node(command_name):
		return get_node(command_name)
	for node in get_children():
		if "aliases" in node and command_name in node.aliases:
			return node
	return null


func _is_command_expression_valid(regex_match: RegExMatch) -> bool:
	return is_instance_valid(regex_match) and regex_match.get_string("prefix") == command_prefix
