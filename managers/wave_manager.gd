extends Node

var map: Node
var towers: Array

@export var time_between_enemies := 0.5
@export var time_between_waves := 4.0
@export var wave_increase := 1

@export var enemy_scene := preload("res://enemies/enemy/enemy.tscn")

var wave_number := 1

func setup(towers_in: Array, map_in: Node):
	map = map_in
	towers = towers_in
	towers[0].tutorial_finished.connect(start)

func start():
	await get_tree().process_frame
	_loop_waves()

func _loop_waves() -> void:
	while true:
		print("Starting wave ", wave_number)

		await _spawn_wave(wave_number)
		wave_number += wave_increase

		await _wait_for_enemies_to_clear()

		if wave_number >= 4:
			towers[1].visible = true
		if wave_number >= 8:
			towers[2].visible = true
		if wave_number >= 10:
			towers[3].visible = true

		if wave_number < 10 and wave_number % 2 == 0:
			for tower in towers:
				tower.money = tower.cost
			map.set_row_count(wave_number / 2.0 + 1.0)
			map.reveal_lanes(wave_number / 2.0 + 1.0)

		await get_tree().create_timer(time_between_waves).timeout

func _spawn_wave(count: int) -> void:
	var lanes = map.get_enemy_lanes()
	var lane_index := 0
	lanes.shuffle()

	for i in range(count * 2):
		var lane = lanes[lane_index % lanes.size()]
		_spawn_enemy(lane)
		lane_index += 1

		var random_offset = randf_range(-0.4, 1.0)
		await get_tree().create_timer(time_between_enemies + random_offset).timeout
	
func _spawn_enemy(y: int) -> void:
	var x = map.bounds.x.right + 2
	var pos = map.tilemap.map_to_local(Vector2(x, y))

	var enemy = enemy_scene.instantiate()
	enemy.position = pos
	get_parent().add_child(enemy)

	var base_health = 10
	var health_increase = wave_number - 1
	enemy.set_health(base_health + health_increase)

func _wait_for_enemies_to_clear() -> void:
	while true:
		await get_tree().create_timer(1).timeout
		var enemies_alive := false

		for child in get_parent().get_children():
			if child != null and child.is_in_group("enemy"):
				enemies_alive = true
				break

		if not enemies_alive:
			break
