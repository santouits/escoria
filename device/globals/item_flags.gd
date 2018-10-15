extends Object

#######################################################
# Variables you can add in the gdscript of every object
#######################################################

# Every object needs a global escoria id so the escoria scripts (.esc) can use it
export var global_id = ""

# The way you activate an action in the object's script
export({Click = 0, Collision = 1, None = 2}) var activation_on = 0

# The path of the escoria script of the object
export(String, FILE, ".esc") var events_path = ""

# The text showed when the mouse hovers over th object
export var tooltip = ""

# Every object can have a node that is the position the player goes to interact with it
export(NodePath) var interact_position = null

# If it is an inventory object
export var inventory = false

# Default action run when interacting with the object
export var action = ""

# Actions that are run if object's activation is set to collision
export var enter_action = ""
export var exit_action = ""
export var stopped_action = ""

export(Script) var animations
export var speed = 300
export var scale_on_map = false
export var light_on_map = false# setget set_light_on_map
export var use_combine = false
export var use_action_menu = true
export(int, -1, 360) var interact_angle = -1
export(Color) var dialog_color = null
export var talk_animation = "talk"
export var active = true #setget logic.set_active,logic.get_active
export var placeholders = {}
export var dynamic_z_index = true