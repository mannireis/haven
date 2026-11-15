extends Control


func _ready() -> void:
	Raycast.get_child(0).visible = false


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_2.tscn")


func _on_button_3_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_3.tscn")
