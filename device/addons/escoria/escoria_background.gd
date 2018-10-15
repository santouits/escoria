extends Sprite

export var tooltip = ""
export(String, FILE, ".esc") var events_path = ""
export var global_id = ""
export var use_combine = false
export var inventory = false
export var use_action_menu = true
export(int, -1, 360) var interact_angle = -1
export(NodePath) var interact_position = null
export(Color) var dialog_color = null
export var talk_animation = "talk"
export var active = true #setget logic.set_active,logic.get_active
export var placeholders = {}
export var dynamic_z_index = true
export var speed = 300
export var scale_on_map = false
export var light_on_map = false# setget set_light_on_map
export(Script) var animations
export var action = "walk"
var area

func input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if (event.button_index == BUTTON_LEFT):
			var pos = get_global_mouse_position()
			get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFAULT, "game", "clicked", self, pos, event)
		elif (event.button_index == BUTTON_RIGHT):
			emit_right_click()

func get_action():
	return action

func _init():
	add_user_signal("right_click_on_bg")

func _enter_tree():
	# Use size of background texture to calculate collision shape
	var size = get_texture().get_size()

	area = Area2D.new()
	var shape = RectangleShape2D.new()

	var sid = area.create_shape_owner(area)

	# Move origin of Area2D to center of Sprite
	var transform = area.shape_owner_get_transform(sid)
	transform.origin = size / 2
	area.shape_owner_set_transform(sid, transform)

	# Set extents of RectangleShape2D to cover entire Sprite
	shape.set_extents(size / 2)
	area.shape_owner_add_shape(sid, shape)

	add_child(area)

func _ready():
	area.connect("input_event", self, "input")
	add_to_group("background")

func emit_right_click():
	emit_signal("right_click_on_bg")
