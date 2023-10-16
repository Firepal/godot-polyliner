@tool
extends Path3D

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

@export var renderer: Renderer = Renderer.STATIC : set = set_renderer
@export var render_mode: RenderMode = RenderMode.TRIANGLES : set = set_render_mode
@export var uv_mode: UVMode = UVMode.STRETCH : set = set_uv_mode
@export var uv_size = 1.0 : set = set_uv_size # (float,0.0,100.0)
@export var material: Material = null : set = set_material

var _internal_render_mode = Mesh.PRIMITIVE_TRIANGLES

var _linegen = LineGen3D.new()

func set_renderer(value):
	renderer = value
	
	if _mesh_instance:
		if Engine.is_editor_hint():
			_show_mesh_instance()
		else:
			match value:
				Renderer.STATIC: _show_mesh_instance()
	_rd()

func _show_imm_geo():
	push_warning("Immediate renderer is not implemented.")
	_mesh_instance.visible = false
func _show_mesh_instance():
	_mesh_instance.visible = true

func set_render_mode(value):
	render_mode = value
	if value == RenderMode.TRIANGLES:
		_linegen.render_mode = Mesh.PRIMITIVE_TRIANGLES
	else:
		_linegen.render_mode = Mesh.PRIMITIVE_LINE_STRIP
	_rd()

func set_uv_mode(value):
	uv_mode = value
	_rd()

func set_uv_size(value):
	uv_size = value
	_rd()

func set_material(mat):
	if mat == null:
		material = load("res://addons/godot-polyliner/default_line_material.tres").duplicate(true)
	if mat is ShaderMaterial:
		material = mat
		_rd()

var _mesh_instance = null
var _imm_sf = ImmediateSurface.new()

func _update_material():
	_mesh_instance.material_override = material
	
func _enter_tree():
	for child in get_children():
		child.queue_free()
	
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	
#	_imm_geo = _imm_sf.get_immediate_geometry()
#	add_child(_imm_geo)
	
	set_render_mode(render_mode)
	set_uv_mode(uv_mode)
	set_uv_size(uv_size)
	set_material(material)
	
	_rd()

func _draw():
	var points = Array(curve.get_baked_points())
	var length = uv_size * curve.get_baked_length()
	
#	var start = Time.get_ticks_usec()
	_mesh_instance.mesh = _linegen.draw_from_points_strip(points,length)
#	var end = Time.get_ticks_usec()
#	print( points.size(), " points, ", (end-start)*0.001, " ms" )
	
	_update_material()

func _rd():
	call_deferred("_draw")

func _ready():
	if not is_connected("curve_changed",Callable(self,"_rd")):
		connect("curve_changed",Callable(self,"_rd"))

