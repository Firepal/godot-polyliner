tool
extends Path

enum Renderer {
	STATIC, # Use SurfaceTool for rendering
	######################  IMMEDIATE IS UNIMPLEMENTED IN LineGen3D
	IMMEDIATE # Use ImmediateGeoemtry
}

enum RenderMode {
	TRIANGLES,
	WIREFRAME
}

enum UVMode {
	# UV size never changes over curve length
	# Useful to keep UV in [0,1] range for float precision
	STRETCH,
	# UV scales with curve length
	# Good for applying repeated textures
	REPEAT
}

export(Renderer) var renderer = Renderer.STATIC setget set_renderer
export(RenderMode) var render_mode = RenderMode.TRIANGLES setget set_render_mode
export(UVMode) var uv_mode = UVMode.STRETCH setget set_uv_mode
export(float,0.0,100.0) var uv_size = 1.0 setget set_uv_size
export(Material) var material = null setget set_material

var _internal_render_mode = Mesh.PRIMITIVE_TRIANGLES

var _linegen = LineGen3D.new()

func set_renderer(value):
	renderer = value
	
	if _mesh_instance and _imm_geo:
		if Engine.editor_hint:
			_show_mesh_instance()
		else:
			match value:
				Renderer.STATIC: _show_mesh_instance()
				Renderer.IMMEDIATE: _show_imm_geo()
	redraw()

func _show_imm_geo():
	push_warning("Immediate renderer is not implemented.")
	_mesh_instance.visible = false
	_imm_geo.visible = true
func _show_mesh_instance():
	_imm_geo.visible = false
	_mesh_instance.visible = true

func set_render_mode(value):
	render_mode = value
	if value == RenderMode.TRIANGLES:
		_linegen.render_mode = Mesh.PRIMITIVE_TRIANGLES
	else:
		_linegen.render_mode = Mesh.PRIMITIVE_LINE_STRIP
	redraw()

func set_uv_mode(value):
	uv_mode = value
	redraw()

func set_uv_size(value):
	uv_size = value
	redraw()

func set_material(mat):
	if mat == null:
		material = load("res://addons/godot-polyliner/default_line_material.tres").duplicate(true)
	if mat is ShaderMaterial:
		material = mat
		redraw()

var _mesh_instance = null
var _imm_sf = ImmediateSurface.new()
var _imm_geo : ImmediateGeometry = null

func _update_material():
	_mesh_instance.material_override = material
	_imm_geo.material_override = material
	
func _enter_tree():
	for child in get_children():
		child.queue_free()
	
	_mesh_instance = MeshInstance.new()
	add_child(_mesh_instance)
	
	_imm_geo = _imm_sf.get_immediate_geometry()
	add_child(_imm_geo)
	
	set_render_mode(render_mode)
	set_uv_mode(uv_mode)
	set_uv_size(uv_size)
	set_material(material)
	
	redraw()

func _draw():
	var points = Array(curve.get_baked_points())
	var length = uv_size * curve.get_baked_length()
	
#	var start = OS.get_ticks_usec()
	_mesh_instance.mesh = _linegen.draw_from_points_strip(points,length)
#	var end = OS.get_ticks_usec()
#	print( points.size(), " points, ", (end-start)*0.001, " ms" )
	
	_update_material()

func redraw():
	call_deferred("_draw")

func _ready():
	if not is_connected("curve_changed",self,"redraw"):
		connect("curve_changed",self,"redraw")

