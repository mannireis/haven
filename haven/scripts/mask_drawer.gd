extends Node2D

@export var edge_width := 2.5


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var manager := get_tree().get_first_node_in_group("echo_manager")
	if manager == null:
		return

	for m in manager.marks:
		var t: float = 1.0 - m["age"] / manager.mark_lifetime
		var a: float = clampf(m["energy"], 0.0, 1.0) * pow(t, 1.5)
		var normal: Vector2 = m["normal"]
		var along := normal.orthogonal()
		var inset := normal * (edge_width * 0.5)
		draw_line(
			m["pos"] - along * maxf(m["a"], 1.5) - inset,
			m["pos"] + along * maxf(m["b"], 1.5) - inset,
			Color(m["col"], a), edge_width, false)
