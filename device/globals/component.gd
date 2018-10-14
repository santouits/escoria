extends Node

var entity

# Copy exported variables from entity here
var global_id
var animations

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
var anim_notify = null
var anim_scale_override = null

var ui_anim = null

var event_table = {}

var clicked = false

var interact_pos

# This appears to be slightly faster in _process than checking
# `self is Node2D` or something similar on every loop
var self_has_z_index = false

func set_light_on_map(p_light):
	entity.light_on_map = p_light
	if entity.light_on_map:
		_update_terrain()
	else:
		entity.modulate(Color(1, 1, 1, 1))

func walk_stop(pos):
	entity.set_position(pos)
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
	walk_path = terrain.get_path(entity.get_position(), pos)
	walk_context = context
	if walk_path.size() == 0:
		walk_stop(entity.get_position())
		entity.set_process(false)
		task = null
		return
	moved = true
	walk_destination = walk_path[walk_path.size()-1]
	if terrain.is_solid(pos):
		walk_destination = walk_path[walk_path.size()-1]
	path_ofs = 0.0
	task = "walk"
	entity.set_process(true)

func walk(pos, speed, context = null):
	walk_to(pos, context)

func modulate(color):
	for s in sprites:
		s.set_modulate(color)

func _process(time):
	if task == "walk":
		var to_walk = entity.speed * last_scale.x * time
		var pos = entity.get_position()
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
					entity.set_process(false)
					return

		var angle = (old_pos.angle_to_point(pos)) * -1
		entity.set_position(pos)

		last_deg = vm._get_deg_from_rad(angle)
		last_dir = vm._get_dir_deg(last_deg, get_parent().name, animations)

		if animation:
			if animation.get_current_animation() != animations.directions[last_dir]:
				animation.play(animations.directions[last_dir])
			pose_scale = animations.directions[last_dir+1]

		# If a z-indexed item is moved, forcibly update its z index
		if entity is esc_type.ITEM:
			_update_terrain(self_has_z_index)

func turn_to(deg):
	if deg < 0 or deg > 360:
		vm.report_errors("interactive", ["Invalid degree to turn to " + str(deg)])

	moved = true

	last_deg = deg
	last_dir = vm._get_dir_deg(deg, entity.name, animations)

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
	last_dir = vm._get_dir_deg(deg, entity.name, animations)

	if animation and animations and "idles" in animations:
		pose_scale = animations.idles[last_dir + 1]
		_update_terrain()

func _find_sprites(p = null):
	if p is CanvasItem:
		sprites.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_sprites(p.get_child(i))

func is_clicked():
	return clicked

func get_interact_pos():
	if interact_pos:
		return interact_pos.get_global_position()
	else:
		return entity.get_global_position()

func anim_finished(anim_name):
	# TODO use parameter here?
	if anim_notify != null:
		vm.finished(anim_notify)
		anim_notify = null

	if anim_scale_override != null && entity is Node2D:
		entity.set_scale(entity.get_scale() * anim_scale_override)
		anim_scale_override = null

	# Although states are permanent until changed, the underlying animations are not,
	# so we must re-set the state for the appearance of permanence
	set_state(state, true)

	if animations and "idles" in animations:
		pose_scale = animations.idles[last_dir + 1]
		_update_terrain()

func set_active(p_active):
	entity.active = p_active
	if p_active:
		entity.show()
	else:
		entity.hide()

func get_active():
	return entity.active
	#return is_visible()

func run_event(p_ev):
	vm.emit_signal("run_event", p_ev)
	yield(vm, "event_done")

func activate(p_action, p_param = null, p_flags = null):
	#printt("****** activated ", p_action, p_param, p_action in event_table)
	#print_stack()
	if p_param != null:
		p_action = p_action + " " + p_param.global_id

	if p_action in event_table:
		run_event(event_table[p_action])
	else:
		return false
	return true

func get_action():
	return entity.action

func mouse_enter():
	entity.get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "game", "mouse_enter", entity)
	_check_focus(true, false)

func mouse_exit():
	entity.get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, "game", "mouse_exit", entity)
	_check_focus(false, false)

func area_input(viewport, event, shape_idx):
	input(event)

func input(event):
	# TODO: Expand this for other input events than mouse
	if event is InputEventMouseButton || event.is_action("ui_accept"):
		if event.is_pressed():
			clicked = true

			var ev_pos = entity.get_global_mouse_position()
			if event.button_index == BUTTON_LEFT:
				entity.get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", entity, ev_pos, event)
			elif event.button_index == BUTTON_RIGHT:
				entity.get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "secondary_click", entity, ev_pos, event)
			_check_focus(true, true)
		else:
			clicked = false
#			_check_focus(true, false)

func _check_focus(focus, pressed):
	if entity.has_node("_focus_in"):
		if focus:
			entity.get_node("_focus_in").show()
		else:
			entity.get_node("_focus_in").hide()

	if entity.has_node("_pressed"):
		if pressed:
			entity.get_node("_pressed").show()
		else:
			entity.get_node("_pressed").hide()

func get_tooltip():
	# if `development_lang` matches `text_lang`, don't translate
	if TranslationServer.get_locale() == ProjectSettings.get_setting("escoria/platform/development_lang"):
		if not entity.global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("item", ["Missing global_id in item with tooltip '" + entity.tooltip + "'"])
		return entity.tooltip

	# Otherwise try to return the translated tooltip
	var tooltip_identifier = entity.global_id + ".tooltip"
	var translated = tr(tooltip_identifier)

	# But if translation isn't found, ensure it can be translated and return placeholder
	if translated == tooltip_identifier:
		if not entity.global_id and ProjectSettings.get_setting("escoria/platform/force_tooltip_global_id"):
			vm.report_errors("item", ["Missing global_id in item with tooltip '" + entity.tooltip + "'"])
		return tooltip_identifier

	return translated

func get_drag_data(point):
	printt("get drag data on point ", point, entity.inventory)
	if !entity.inventory:
		return null

	var c = Control.new()
	var it = duplicate()
	it.set_script(null)
	it.set_position(Vector2(-50, -80))
	c.add_child(it)
	c.show()
	it.show()
	#set_drag_preview(c)

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "background", "force_drag", entity.global_id, c)
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "interact", [self, "use"])

	vm.drag_begin(entity.global_id)
	printt("returning for drag data", entity.global_id)
	return entity.global_id

func can_drop_data(point, data):
	return true # always true ?

func drop_data(point, data):
	printt("dropping data ", data, entity.global_id)
	if data == entity.global_id:
		return

	if !entity.inventory:
		return

	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", self, entity.get_position())
	vm.drag_end()


func global_changed(name):
	var ev = "global_changed "+name
	if ev in event_table:
		run_event(event_table[ev])
	elif "global_changed" in event_table:
		run_event(event_table.global_changed)

func anim_get_ph_paths(p_anim):
	if !(p_anim in entity.placeholders):
		return null

	var ret = []
	for p in entity.placeholders[p_anim]:
		var n = entity.get_node(p)
		if !(n is InstancePlaceholder):
			continue
		ret.push_back(n.get_instance_path())
	return ret

func play_anim(p_anim, p_notify = null, p_reverse = false, p_flip = null):
	if p_notify == null and (!animation or !animation.has_animation(p_anim)):
		print("skipping cut scene '", p_anim, "'")
		vm.finished(p_notify)
		#_debug_states()
		return

	if p_anim in entity.placeholders:
		for npath in entity.placeholders[p_anim]:
			var node = entity.get_node(npath)
			if !node is InstancePlaceholder:
				continue
			var path = node.get_instance_path()
			var res = vm.res_cache.get_resource(path)
			node.replace_by_instance(res)
			_find_sprites(entity.get_node(npath))

	if p_flip != null && entity is Node2D:
		var s = entity.get_scale()
		entity.set_scale(s * p_flip)
		anim_scale_override = p_flip
	else:
		anim_scale_override = null

	if p_reverse:
		animation.play(p_anim, -1, -1, true)
	else:
		animation.play(p_anim)
	anim_notify = p_notify

	#_debug_states()


func set_speaking(p_speaking):
	printt("item set speaking! ", entity.global_id, p_speaking, state)
	#print_stack()
	if !animation:
		return
	if entity.talk_animation == "":
		return
	if p_speaking:
		if animation.has_animation(entity.talk_animation):
			animation.play(entity.talk_animation)
			animation.seek(0, true)
	else:
		set_state(state, true)
		if animations and "idles" in animations:
			pose_scale = animations.idles[last_dir + 1]
	_update_terrain()

func set_state(p_state, p_force = false):
	if state == p_state && !p_force:
		return

	# printt("set state ", "global_id: ", global_id, "state: ", state, "p_state: ", p_state, "p_force: ", p_force)

	state = p_state

	if animation != null:
		# Though calling `.play()` probably stops the animation, be safe.
		animation.stop()
		if animation.has_animation(p_state):
			animation.play(p_state)

func teleport(obj):
	entity.set_position(obj.global_position)
	moved = true
	_update_terrain(entity is Node2D)

func teleport_pos(x, y):
	entity.set_position(Vector2(x, y))
	moved = true
	_update_terrain(entity is Node2D)

func _update_terrain(need_z_update=false):
	if dynamic_z_index and need_z_update:
		entity.set_z_index(entity.get_position().y)

	if !scale_on_map && !light_on_map:
		return

	var pos = entity.get_position()
	# Items in the scene tree will issue errors unless this is conditional
	var terrain = $"../terrain" if entity.has_node("../terrain") else null
	if terrain == null:
		return

	var color = terrain.get_terrain(pos)
	var scale_range = terrain.get_scale_range(color.b)

	# The item's - as the player's - `animations` define the direction
	# as 1 or -1. This is stored as `pose_scale` and the easiest way
	# to flip a node is multiply its x-axis scale.
	scale_range.x *= pose_scale

	if entity is Node2D and entity.scale_on_map and scale_range != entity.get_scale():
		# Check if `interact_pos` is a child of ours, and if so,
		# take a backup of the global position, because it will be affected by scaling.
		var interact_global_position
		if entity.has_node("interact_pos"):
			interact_global_position = interact_pos.get_global_position()

		entity.scale = scale_range

		# If `interact_pos` is a child, it was affected by scaling, so reset it
		# to the expected location.
		if interact_global_position:
			interact_pos.global_position = interact_global_position

	if entity is CanvasItem and entity.light_on_map:
		var c = terrain.get_light(pos)
		entity.modulate(c)

func _check_bounds():
	#printt("checking bouds for pos ", get_position(), terrain.is_solid(get_position()))
	if !entity.scale_on_map:
		return
	if !Engine.is_editor_hint():
		return
	if terrain.is_solid(entity.get_position()):
		if entity.has_node("terrain_icon"):
			entity.get_node("terrain_icon").hide()
	else:
		if !entity.has_node("terrain_icon"):
			var node = Sprite.new()
			var tex = load("res://globals/terrain.png")
			node.set_texture(tex)
			entity.add_child(node)
			node.set_name("terrain_icon")
		entity.get_node("terrain_icon").show()

func _notification(what):
	if !is_inside_tree() || !Engine.is_editor_hint():
		return
	if what == Node2D.NOTIFICATION_TRANSFORM_CHANGED:
		_update_terrain()
		_check_bounds()

func hint_request():
	if !get_active():
		return
	if !vm.can_interact():
		return

	if ui_anim == null:
		return

	if ui_anim.is_playing():
		return

	ui_anim.play("hint")

func setup_ui_anim():
	if entity.has_node("ui_anims"):
		ui_anim = entity.get_node("ui_anims")

		for bg in get_tree().get_nodes_in_group("background"):
			bg.connect("right_click_on_bg", self, "hint_request")

	vm.connect("global_changed", self, "global_changed")


func body_entered(body):
	if body is esc_type.PLAYER:
		if entity.visible:
			var event = "enter"
			if event in event_table:
				vm.run_event(event_table[event])

func body_exited(body):
	if body is esc_type.PLAYER:
		if entity.visible:
			var event = "exit"
			if event in event_table:
				vm.run_event(event_table[event])

var events_path = ""
var interact_position
var dynamic_z_index = false
var scale_on_map = false
var light_on_map = false
enum ActivationType {Click = 0, Collision = 1}	

export(ActivationType) var activation_on = Click

func init():
	
	if not entity:
		entity = get_parent()
		return
	
	#Copy exported variables from entity
	if entity.get("global_id"):global_id = entity.global_id
	if entity.get("animations"):animations = entity.animations
	if entity.get("events_path"):events_path = entity.events_path
	if entity.get("interact_position"):interact_position = entity.interact_position
	if entity.get("dynamic_z_index"):dynamic_z_index = entity.dynamic_z_index
	if entity.get("scale_on_map"):scale_on_map = entity.scale_on_map
	if entity.get("light_on_map"):light_on_map = entity.light_on_map
	if entity.get("activation_on"):activation_on = entity.activation_on
	
	self_has_z_index = entity is Node2D
	if entity.has_node("../terrain"):
		terrain = entity.get_node("../terrain")

	# We find all the images of the entity so we can modulate them all
	_find_sprites(entity)

	if Engine.is_editor_hint():
		return
	if entity.has_node("animation"):
		animation = entity.get_node("animation")

	entity.add_to_group("item")

	if Engine.is_editor_hint():
		return

	var area
	if entity.has_node("area"):
		area = entity.get_node("area")
	else:
		area = entity

	if ClassDB.class_has_signal(area.get_class(), "input_event"):
		area.connect("input_event", self, "area_input")
	elif ClassDB.class_has_signal(area.get_class(), "gui_input"):
		area.connect("gui_input", self, "input")
	else:
		vm.report_warnings("item", ["No input events possible for global_id " + entity.global_id])

	if ClassDB.class_has_signal(area.get_class(), "mouse_entered"):
		area.connect("mouse_entered", self, "mouse_enter")
		area.connect("mouse_exited", self, "mouse_exit")

	if activation_on == Collision:
		area.connect("body_entered", self, "body_entered")
		area.connect("body_exited", self, "body_exited")

	if events_path != "":
		event_table = vm.compile(events_path)

	# Forbit pipe because it's used to separate flags from actions, like in `:use item | TK`. And space for good measure.
	for c in ["|", " "]:
		if c in entity.global_id:
			vm.report_errors("item", ["Forbidden character '" + c + "' in global_id: " + entity.global_id])

	vm.register_object(entity.global_id, self)

	if animation:
		animation.connect("animation_finished", self, "anim_finished")

	_check_focus(false, false)

	if interact_position:
		interact_pos = entity.get_node(entity.interact_position)
	elif entity.has_node("interact_pos"):
		interact_pos = $"interact_pos"

	# Initialize Node2D items' terrain status like z-index.
	# Stationary items will be set up correctly and
	# if an item moves, it will handle this in its _process() loop
	_update_terrain(entity is Node2D)