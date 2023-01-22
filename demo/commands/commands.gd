## The root command handler.
##
## Available chat bot commands are nested (as child nodes) of this handler.[br]
##
## [b]Note:[/b] This is only an example of how a chat bot could be implemented
## using TwitchIRCClient. Use it as a starting point: try adding and modifying
## commands yourself.
extends Node


func _find_command(command_name: String) -> Node:
	for node in get_children():
		if command_name == node.name or command_name in node.aliases:
			return node
	return null


## Runs the command called by the user, if available.
func run(command_name: String, arguments: Array[String], user_details: UserDetails) -> Dictionary:
	var result := {}
	var command := _find_command(command_name)
	if is_instance_valid(command) and command.is_user_allowed(user_details):
		result.message = command.run(arguments, user_details)
		if command.is_reply:
			result.tags = user_details.get_reply_parent_message_id()
	return result
