extends Node2D

@onready var polygon := $Polygon2D
@onready var vision := $VisionArea

var bullet_scene := preload("res://towers/shooter/bullet.tscn")
var bullet_offset := Vector2(16, 0)

var note := 0
var color := Color.WHITE
var damage := 1
var bullet_count := 1
var index := 0

var has_synergy := false

var should_shoot := false
var preview := false

var audio_stream: AudioStreamWAV = null
var note_duration: float = 0.9
var note_spacing: float = 1.0

signal shot(shooter: Node2D)
signal destroyed(shooter: Node2D)

var pool_size := 4
@onready var player := $Player

func _ready() -> void:
	polygon.color = color
	if preview == true:
		make_preview()

func make_preview():
	visible = false
	polygon.color.a = 0.4
	var current_scale = polygon.scale
	var rate = BeatManager.beat_interval / 4
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(polygon, "scale", current_scale * 1.1, rate)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(polygon, "scale", current_scale, rate)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _pulse():
	var tween = create_tween()
	var current_scale = polygon.scale
	var pulse_scale = polygon.scale * 1.1

	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(polygon, "scale", pulse_scale, 0.1)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(polygon, "scale", current_scale, 0.1)

func destroy():
	emit_signal("destroyed", self)
	queue_free()

func shoot():
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	if should_shoot:
		_pulse()
		emit_signal("shot", self)

		player.stream = audio_stream
		player.play()

		for i in range(bullet_count):
			var bullet = bullet_scene.instantiate()
			var random_y_offset = randf_range(-5.0, 5.0)
			var offset = bullet_offset + Vector2(0, random_y_offset)
			bullet.global_position = global_position + offset
			bullet.damage = damage * 2 if has_synergy else damage
			bullet.modulate = Color.YELLOW if has_synergy else color
			bullet.scale = Vector2(2, 2) if has_synergy else Vector2.ONE
			get_tree().current_scene.add_child(bullet)

func _process(_delta: float) -> void:
	should_shoot = false
	var potential_enemies = vision.get_overlapping_areas()
	for potential_enemy in potential_enemies:
		if potential_enemy.get_parent().is_in_group("enemy"):
			should_shoot = true
			break
