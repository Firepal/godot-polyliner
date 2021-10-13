tool
extends EditorPlugin

# TODO: Use add_control_to_container to allow Editor export of line meshes.

func _enter_tree():
	add_custom_type("Line3D","Path",preload("Line3D/Line3D.gd"),preload("Line3D/icon.png"))
	make_visible(false)


func _exit_tree():
	remove_custom_type("Line3D")
