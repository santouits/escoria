# Create a file like this in your game to define right-mouse-button
# behavior.

extends Node

func _ready():
	for item in get_tree().get_nodes_in_group("item"):
		var component = item.get_meta("component")
		if component:
			component.setup_ui_anim()
		# printt("set up item ", item.global_id, item.tooltip, item.name)

