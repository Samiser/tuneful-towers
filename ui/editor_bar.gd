extends HBoxContainer

@export var min_steps := 4
var steps: Array[ColorRect] = []
var shooters: Dictionary[int, Node2D] = {}

@export var inactive_color: Color = Color(0, 0, 0, 0.2)
@export var active_color: Color = Color(1, 1, 1)

var hovered_step: ColorRect = null

var sequence_step_scene = preload("res://ui/sequence_step.tscn")

var tweens := {}

func _ready():
	for i in range(min_steps):
		add_step()

func shooter_added(tower: Node2D, shooter: Node2D) -> void:
	var insert_index := -1
	for i in range(steps.size()):
		if not steps[i].active:
			insert_index = i
			break

	if insert_index == -1:
		var step = add_step()
		insert_index = steps.size() - 1

	shooter.index = insert_index
	shooters[insert_index] = shooter

	var step = steps[insert_index]
	step.active = true
	step.color = active_color
	step.note = shooter.note

func remove_step(shooter: Node2D) -> void:
	var index = shooter.index

	if shooters.has(index):
		shooters.erase(index)

		if index < 4:
			steps[index].color = inactive_color
			steps[index].note = -1
			steps[index].note_polygon.polygon = []
			steps[index].active = false
		else:
			var step := steps[index]
			steps.remove_at(index)
			step.queue_free()

			for i in range(index, steps.size()):
				steps[i].step_index = i
				if shooters.has(i + 1):
					var s := shooters[i + 1]
					s.index = i
					shooters[i] = s
					shooters.erase(i + 1)
					steps[i].color = active_color
					steps[i].note = s.note

func shooter_destroyed(tower: Node2D, shooter: Node2D):
	remove_step(shooter)

func highlight_step(_tower: Node2D, index: int, _note: int):
	if index < 0 or index >= steps.size():
		return

	steps[index].pulse()

func highlight_note(target_note: int):
	for step in steps:
		if step.active and step.note == target_note:
			step.note_polygon.color = Color.YELLOW

func clear_highlights():
	for step in steps:
		step.note_polygon.color = Color(0, 0, 0, 0.2)

func _on_step_hovered(step):
	for bar in get_parent().get_children():
		if bar.has_method("clear_highlights"):
			bar.clear_highlights()

	if step == null:
		return

	var target_note = step.note
	for bar in get_parent().get_children():
		if bar.has_method("highlight_note"):
			bar.highlight_note(target_note)

func add_step() -> ColorRect:
	var step = sequence_step_scene.instantiate()
	step.color = inactive_color if shooters.size() <= 4 else active_color
	step.custom_minimum_size = Vector2(80, 20)
	step.hovered.connect(_on_step_hovered)
	add_child(step)
	steps.append(step)
	return step

func _reorder_step(dragged_step: Control, target_step: Control) -> void:
	var old_index = steps.find(dragged_step)
	var new_index = steps.find(target_step)

	if old_index == -1 or new_index == -1:
		return

	var shooter = shooters[old_index]
	if shooters.has(new_index):
		var old_shooter = shooters[new_index]
		old_shooter.index = old_index
		shooters[old_index] = old_shooter
	else:
		shooters.erase(old_index)
	shooters[new_index] = shooter
	shooter.index = new_index
	
	for step in steps:
		step.color = inactive_color
		step.active = false
		step.note_polygon.polygon = []
	
	for key in shooters.keys():
		steps[key].active = true
		steps[key].color = active_color
		steps[key].note = shooters[key].note
		
	while steps.size() > min_steps and not steps[steps.size() - 1].active:
		var step = steps.pop_back()
		step.queue_free()
