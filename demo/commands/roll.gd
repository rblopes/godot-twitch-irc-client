# This example is a more refined bot command implemented using this pattern.
# It uses a timer to "limit" how often it gives correct answers.
# It also demonstrates how command arguments can be read and used.
extends "command.gd"

const ROLL_MESSAGE := "The dice has rolled the number %d."
const COOLDOWN_MESSAGE := "This command is on cooldown for about %d seconds..."

const HELP_MESSAGE := [
	"Command !roll_die [{ --help | -h | -? } | <number>] • ",
	"Aliases: %s • ",
	"Options: • ",
	"--help: Shows this help message • ",
	"<number>: An integer, ranging from %d (default) to %d"
]

const MIN_FACES := 6
const MAX_FACES := 1000

@export
var min_faces: int = MIN_FACES

@export
var max_faces: int = MAX_FACES

@export
var cooldown_interval: int = 15

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.randomize()


func _roll(faces: int) -> int:
	return rng.randi_range(1, faces)


func run(arguments: Array[String], user_details: UserDetails) -> String:
	match arguments.pop_front():
		"--help", "-h", "-?":
			return " ".join(HELP_MESSAGE) % ["; ".join(aliases), min_faces, max_faces]
		var value:
			if $Cooldown.is_stopped():
				$Cooldown.start(cooldown_interval)
				var faces := min_faces
				if value is String and value.is_valid_int():
					faces = clampi(int(value), min_faces, max_faces)
				return ROLL_MESSAGE % _roll(faces)
			return COOLDOWN_MESSAGE % $Cooldown.time_left
