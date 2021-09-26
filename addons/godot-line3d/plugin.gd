tool
extends EditorPlugin

var l = MenuButton.new()
func _enter_tree():
	l.text = "yese"
#	var p = l.get_popup()
#	p.add_item("yes")
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,l)
	add_custom_type("Line3D","Path",preload("Line3D.gd"),preload("icon.png"))
#	make_visible(false)

func make_visible(visible):
	if l:
		l.visible = visible

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,l)
	remove_custom_type("Line3D")
