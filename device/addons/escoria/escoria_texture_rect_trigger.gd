extends TextureRect

export var global_id = ""
export(String, FILE, ".esc") var events_path = ""
export({Click = 0, Collision = 1}) var activation_on = 1
# Actions that are run if object's activation is set to collision
export var enter_action = "enter"
export var exit_action = ""
export var stopped_action = ""
export var tooltip = ""
export var action = ""
export(Script) var animations
export var speed = 300
export var scale_on_map = false
export var light_on_map = false# setget set_light_on_map
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