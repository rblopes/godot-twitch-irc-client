## An abstract bot command.
##
## The base class for chat commands. A command can be called by its name (by
## convention, its node name), or its [member aliases]. Commands may require
## users to be of a certain [member required_user_level] to be performed, and
## may become unavailable for a given amount of time, to avoid spamming.
extends Node

const EMPTY_MESSAGE: String = ""

## The aliases this command can also be invoked by.
@export
var aliases: PackedStringArray

## The interval a user has to wait before using this command again.
@export_range(0, 120, 5, "suffix:s")
var cooldown_interval: int = 0

## If enabled, reply the message that issued this command.
@export
var is_reply: bool

## A user has to be at least of this user level to use this command.
@export
var required_user_level: UserDetails.UserLevelFlags = UserDetails.UserLevelFlags.EVERYONE


## Whether this command can be called by the user or not.
func is_available_for(user: UserDetails) -> bool:
	return user.is_broadcaster() or $Cooldown.is_stopped() and user.get_user_level() >= required_user_level


## Performs the requested chat bot command.
func run(arguments: Array[String], user: UserDetails) -> String:
	# Overridden by subclasses to generate the message.
	return EMPTY_MESSAGE


## This command becomes unavailable for an interval defined by [member
## cooldown_interval].
func start_cooldown() -> void:
	$Cooldown.start(cooldown_interval)
