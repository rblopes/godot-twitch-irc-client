## An abstract bot command.
##
## The base class for chat commands. A command can be called by its name (by
## convention, its node name), or its [member aliases]. Commands may
## require users to be of a certain [member user_level] to be performed.
extends Node

## The aliases this command can also be invoked by.
@export
var aliases: Array[String] = []

## If enabled, reply the message that issued this command.
@export
var is_reply: bool

## A user need to be, at least, of this user level to invoke this command.
@export
var user_level: UserDetails.UserLevelFlags = UserDetails.UserLevelFlags.EVERYONE


## Tests whether a user is allowed to use this command.
func is_user_allowed(user_details: UserDetails) -> bool:
	return user_details.get_user_level() >= user_level


## Performs the requested chat bot command.
func run(arguments: Array[String], user_details: UserDetails) -> String:
	# Overridden by `command.gd` subclasses.
	return ""
