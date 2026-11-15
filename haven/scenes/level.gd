extends Node2D

@onready var enemies: Node2D = $enemies

func _ready() -> void:
	Raycast.get_child(0).visible = true


func _process(delta: float) -> void:
	if enemies.get_child_count() == 0:
		print("complete")
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
