## This example demonstrates how command arguments could be read and used.
extends "../command.gd"

const ROLL_MESSAGE := "The dice has rolled the number %d."

const HELP_MESSAGE := [
	"Command %s [{ --help | -h | -? } | <number>]",
	"Aliases: %s",
	"Options:",
	"--help: Shows this help message",
	"<number>: An integer, ranging from %d (default) to %d"
]

const MIN_FACES := 6
const MAX_FACES := 1000

@export_range(6, 1000, 1, "suffix:faces")
var min_faces: int = MIN_FACES

@export_range(6, 1000, 1, "suffix:faces")
var max_faces: int = MAX_FACES

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func run(arguments: Array[String], user_details: UserDetails) -> String:
	match arguments.pop_front():
		"--help", "-h", "-?":
			return " • ".join(HELP_MESSAGE) % [name, "; ".join(aliases), min_faces, max_faces]
		var value:
			var faces := min_faces
			if value is String and value.is_valid_int():
				faces = clampi(int(value), min_faces, max_faces)
			return ROLL_MESSAGE % _rng.randi_range(1, faces)
