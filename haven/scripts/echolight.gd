class_name EchoLight
extends Node2D

@export var enabled := true
@export var inner_radius := 8
@export var outer_radius := 16
@export var strength := 0.8
@export var color := Color(0.6, 0.9, 1.0)
@export var blocked_by_walls := true


func _ready() -> void:
	add_to_group("echo_light")
