extends Node2D

@onready var tilemap := $TileMapLayer
@onready var top_cover := $TopCover
@onready var bottom_cover := $BottomCover

var bounds := {
	"x": {"left": -6, "right": 8},
	"y": {"top": -2, "bottom": 2}
}

signal clicked(position: Vector2)

func reveal_lanes(row_count: int):
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	match row_count:
		2:
			tween.tween_property(bottom_cover, "position", bottom_cover.position + Vector2(0, 64), 1.0)
		3:
			tween.tween_property(top_cover, "position", top_cover.position - Vector2(0, 64), 1.0)
		4:
			tween.tween_property(bottom_cover, "position", bottom_cover.position + Vector2(0, 64), 1.0)
		5:
			tween.tween_property(top_cover, "position", top_cover.position - Vector2(0, 64), 1.0)

func set_row_count(row_count: int):
	var top := (row_count - 1) / 2
	var bottom := row_count - 1 - int(top)
	
	bounds = {
		"x": {"left": bounds.x.left, "right": bounds.x.right},
		"y": {"top": -top, "bottom": bottom}
	}

func get_random_enemy_position() -> Vector2:
	var x = bounds.x.right + 2
	var y_range = abs(bounds.y.bottom) + abs(bounds.y.top) + 1
	var y = bounds.y.top + randi() % y_range
	return Vector2(x, y)

func damage():
	print("taken base damage!")

func get_enemy_lanes() -> Array:
	var lanes = []
	for y in range(bounds.y.top, bounds.y.bottom + 1):
		lanes.append(y)
	return lanes

func within_bounds(map_pos):
	return (map_pos.x >= bounds.x.left
		and map_pos.x <= bounds.x.right
		and map_pos.y <= bounds.y.bottom
		and map_pos.y >= bounds.y.top)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var map_position = tilemap.local_to_map(get_global_mouse_position())
		if within_bounds(map_position):
			emit_signal("clicked", tilemap.map_to_local(map_position))

func _ready() -> void:
	set_row_count(1)
