extends Control

func _ready() -> void:
	Raycast.get_child(0).visible = false


func _on_button_pressed() -> void:
	$AnimationPlayer.play("cutscene")
	await $AnimationPlayer.animation_finished
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
