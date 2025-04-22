extends Node

@export var bpm: float = 160.0
signal beat(subdivision)

var _time_accumulator := 0.0
var beat_interval := 0.0
var beat_position := 0.0

const SUBDIVISIONS = {
	"full": 1,
	"half": 2,
	"quarter": 4,
	"quarter_triplet": 6,
	"eighth": 8,
	"eighth_quintuplets": 10,
	"eighth_triplet": 12,
}

const SUBDIVISION_NAMES = [
	"full",
	"half",
	"quarter",
	"quarter_triplet",
	"eighth",
	"eighth_quintuplets",
	"eighth_triplet",
]

var total_subdivs := 0
var current_subdiv_step := 0
var global_subdivision_steps := {}

func lcm(a: int, b: int) -> int:
	return abs(a * b) / gcd(a, b)

func gcd(a: int, b: int) -> int:
	while b != 0:
		var temp = b
		b = a % b
		a = temp
	return a

func lcm_all(values: Array) -> int:
	var result = values[0]
	for i in range(1, values.size()):
		result = lcm(result, values[i])
	return result

func _ready():
	for name in SUBDIVISIONS.keys():
		global_subdivision_steps[name] = 0
		
	beat_interval = 60.0 / (bpm / 4)
	total_subdivs = lcm_all(SUBDIVISIONS.values())

func set_bpm(new_bpm: int):
	bpm = new_bpm
	beat_interval = 60.0 / (bpm / 4)

func _process(delta):
	_time_accumulator += delta

	var step_duration = beat_interval / total_subdivs

	while _time_accumulator >= step_duration:
		_time_accumulator -= step_duration
		emit_subdivision_signals(current_subdiv_step)
		current_subdiv_step = (current_subdiv_step + 1) % total_subdivs

func emit_subdivision_signals(step: int):
	for sub in SUBDIVISIONS.keys():
		var div = SUBDIVISIONS[sub]
		if step % (total_subdivs / div) == 0:
			global_subdivision_steps[sub] += 1
			emit_signal("beat", sub)
