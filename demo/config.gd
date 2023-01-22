# Configuration file helper.
extends Node

@export_global_file("*.cfg")
var config_file_path: String = "user://config.cfg"

var _config_file := ConfigFile.new()


func _ready() -> void:
	# Before testing this project, make a copy of the sample config file
	# (`demo/config.cfg`) inside the project data folder (open it using the menu
	# "Project > Open Project Data Folder"), and modify it following the
	# instructions included.
	assert(FileAccess.file_exists(config_file_path), "Demo app configuration file missing!")
	assert(_config_file.load(config_file_path) == OK, "There was an error loading the app configuration.")


func get_value(section: String, key: String) -> Variant:
	return _config_file.get_value(section, key, null)
