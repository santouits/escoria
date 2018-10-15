tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("EscoriaTextureRect", "TextureRect", preload("escoria_texture_rect.gd"), preload("icon_godot_docs.svg"))
	add_custom_type("EscoriaBackground", "Sprite", preload("escoria_background.gd"),preload("icon_godot_docs.svg"))
	add_custom_type("EscoriaSprite", "Sprite", preload("escoria_sprite.gd"), preload("icon_godot_docs.svg"))
	add_custom_type("EscoriaNode2D", "Node2D", preload("escoria_node2d.gd"), preload("icon_godot_docs.svg"))
	add_custom_type("EscoriaArea2D", "Area2D", preload("escoria_area2d.gd"), preload("icon_godot_docs.svg"))
	add_custom_type("EscoriaControlTrigger", "Control", preload("escoria_control_trigger.gd"), preload("icon_godot_docs.svg"))
	add_custom_type("EscoriaTextureRectTrigger", "TextureRect", preload("escoria_texture_rect_trigger.gd"), preload("icon_godot_docs.svg"))

func _exit_tree():
	remove_custom_type("EscoriaTextureRect")
	remove_custom_type("EscoriaBackground")
	remove_custom_type("EscoriaSprite")
	remove_custom_type("EscoriaNode2D")
	remove_custom_type("EscoriaArea2D")
	remove_custom_type("EscoriaControlTrigger")
	remove_custom_type("EscoriaTextureRectTrigger")
