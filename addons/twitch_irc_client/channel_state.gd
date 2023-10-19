extends Node

var _channel_state: ChannelState


func clear() -> void:
	_channel_state = null


func get_rate_limit(channel: String) -> TwitchIRCClient.RateLimit:
	if has_joined(channel):
		if _channel_state.is_broadcaster_or_moderator():
			return TwitchIRCClient.RateLimit.FOR_MODERATORS_OR_BROADCASTERS
		return TwitchIRCClient.RateLimit.FOR_REGULAR_ACCOUNTS
	return TwitchIRCClient.RateLimit.UNDEFINED


func has_joined(channel: String) -> bool:
	return is_instance_valid(_channel_state) and _channel_state.name == channel


func register(channel: String) -> void:
	_channel_state = ChannelState.new()
	_channel_state.name = channel


func set_user_state(channel: String, user_state_tags: Dictionary) -> void:
	if has_joined(channel):
		_channel_state.user_state_tags = user_state_tags


class ChannelState extends RefCounted:
	var name: String
	var user_state_tags: Dictionary

	func is_broadcaster_or_moderator() -> bool:
		var is_broadcaster: bool = "broadcaster/" in user_state_tags.get("badges", "")
		var is_moderator: bool = user_state_tags.get("mod", "") == "1"
		return is_broadcaster or is_moderator
