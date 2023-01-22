extends "command.gd"


func run(arguments: Array[String], user_details: UserDetails) -> String:
	return "List: %s." % ", ".join(arguments)
