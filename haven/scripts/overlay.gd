extends ColorRect

const RAYS := 180
const MAX_LIGHTS := 8

@export var mask_vp: SubViewport
@export_flags_2d_physics var collision_mask := 1

var _active_ids: Array[int] = []
var _vis_img: Image
var _vis_tex: ImageTexture
var _resizing := false
var _syncing := false


func _ready() -> void:
	if mask_vp == null:
		mask_vp = get_parent().find_child("*Viewport*", false, false) as SubViewport
	if mask_vp == null:
		push_error("Overlay: assign the SubViewport to 'Mask Vp' in the inspector")
		return
	if get_viewport() == mask_vp:
		push_error("Overlay: the ColorRect must be a sibling of the SubViewport, not inside it")
		return

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_vis_img = Image.create(RAYS, MAX_LIGHTS, false, Image.FORMAT_RF)
	_vis_img.fill(Color(-1.0, 0.0, 0.0, 1.0))
	_vis_tex = ImageTexture.create_from_image(_vis_img)

	var m := material as ShaderMaterial
	m.set_shader_parameter("mask_tex", mask_vp.get_texture())
	m.set_shader_parameter("vis_tex", _vis_tex)

	_resize()
	if not get_viewport().size_changed.is_connected(_resize):
		get_viewport().size_changed.connect(_resize)
	if not RenderingServer.frame_pre_draw.is_connected(_sync):
		RenderingServer.frame_pre_draw.connect(_sync)


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync):
		RenderingServer.frame_pre_draw.disconnect(_sync)


func _resize() -> void:
	if _resizing or not is_instance_valid(mask_vp):
		return
	_resizing = true
	var s := Vector2i(get_viewport().get_visible_rect().size)
	if mask_vp.size != s:
		mask_vp.size = s
	_resizing = false


func _physics_process(_delta: float) -> void:
	if _vis_img == null or not is_instance_valid(mask_vp):
		return

	var vp := get_viewport()
	var xform := vp.get_canvas_transform()
	var screen := vp.get_visible_rect().size
	var center := screen * 0.5
	var zoom := xform.get_scale().x

	var candidates: Array = []
	for n in get_tree().get_nodes_in_group("echo_light"):
		if not is_instance_valid(n) or n.is_queued_for_deletion():
			continue
		var l := n as EchoLight
		if l == null or not l.enabled or not l.is_visible_in_tree():
			continue
		var sp := xform * l.global_position
		var margin := l.outer_radius * zoom
		if sp.x < -margin or sp.y < -margin or sp.x > screen.x + margin or sp.y > screen.y + margin:
			continue
		candidates.append({"id": l.get_instance_id(), "d": sp.distance_squared_to(center)})
	candidates.sort_custom(func(a, b): return a["d"] < b["d"])

	_active_ids.clear()
	var space := get_world_2d().direct_space_state
	for i in mini(candidates.size(), MAX_LIGHTS):
		var id: int = candidates[i]["id"]
		var l := instance_from_id(id) as EchoLight
		if l == null:
			continue
		_active_ids.append(id)
		_cast_visibility(space, l, _active_ids.size() - 1)
	_vis_tex.update(_vis_img)


func _cast_visibility(space: PhysicsDirectSpaceState2D, l: EchoLight, row: int) -> void:
	if not l.blocked_by_walls:
		for k in RAYS:
			_vis_img.set_pixel(k, row, Color(-1.0, 0.0, 0.0, 1.0))
		return

	var origin := l.global_position
	var exclude: Array[RID] = []
	var node: Node = l
	while node != null:
		if node is CollisionObject2D:
			exclude.append((node as CollisionObject2D).get_rid())
			break
		node = node.get_parent()

	for k in RAYS:
		var angle := (float(k) + 0.5) / RAYS * TAU - PI
		var to := origin + Vector2.from_angle(angle) * l.outer_radius
		var q := PhysicsRayQueryParameters2D.create(origin, to, collision_mask, exclude)
		q.hit_from_inside = false
		var res := space.intersect_ray(q)
		var dist := -1.0
		if not res.is_empty():
			dist = origin.distance_to(res["position"])
		_vis_img.set_pixel(k, row, Color(dist, 0.0, 0.0, 1.0))


func _sync() -> void:
	if _syncing or not is_instance_valid(mask_vp) or not is_inside_tree():
		return
	_syncing = true

	var vp := get_viewport()
	var xform := vp.get_canvas_transform()
	var zoom := xform.get_scale().x
	mask_vp.canvas_transform = xform

	var pos := PackedVector2Array()
	var inner := PackedFloat32Array()
	var outer := PackedFloat32Array()
	var strength := PackedFloat32Array()
	var colors := PackedColorArray()
	pos.resize(MAX_LIGHTS)
	inner.resize(MAX_LIGHTS)
	outer.resize(MAX_LIGHTS)
	strength.resize(MAX_LIGHTS)
	colors.resize(MAX_LIGHTS)

	for i in _active_ids.size():
		var l := instance_from_id(_active_ids[i]) as EchoLight
		if l == null:
			continue
		pos[i] = xform * l.global_position
		inner[i] = l.inner_radius * zoom
		outer[i] = l.outer_radius * zoom
		strength[i] = l.strength
		colors[i] = l.color

	var m := material as ShaderMaterial
	m.set_shader_parameter("viewport_size", vp.get_visible_rect().size)
	m.set_shader_parameter("zoom", zoom)
	m.set_shader_parameter("light_count", _active_ids.size())
	m.set_shader_parameter("light_pos", pos)
	m.set_shader_parameter("light_inner", inner)
	m.set_shader_parameter("light_outer", outer)
	m.set_shader_parameter("light_strength", strength)
	m.set_shader_parameter("light_color", colors)

	_syncing = false
