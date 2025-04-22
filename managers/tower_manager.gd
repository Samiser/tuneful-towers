extends Node

var towers: Array
var map: Node

var selected_tower: Node2D = null
var preview_shooter: Node2D = null
var shooters: Dictionary[Vector2, Node2D] = {}

var harmony_step_notes := {}
var bass_step_notes := {}

func _set_shooter_synergy(tower: Node2D, note_data: Dictionary):
	for shooter in tower.shooters:
		if shooter.index == note_data.step:
			shooter.has_synergy = true
			print(shooter, " ", shooter.has_synergy)

func _check_synergy(global_step: int, tower: Node2D):
	await get_tree().process_frame
	
	for shooter in tower.shooters:
		shooter.has_synergy = false

	if not (harmony_step_notes.has(global_step) and bass_step_notes.has(global_step)):
		return

	var h_data = harmony_step_notes[global_step]
	var b_data = bass_step_notes[global_step]

	if tower.tower_type == "harmony":
		print(h_data, b_data)

	if tower.tower_type in ["harmony", "bass"] and h_data.note == b_data.note:
		_set_shooter_synergy(tower, b_data if tower.tower_type == "bass" else h_data)

func _check_melody_synergy(global_melody_step: int, melody_note: int, tower: Node2D, step: int):
	await get_tree().process_frame

	var matched := false

	for step_notes in [harmony_step_notes, bass_step_notes]:
		if step_notes.size() > 0:
			var latest_step = step_notes.keys().max()
			var note = step_notes[latest_step].note
			if note == melody_note:
				matched = true
				break

	for shooter in tower.shooters:
		shooter.has_synergy = false
		if matched and shooter.index == step:
			shooter.has_synergy = true
			print("Melody SYNERGY! Step:", step, "Note:", melody_note)

func _on_tower_beat(tower: Node2D, step: int, note: int):
	var subdivision = tower.selected_subdivision
	var global_step = BeatManager.global_subdivision_steps[subdivision]
	var local_step = (global_step - 1) % tower.get_sequence_length()

	match tower.tower_type:
		"harmony":
			harmony_step_notes[global_step] = { "note": note, "step": local_step }
			_check_synergy(global_step, tower)
		"bass":
			bass_step_notes[global_step] = { "note": note, "step": local_step }
			_check_synergy(global_step, tower)
		"melody":
			_check_melody_synergy(global_step, note, tower, local_step)

func _on_shooter_destroyed(_tower: Node2D, shooter: Node2D):
	if shooter:
		shooters.erase(shooter.global_position)

func setup(towers_in: Array, map_in: Node) -> void:
	towers = towers_in
	map = map_in

	for tower in towers:
		tower.shooter_destroyed.connect(_on_shooter_destroyed)
		tower.clicked.connect(_on_tower_clicked)
		tower.beat.connect(_on_tower_beat)

	map.clicked.connect(_on_map_clicked)

func _on_tower_clicked(tower: Node2D) -> void:
	if selected_tower == tower:
		selected_tower.deselect()
		selected_tower = null
		_clear_preview()
		return

	if not tower.can_buy():
		return
		
	if selected_tower:
		selected_tower.deselect()

	selected_tower = tower
	selected_tower.select()

	_clear_preview()
	preview_shooter = selected_tower.spawn_preview_shooter()
	add_child(preview_shooter)

func _on_map_clicked(pos: Vector2) -> void:
	if towers[0].hint_arrows[1].visible:
		towers[0].hide_hint_arrow(1)
	
	if selected_tower == null:
		return

	if !shooters.has(pos):
		var shooter = selected_tower.spawn_shooter_at(pos)
		shooters[pos] = shooter
		selected_tower.deselect()
		selected_tower = null
		_clear_preview()

func _clear_preview():
	if preview_shooter:
		preview_shooter.queue_free()
		preview_shooter = null

func _process(_delta: float) -> void:
	_process_preview_shooter()

func _process_preview_shooter():
	if selected_tower == null or preview_shooter == null:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	mouse_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var map_pos = map.tilemap.local_to_map(mouse_pos)
	var world_pos = map.tilemap.map_to_local(map_pos)

	if map.within_bounds(map_pos) and !shooters.has(world_pos):
		preview_shooter.global_position = world_pos
		preview_shooter.visible = true
	else:
		preview_shooter.visible = false
