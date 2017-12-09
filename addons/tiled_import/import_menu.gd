tool
extends EditorPlugin

var import_tab = preload("import_control.tscn").instance()

func _enter_tree():
	print("Tiled Import loaded")
	add_control_to_bottom_panel(import_tab, "Tiled Import")

func _exit_tree():
	print("Tiled Import destroyed")
	remove_control_from_bottom_panel(import_tab)