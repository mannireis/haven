extends Node2D

const MAX_MARKS := 1500
const PROBE_STEPS := 3

@export_flags_2d_physics var collision_mask := 1
@export var rays_per_pulse := 64
@export var ray_speed := 500.0
@export var max_distance := 900.0
@export var max_bounces := 3
@export var bounce_energy := 0.6
@export var min_energy := 0.1
@export var trail_length := 18.0
@export var ray_width := 1.5
@export var mark_lifetime := 4.0
@export var edge_half_length := 12.0
@export var draw_edge_lines := true
@export var color_ramp: Gradient

var marks: Array = []
var _rays: Array = []


func _ready() -> void:
	add_to_group("echo_manager")
	if color_ramp == null:
		color_ramp = Gradient.new()
		color_ramp.set_color(0, Color(0.6, 0.9, 1.0))    # cyan
		color_ramp.set_color(1, Color(1.0, 0.3, 0.6))    # magenta
		color_ramp.add_point(0.5, Color(1.0, 0.9, 0.4))  # yellow


func emit(world_pos: Vector2, source: CollisionObject2D = null) -> void:
	var exclude: Array[RID] = []
	if source != null:
		exclude.append(source.get_rid())
	var start_angle := randf() * TAU
	for k in rays_per_pulse:
		_rays.append({
			"pos": world_pos,
			"dir": Vector2.from_angle(start_angle + TAU * k / rays_per_pulse),
			"energy": 1.0,
			"dist": 0.0,
			"bounces": 0,
			"ex": exclude,
		})


func _ray_color(dist: float, bounces: int) -> Color:
	var t := maxf(dist / max_distance, float(bounces) / float(max_bounces))
	return color_ramp.sample(clampf(t * 2, 0.0, 1.0))


func _physics_process(delta: float) -> void:
	var space := get_world_2d().direct_space_state
	var step := ray_speed * delta

	for i in range(_rays.size() - 1, -1, -1):
		var r: Dictionary = _rays[i]
		var from: Vector2 = r["pos"]
		var to: Vector2 = from + r["dir"] * step

		var q := PhysicsRayQueryParameters2D.create(from, to, collision_mask, r["ex"])
		q.hit_from_inside = false
		var res := space.intersect_ray(q)

		if res.is_empty():
			r["pos"] = to
			r["dist"] += step
		else:
			var hit_pos: Vector2 = res["position"]
			var normal: Vector2 = res["normal"]
			r["dist"] += from.distance_to(hit_pos)
			_add_mark(space, hit_pos, normal, r["energy"], r["ex"], _ray_color(r["dist"], r["bounces"]))
			r["bounces"] += 1
			r["energy"] *= bounce_energy
			r["dir"] = (r["dir"] as Vector2).bounce(normal)
			r["pos"] = hit_pos + normal * 0.5

		if r["dist"] >= max_distance or r["bounces"] > max_bounces or r["energy"] < min_energy:
			_rays.remove_at(i)


func _add_mark(space: PhysicsDirectSpaceState2D, pos: Vector2, normal: Vector2, energy: float, exclude: Array, col: Color) -> void:
	if marks.size() >= MAX_MARKS:
		marks.pop_front()
	marks.append({
		"pos": pos,
		"normal": normal,
		"age": 0.0,
		"energy": energy,
		"col": col,
		"a": _surface_extent(space, pos, normal, -1.0, exclude),
		"b": _surface_extent(space, pos, normal, 1.0, exclude),
	})


func _surface_extent(space: PhysicsDirectSpaceState2D, pos: Vector2, normal: Vector2, sgn: float, exclude: Array) -> float:
	var tangent := normal.orthogonal() * sgn
	var reached := 0.0
	for s in range(1, PROBE_STEPS + 1):
		var d := edge_half_length * float(s) / PROBE_STEPS
		var p := pos + tangent * d
		var q := PhysicsRayQueryParameters2D.create(p + normal * 3.0, p - normal * 3.0, collision_mask, exclude)
		if space.intersect_ray(q).is_empty():
			break
		reached = d
	return reached


func _process(delta: float) -> void:
	for i in range(marks.size() - 1, -1, -1):
		marks[i]["age"] += delta
		if marks[i]["age"] >= mark_lifetime:
			marks.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for r in _rays:
		var c := Color(_ray_color(r["dist"], r["bounces"]), r["energy"])
		draw_line(r["pos"] - r["dir"] * trail_length, r["pos"], c, ray_width)

	if draw_edge_lines:
		for m in marks:
			var t: float = 1.0 - m["age"] / mark_lifetime
			var c := Color(m["col"], m["energy"] * pow(t, 1.5))
			var along: Vector2 = (m["normal"] as Vector2).orthogonal()
			draw_line(m["pos"] - along * maxf(m["a"], 1.5), m["pos"] + along * maxf(m["b"], 1.5), c, 2.0)
