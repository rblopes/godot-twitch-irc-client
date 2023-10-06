extends Node

signal message_parsed(command: String, params: String, trailing: String, username: String, tags: Dictionary)

# The notification received after an unsuccessful authentication.
const AUTH_FAILED_NOTICE := "Login authentication failed"

const IRC_MESSAGE_REGEX := "(?mn)^(?<tags>@\\H+ )?(:((?<username>\\w+)(!\\w+@\\w+)?\\.)?tmi\\.twitch\\.tv )?(?<command>\\d{3}|[A-Z]+)( (?<params>.+?))?( :(?<trailing>.*))?$"
const IRC_TAGS_REGEX := "(?<=^@|;)(?<key>\\H+?)(?:=(?<value>\\H*?))?(?=;|$)"

var _irc_message_regex := RegEx.create_from_string(IRC_MESSAGE_REGEX)
var _irc_tags_regex := RegEx.create_from_string(IRC_TAGS_REGEX)


func is_auth_failed_notice(message: String) -> bool:
	return message == AUTH_FAILED_NOTICE


func _get_tags(raw_tags: String) -> Dictionary:
	var result := {}
	for m in _irc_tags_regex.search_all(raw_tags):
		result[m.get_string("key")] = _unescape_tag_value(m.get_string("value"))
	return result


func _on_web_socket_message_received(message: Variant) -> void:
	if message is String:
		_parse_lines(message)


func _parse_lines(lines: String) -> void:
	for m in _irc_message_regex.search_all(lines):
		var tags := _get_tags(m.get_string("tags"))
		var username := m.get_string("username")
		var command := m.get_string("command")
		var params := m.get_string("params")
		var trailing := m.get_string("trailing").strip_escapes()
		message_parsed.emit(command, params, trailing, username, tags)


func _unescape_tag_value(raw_value: String) -> String:
	return raw_value.replace("\\:", ";").replace("\\s", " ").replace("\\r", "\r").replace("\\n", "\n").replace("\\\\", "\\")
