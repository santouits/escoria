tool extends Node2D

onready var component = preload("res://globals/component.gd").new()

export({Click = 0, Collision = 1}) var activation_on = 0
export(Script) var animations
export var speed = 300
export var scale_on_map = false
export var light_on_map = false# setget set_light_on_map
export var tooltip = ""
export var action = ""
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




func _ready():
	pass
#	add_child(component)
#	component.init()

