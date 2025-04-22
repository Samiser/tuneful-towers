extends Node

var sequence_bar_scene = preload("res://ui/sequence_bar.tscn")
var editor_bar_scene = preload("res://ui/editor_bar.tscn")

var sequence_bars_dict: Dictionary[Node2D, HBoxContainer] = {}
var sequence_editor_dict: Dictionary[Node2D, HBoxContainer] = {}

@onready var sequence_bars := $SequenceBars
@onready var sequence_editor := $SequenceEditor
@onready var sequence_editor_toggle := $SequenceEditorToggle

@onready var intro_card: ColorRect = $IntroCard
@onready var wildcards: Sprite2D = $Wildcards

func play_intro_sequence():
	intro_card.visible = true
	wildcards.visible = true
	wildcards.modulate.a = 0.0

	var tween = create_tween()

	tween.tween_property(wildcards, "modulate:a", 1.0, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(2.5)

	tween.tween_property(wildcards, "modulate:a", 0.0, 1.5)
	tween.parallel().tween_property(intro_card, "modulate:a", 0.0, 1.5)

	tween.finished.connect(func():
		wildcards.queue_free()
		intro_card.queue_free()
	)

func setup(towers: Array):
	play_intro_sequence()
	sequence_editor_toggle.gui_input.connect(_on_gui_input)

	for tower in towers:
		_add_tower(tower)

func _add_ui_bar(tower: Node2D, scene: PackedScene, dict: Dictionary, parent: Node):
	var bar = scene.instantiate()
	dict[tower] = bar
	bar.active_color = tower.color

	tower.shooter_added.connect(bar.shooter_added)
	tower.shooter_destroyed.connect(bar.shooter_destroyed)
	tower.beat.connect(bar.highlight_step)

	parent.add_child(bar)

func _add_tower(tower: Node2D):
	_add_ui_bar(tower, sequence_bar_scene, sequence_bars_dict, sequence_bars)
	_add_ui_bar(tower, editor_bar_scene, sequence_editor_dict, sequence_editor)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_parent().tower_manager.towers[0].hide_hint_arrow(2)
		sequence_editor.visible = !sequence_editor.visible
