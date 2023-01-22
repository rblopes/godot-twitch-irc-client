## Helper class to fetch use details from message tags.
class_name UserDetails
extends RefCounted

## Required permissions to execute a command.
enum UserLevelFlags {
	EVERYONE = 0x0,    ## Everyone is allowed to use this command.
	SUBSCRIBER = 0x1,  ## User must be at least a subscriber of the channel.
	VIP = 0x2,         ## User must be at least a VIP.
	MODERATOR = 0x4,   ## User must be at least a channel moderator.
	BROADCASTER = 0x8, ## Only the channel owner is allowed to use this command.
}

## The user's account name who sent the message.
var username: String

## A collection of tags related to the last message received.
var tags: Dictionary


func _init(p_username: String, p_tags: Dictionary) -> void:
	username = p_username
	tags = p_tags


## Returns the display name of the use user who sent the message.
## If none, defaults to [member username].
func get_display_name() -> String:
	return tags.get("display-name", username)


## Gets the last received message ID. Useful to encode messages as direct
## replies.
func get_reply_parent_message_id() -> Dictionary:
	if "id" in tags:
		return {"reply-parent-msg-id" = tags.id}
	return {}


## Calculates the current user's level, based on their subscription badges.
func get_user_level() -> int:
	var result := 0
	result |= UserLevelFlags.SUBSCRIBER * int(tags.get("subscriber") == "1")
	result |= UserLevelFlags.MODERATOR * int(tags.get("mod") == "1")
	for badge in tags.get("badges", "").split(",", false):
		result |= UserLevelFlags.VIP * int(badge.begins_with("vip"))
		result |= UserLevelFlags.BROADCASTER * int(badge.begins_with("broadcaster"))
	return result
