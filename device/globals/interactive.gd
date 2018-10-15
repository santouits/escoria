extends Node

# interactive.gd

export(Script) var animations

var terrain
var walk_path
var walk_context
var moved
var last_scale = Vector2(1, 1)
var last_deg = null
var last_dir = 0
var animation
var state = ""
var walk_destination
var path_ofs
var pose_scale = 1
var task
var sprites = []

export var speed = 300
export var scale_on_map = false
export var light_on_map = false setget set_light_on_map

# This appears to be slightly faster in _process than checking
# `self is Node2D` or something similar on every loop
onready var self_has_z_index = self is Node2D

func set_light_on_map(p_light):
	light_on_map = p_light
	if light_on_map:
		_update_terrain()
	else:
		modulate(Color(1, 1, 1, 1))

func walk_stop(pos):
	set_position(pos)
	walk_path = []

	# Walking is not a state, but we must re-set our previous state to reset the animation
	set_state(state)

	task = null
	if "idles" in animations:
		pose_scale = animations.idles[last_dir + 1]
	_update_terrain(self_has_z_index)

	if walk_context != null:
		vm.finished(walk_context)
		walk_context = null

func walk_to(pos, context = null):
	walk_path = terrain.get_path(get_position(), pos)
	walk_context = context
	if walk_path.size() == 0:
		walk_stop(get_position())
		set_process(false)
		task = null
		return
	moved = true
	walk_destination = walk_path[walk_path.size()-1]
	if terrain.is_solid(pos):
		walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0.0
	task = "walk"
	set_process(true)

func walk(pos, speed, context = null):
	walk_to(pos, context)

func modulate(color):
	for s in sprites:
		s.set_modulate(color)

func _process(time):
	if task == "walk":
		var to_walk = speed * last_scale.x * time
		var pos = get_position()
		var old_pos = pos
		if walk_path.size() > 0:
			while to_walk > 0:
				var next
				if walk_path.size() > 1:
					next = walk_path[path_ofs + 1]
				else:
					next = walk_path[path_ofs]

				var dist = pos.distance_to(next)

				if dist > to_walk:
					var n = (next - pos).normalized()
					pos = pos + n * to_walk
					break
				pos = next
				to_walk -= dist
				path_ofs += 1
				if path_ofs >= walk_path.size() - 1:
					walk_stop(walk_destination)
					set_process(false)
					return

		var angle = (old_pos.angle_to_point(pos)) * -1
		set_position(pos)

		last_deg = vm._get_deg_from_rad(angle)
		last_dir = vm._get_dir_deg(last_deg, self.name, animations)

		if animation:
			if animation.get_current_animation() != animations.directions[last_dir]:
				animation.play(animations.directions[last_dir])
			pose_scale = animations.directions[last_dir+1]

		# If a z-indexed item is moved, forcibly update its z index
		if self is esc_type.ITEM:
			_update_terrain(self_has_z_index)

func turn_to(deg):
	if deg < 0 or deg > 360:
		vm.report_errors("interactive", ["Invalid degree to turn to " + str(deg)])

	moved = true

	last_deg = deg
	last_dir = vm._get_dir_deg(deg, self.name, animations)

	if animation and animations and "directions" in animations:
		if !animation.get_current_animation() or animation.get_current_animation() != animations.directions[last_dir]:
			# XXX: This requires manually scripting a wait
			# and setting the correct idle animation
			animation.play(animations.directions[last_dir])
		pose_scale = animations.directions[last_dir + 1]
		_update_terrain()

func set_angle(deg):
	if deg < 0 or deg > 360:
		# Compensate for savegame files during a broken version of Escoria
		if vm.loading_game:
			vm.report_warnings("interactive", ["Reset invalid degree " + str(deg)])
			deg = 0
		else:
			vm.report_errors("interactive", ["Invalid degree to turn to " + str(deg)])

	moved = true

	last_deg = deg
	last_dir = vm._get_dir_deg(deg, self.name, animations)

	if animation and animations and "idles" in animations:
		pose_scale = animations.idles[last_dir + 1]
		_update_terrain()

func _find_sprites(p = null):
	if p is CanvasItem:
		sprites.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_sprites(p.get_child(i))

func _ready():
	if has_node("../terrain"):
		terrain = get_node("../terrain")

	_find_sprites(self)

	if Engine.is_editor_hint():
		return
	if has_node("animation"):
		animation = get_node("animation")
