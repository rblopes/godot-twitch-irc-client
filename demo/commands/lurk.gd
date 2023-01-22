extends "command.gd"


func run(arguments: Array[String], user_details: UserDetails) -> String:
	return "Enjoy the lurk, %s! KonCha" % user_details.get_display_name()
