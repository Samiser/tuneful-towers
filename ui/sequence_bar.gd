extends HBoxContainer

@export var min_steps := 4
var steps: Array[ColorRect] = []
var current_step := -1

@export var inactive_color: Color = Color(0, 0, 0, 0.2)
@export var active_color: Color = Color(1, 1, 1)
@export var fade_duration: float = 0.3

var tweens := {}

func _ready():
	for i in range(min_steps):
		add_step()

func add_step():
	var step = ColorRect.new()
	step.color = inactive_color
	step.custom_minimum_size = Vector2(20, 20)
	add_child(step)
	steps.append(step)

func shooter_added(tower: Node2D, _shooter: Node2D):
	if tower.shooters.size() >= min_steps:
		add_step()

func remove_step():
	if steps.size() > min_steps:
		var step = steps.pop_back()
		step.queue_free()

func shooter_destroyed(_tower: Node2D, _shooter: Node2D):
	remove_step()

func _reset_steps():
	for step in steps:
		step.color = inactive_color

func highlight_step(_tower:Node2D, index: int, _note: int):
	if index < 0 or index >= steps.size():
		return

	var step = steps[index]

	if tweens.has(index):
		if is_instance_valid(tweens[index]):
			tweens[index].kill()

	step.color = active_color

	var tween = create_tween()
	tween.tween_property(step, "color", inactive_color, fade_duration)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)

	tweens[index] = tween
	current_step = index
