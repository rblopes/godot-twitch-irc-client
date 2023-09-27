extends Node

# IRC message masks.
const IRC_COMMAND_CAP_REQ_MASK := "CAP REQ :%s"
const IRC_COMMAND_JOIN_MASK := "JOIN %s"
const IRC_COMMAND_NICK_MASK := "NICK %s"
const IRC_COMMAND_PART_MASK := "PART %s"
const IRC_COMMAND_PASS_MASK := "PASS oauth:%s"
const IRC_COMMAND_PONG_MASK := "PONG %s"
const IRC_COMMAND_PRIVMSG_MASK := "PRIVMSG %s :%s"

# Twitch IRC capabilities requested by the client.
const TWITCH_IRC_CAPABILITIES := "twitch.tv/commands twitch.tv/membership twitch.tv/tags"

# A PING message that must be sent regularly.
# Required to prevent connectivity loss.
const TWITCH_PING_MESSAGE := "PING :tmi.twitch.tv"


func _escape_tag_value(raw_value: String) -> String:
	return raw_value.replace("\\", "\\\\").replace(";", "\\:").replace(" ", "\\s").replace("\r", "\\r").replace("\n", "\\n")


func _format_tags(tags: Dictionary) -> String:
	if tags.is_empty():
		return ""
	return str("@", ";".join(tags.keys().map(func(t): return str(t, "=", _escape_tag_value(tags[t])))), " ")


func get_cap_req_message() -> String:
	return IRC_COMMAND_CAP_REQ_MASK % TWITCH_IRC_CAPABILITIES


func get_join_message(arg: String) -> String:
	return IRC_COMMAND_JOIN_MASK % arg


func get_nick_message(arg: String) -> String:
	return IRC_COMMAND_NICK_MASK % arg


func get_part_message(arg: String) -> String:
	return IRC_COMMAND_PART_MASK % arg


func get_pass_message(arg: String) -> String:
	return IRC_COMMAND_PASS_MASK % arg


func get_ping_twitch_message() -> String:
	return TWITCH_PING_MESSAGE


func get_pong_message(arg: String) -> String:
	return IRC_COMMAND_PONG_MASK % arg


func get_privmsg_message(channel: String, message: String, tags: Dictionary) -> String:
	return str(_format_tags(tags), IRC_COMMAND_PRIVMSG_MASK % [channel, message])
