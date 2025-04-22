extends ColorRect

var step_index := 0
var active := false
@onready var note_polygon := $NotePolygon

var note: int = 0:
	set(value):
		note = value
		_update_note_polygon()

signal hovered(step)

func pulse():
	if not note_polygon:
		return

	var tween := create_tween()
	var original_scale = Vector2.ONE
	var pulse_scale = original_scale * 1.2
	var duration := 0.1

	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(note_polygon, "scale", pulse_scale, 0.05)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(note_polygon, "scale", original_scale, 0.5)

func _ready() -> void:
	note_polygon.color = Color(0, 0, 0, 0.2)
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	if active:
		emit_signal("hovered", self)

func _on_mouse_exited():
	if active:
		emit_signal("hovered", null)

func _notification(what):
	if what == NOTIFICATION_RESIZED and note_polygon:
		note_polygon.position = size / 2

func _generate_regular_polygon(sides: int, radius: float = 4.0, rotation_offset: float = -PI / 2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(sides):
		var angle = TAU * i / sides + rotation_offset
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _update_note_polygon():
	if note_polygon:
		var sides = clampi(note + 3, 3, 12)
		var radius = 22.0
		note_polygon.polygon = _generate_regular_polygon(sides, radius)

func _get_drag_data(_position: Vector2) -> Variant:
	if not active:
		return null
	
	var preview = duplicate()
	preview.scale = Vector2(0.04, 0.11)
	preview.pivot_offset = preview.size / 2
	preview.z_index = 50
	set_drag_preview(preview)
	return self

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is ColorRect

func _drop_data(_position: Vector2, data: Variant) -> void:
	if data == self:
		return

	var container := get_parent()
	if container:
		container.call_deferred("_reorder_step", data, self)
