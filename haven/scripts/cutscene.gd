extends Control

signal any_input

func _ready() -> void:
	Raycast.get_child(0).visible = false


func _on_button_pressed() -> void:
	$AnimationPlayer.play("cutscene")
	await $AnimationPlayer.animation_finished
	await get_tree().create_timer(0.5)
	await any_input
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _input(event: InputEvent) -> void:
	var pressed: bool = event.is_pressed() and not event.is_echo()
	var stick_moved: bool = event is InputEventJoypadMotion and abs(event.axis_value) > 0.5
	if pressed or stick_moved:
		any_input.emit()
