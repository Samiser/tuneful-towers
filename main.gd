extends Node2D

@onready var map := $Map

@onready var tower_manager := $TowerManager
@onready var wave_manager := $WaveManager
@onready var ui_manager := $UIManager

func _ready() -> void:
	var towers := get_tree().get_nodes_in_group("tower")
	
	tower_manager.setup(towers, map)
	wave_manager.setup(towers, map)
	ui_manager.setup(towers)
