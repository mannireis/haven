extends ColorRect

@onready var mask_vp: SubViewport = $"../SubViewport"
var player: Node2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	(material as ShaderMaterial).set_shader_parameter("mask_tex", mask_vp.get_texture())
	_resize()
	get_viewport().size_changed.connect(_resize)
	RenderingServer.frame_pre_draw.connect(_sync)


func _resize() -> void:
	mask_vp.size = Vector2i(get_viewport().get_visible_rect().size)


func _sync() -> void:
	var vp := get_viewport()
	var xform := vp.get_canvas_transform()
	mask_vp.canvas_transform = xform

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			push_warning("Overlay: no node in group 'player'")
			return

	var m := material as ShaderMaterial
	m.set_shader_parameter("viewport_size", vp.get_visible_rect().size)
	m.set_shader_parameter("player_pos", xform * player.global_position)
