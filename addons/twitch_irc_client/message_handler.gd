extends Node

signal message_parsed(command: String, params: String, trailing: String, username: String, tags: Dictionary)

const CRLF := "\r\n"
const IRC_MESSAGE_REGEX := "^(?:@(?<tags>\\S+) )?(?::(?:(?<username>\\w+)(?:!\\w+@\\w+)?\\.)?tmi\\.twitch\\.tv )?(?<command>\\d{3}|[A-Z]+?)(?: (?<params>.*?))?(?: \\:(?<trailing>.*))?$"
const IRC_TAGS_REGEX := "(?<=^|;)(?<key>\\S+?)=(?<value>\\S*?)(?=;|$)"

var _irc_message_regex := RegEx.create_from_string(IRC_MESSAGE_REGEX)
var _irc_tags_regex := RegEx.create_from_string(IRC_TAGS_REGEX)


func _get_message_parts(value: String) -> Dictionary:
	var result := {}
	var matches := _irc_message_regex.search(value)
	for key in _irc_message_regex.get_names():
		result[key] = matches.get_string(key)
	return result


func _get_tags(raw_tags: String) -> Dictionary:
	var result := {}
	for m in _irc_tags_regex.search_all(raw_tags):
		result[m.get_string("key")] = m.get_string("value")
	return result


func _on_web_socket_message_received(message: Variant) -> void:
	if message is String:
		_parse_messages(message)


func _parse_messages(messages: String) -> void:
	for message in messages.split(CRLF, false):
		var parts := _get_message_parts(message)
		message_parsed.emit(parts.command, parts.params, parts.trailing, parts.username, _get_tags(parts.tags))
