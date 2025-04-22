extends Node2D

@onready var click_area := $ClickArea
@onready var polygon := $Polygon2D
@onready var selected_polygon := $SelectedPolygon
@onready var cost_bar := $CostBar
@onready var hint_arrows := [$HintArrow, $HintArrow2, $HintArrow3]

@export var color: Color = Color.WHITE

var note_players: Array[AudioStreamPlayer2D] = []
var audio_stream: AudioStream = null
var audio_streams: Array[AudioStream] = []

var possible_notes: Array[int] = []
var bullet_damage := 2

var bus := "Master"
var bullet_count := 1

var shooter_scene := preload("res://towers/shooter/shooter.tscn")
var shooter_color := Color.WHITE
var shooters: Array[Node2D] = []

var current_note_index := 0

var money := 10.0
var cost := 10.0
var money_increment := 1.0
var number_purchased := 0

var is_pulsing: bool = false
var pulse_tween: Tween = null

var tutorial_has_finished = false

@export_enum("melody", "harmony", "rhythm", "bass") var tower_type := "melody"
@export_enum("full",
	"half",
	"quarter",
	"quarter_triplet",
	"eighth",
	"eighth_quintuplets",
	"eighth_triplet") var selected_subdivision := "full"

signal clicked(tower: Node2D)
signal beat(tower: Node2D, step: int, note: int, sequence_length: int)
signal shooter_added(tower: Node2D, shooter: Node2D)
signal shooter_destroyed(tower: Node2D, shooter: Node2D)
signal tutorial_finished

func _melody_tower():
	possible_notes = [0, 1, 2, 3, 4]
	audio_streams = [
		load("res://towers/melody-pentatonic/melody_pentatonic_000.wav"),
		load("res://towers/melody-pentatonic/melody_pentatonic_001.wav"),
		load("res://towers/melody-pentatonic/melody_pentatonic_002.wav"),
		load("res://towers/melody-pentatonic/melody_pentatonic_003.wav"),
		load("res://towers/melody-pentatonic/melody_pentatonic_004.wav")
	]
	bus = "Melody"

func _rhythm_tower():
	possible_notes = [0, 1, 2, 3]
	bullet_damage = 4
	audio_streams = [
		load("res://towers/rhythm-notes/rhythm_notes_000.wav"),
		load("res://towers/rhythm-notes/rhythm_notes_001.wav"),
		load("res://towers/rhythm-notes/rhythm_notes_002.wav"),
		load("res://towers/rhythm-notes/rhythm_notes_003.wav"),
	]
	money_increment = 2

func _harmony_tower():
	possible_notes = [0, 1, 2, 3, 4, 5, 6]
	bullet_damage = 3
	audio_streams = [
		load("res://towers/harmony-notes/harmony_notes_000.wav"),
		load("res://towers/harmony-notes/harmony_notes_001.wav"),
		load("res://towers/harmony-notes/harmony_notes_002.wav"),
		load("res://towers/harmony-notes/harmony_notes_003.wav"),
		load("res://towers/harmony-notes/harmony_notes_004.wav"),
		load("res://towers/harmony-notes/harmony_notes_005.wav"),
		load("res://towers/harmony-notes/harmony_notes_006.wav")
	]
	bus = "Melody"
	bullet_count = 3
	money_increment = 4

func _bass_tower():
	possible_notes = [0, 1, 2, 3, 4, 5, 6]
	money_increment = 4
	bullet_damage = 10
	audio_streams = [
		load("res://towers/bass-notes/bass_notes_000.wav"),
		load("res://towers/bass-notes/bass_notes_001.wav"),
		load("res://towers/bass-notes/bass_notes_002.wav"),
		load("res://towers/bass-notes/bass_notes_003.wav"),
		load("res://towers/bass-notes/bass_notes_004.wav"),
		load("res://towers/bass-notes/bass_notes_005.wav"),
		load("res://towers/bass-notes/bass_notes_006.wav"),
	]

func _show_hint_arrow(arrow: Node2D):
	arrow.visible = true
	var tween = create_tween()
	tween.set_loops()

	var original_y = arrow.position.y
	var float_amount = 8.0
	var duration = 0.8

	tween.tween_property(arrow, "position:y", original_y - float_amount, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(arrow, "position:y", original_y, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _ready():
	if tower_type == "melody":
		_show_hint_arrow(hint_arrows[0])
		_melody_tower()
	elif tower_type == "rhythm":
		_rhythm_tower()
	elif tower_type == "harmony":
		_harmony_tower()
	elif tower_type == "bass":
		_bass_tower()

	cost_bar.modulate = color
	_start_pulse()
	polygon.color = color
	BeatManager.beat.connect(_on_beat)
	shooter_color = polygon.color
	click_area.connect("input_event", _on_click_area_input_event)

func hide_hint_arrow(index: int) -> void:
	match index:
		1:
			if hint_arrows[1].visible:
				_show_hint_arrow(hint_arrows[2])
				hint_arrows[1].visible = false
				if not tutorial_has_finished:
					emit_signal("tutorial_finished")
					tutorial_has_finished = true
		2:
			if hint_arrows[2].visible:
				hint_arrows[2].visible = false

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("clicked", self)
		if hint_arrows[0].visible:
			hint_arrows[0].visible = false
			_show_hint_arrow(hint_arrows[1])

func can_buy() -> bool:
	return (money >= cost and shooters.size() <= 7)

func _add_money():
	if money < cost:
		money += money_increment
	update_pulse()

func _on_shot(shooter: Node2D) -> void:
	_add_money()

func get_sequence_length():
	var indices = []
	for shooter in shooters:
		indices.append(shooter.index)
	
	var max = indices.max() + 1
	
	return (4 if max < 4 else max)

func _on_beat(subdivision):
	if subdivision == selected_subdivision:
		shooters = _get_shooter_notes()
		for shooter in shooters:
			if shooter.index == current_note_index:
				emit_signal("beat", self, current_note_index, shooter.note)
				shooter.shoot()

		current_note_index = (current_note_index + 1) % max(shooters.size(), 4)

func select() -> void:
	selected_polygon.modulate.a = 0
	selected_polygon.visible = true

	var tween = create_tween()
	var start_color = selected_polygon.modulate
	var end_color = start_color
	end_color.a = 0.9
	tween.tween_property(selected_polygon, "modulate", end_color, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func deselect() -> void:
	var tween = create_tween()
	var start_color = selected_polygon.modulate
	var end_color = start_color
	end_color.a = 0.0
	tween.tween_property(selected_polygon, "modulate", end_color, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _get_shooter_notes():
	var new_shooters: Array[Node2D] = []

	for child in self.get_children():
		if child.is_in_group("shooter"):
			new_shooters.append(child)

	new_shooters.sort_custom(func(a, b): return a.index < b.index)
	
	return new_shooters

func _on_shooter_destroyed(shooter: Node2D):
	emit_signal("shooter_destroyed", self, shooter)
	cost_bar.visible = true

func spawn_shooter_at(pos: Vector2) -> Node2D:
	var shooter = shooter_scene.instantiate()

	shooter.global_position = pos - position
	var random_note = possible_notes[randi_range(0, possible_notes.size() - 1)]

	shooter.note = random_note
	shooter.color = shooter_color
	shooter.damage = bullet_damage
	shooter.bullet_count = bullet_count
	shooter.index = shooters.size()
	shooter.audio_stream = audio_streams[random_note]
	shooter.shot.connect(_on_shot)
	shooter.destroyed.connect(_on_shooter_destroyed)

	money = 0.0
	if number_purchased < 7:
		number_purchased += 1
		cost *= 1.8
	
	if shooters.size() > 6:
		cost_bar.visible = false

	emit_signal("shooter_added", self, shooter)
	add_child(shooter)
	_stop_pulse()
	return shooter

func spawn_preview_shooter() -> Node2D:
	var shooter = shooter_scene.instantiate()
	shooter.color = shooter_color
	shooter.preview = true

	return shooter

func _start_pulse():
	is_pulsing = true
	var current_scale = polygon.scale
	var rate = BeatManager.beat_interval / 4
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(polygon, "scale", current_scale * 1.1, rate)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.parallel().tween_property(selected_polygon, "scale", current_scale * 1.1, rate)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.tween_property(polygon, "scale", current_scale, rate)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse_tween.parallel().tween_property(selected_polygon, "scale", current_scale, rate)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_pulse():
	is_pulsing = false
	polygon.scale = Vector2.ONE
	selected_polygon.scale = Vector2.ONE

	if pulse_tween:
		pulse_tween.kill()
		pulse_tween = null

func update_pulse():
	if can_buy() and not is_pulsing:
		_start_pulse()
	elif not can_buy() and is_pulsing:
		_stop_pulse()

func _process(_delta: float) -> void:
	cost_bar.value = money
	cost_bar.max_value = cost
	update_pulse()
