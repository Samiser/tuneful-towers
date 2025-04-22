extends Node2D

var speed := 100.0
var damage := 1
var direction: Vector2 = Vector2.RIGHT

func _calculate_tempo_speed() -> float:
	var beat_interval = BeatManager.beat_interval
	var distance_per_beat = 512.0
	return distance_per_beat / beat_interval

func _physics_process(delta):
	speed = _calculate_tempo_speed()
	position += direction * speed * delta
