extends Node2D

@onready var body_area := $Area2D
@onready var polygon := $Polygon2D
@onready var health_bar := $HealthBar
@onready var hit_particles := $HitParticles
@onready var death_particles := $DeathParticles

var health := 10
var alive := true

func set_y_position(new_y: float) -> void:
	position.y = new_y

func _bounce():
	var bounce_height = -4.0
	var duration = 0.2
	var base_y = position.y
	var bounce_y = base_y + bounce_height

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_method(set_y_position, base_y, bounce_y, duration)

	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_method(set_y_position, bounce_y, base_y, duration)

func _pulse():
	var tween = create_tween()
	polygon.scale = Vector2(1, 1)
	var current_scale = polygon.scale
	var pulse_scale = polygon.scale * 1.1
	
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(polygon, "scale", pulse_scale, 0.03)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(polygon, "scale", current_scale, 0.03)

func _explode():
	alive = false
	polygon.visible = false
	health_bar.visible = false
	death_particles.emitting = true

	await get_tree().create_timer(0.3).timeout
	queue_free()

func _body_entered(area: Area2D):
	if area.is_in_group("bullet"):
		health_bar.visible = true
		var bullet = area.get_parent()
		health -= bullet.damage
		health_bar.value = health
		area.get_parent().free()
		_pulse()
		if health <= 0:
			_explode()
		else:
			hit_particles.emitting = true
	
	elif area.is_in_group("shooter"):
		var shooter = area.get_parent()
		if shooter.preview == false:
			shooter.destroy()
			_explode()
	
	elif area.is_in_group("base"):
		var map = area.get_parent()
		map.damage()
		_explode()

func _on_beat(subdivision):
	if subdivision == "half":
		_bounce()

func set_health(new_health: int):
	health = new_health
	health_bar.max_value = health
	health_bar.value = health

func _ready() -> void:
	body_area.area_entered.connect(_body_entered)
	BeatManager.beat.connect(_on_beat)

func _process(delta: float) -> void:
	if alive:
		position.x -= BeatManager.beat_interval * 40 * delta
