tool
extends Spatial

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

export(RenderMode) var render_mode = RenderMode.TRIANGLES setget set_render_mode
export(UVMode) var uv_mode = UVMode.STRETCH setget set_uv_mode
export(float,0.0,100.0) var uv_size = 1.0 setget set_uv_size
export(Material) var material setget set_material

var _internal_render_mode = Mesh.PRIMITIVE_TRIANGLES

var _linegen = LineGen3D.new()

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
		var default_mat : ShaderMaterial = load("res://addons/godot-line3d/Line3D/default_line_material.tres").duplicate(true)
		material = default_mat
	if mat is ShaderMaterial:
		material = mat
		if not mat.is_connected("changed",self,"_update_material"):
			mat.connect("changed",self,"_update_material")
	_update_material()

var _mesh_instance = MeshInstance.new()

func _update_material():
	_mesh_instance.material_override = material
	
func _enter_tree():
	add_child(_mesh_instance)
	
	set_render_mode(render_mode)
	set_uv_mode(uv_mode)
	set_uv_size(uv_size)
	
	redraw()

export var points = PoolVector3Array() setget set_points

func set_points(val):
	points = val
	redraw()

func add_point(point : Vector3):
	points.push_back(point)

func clear_points():
	points.clear()

func get_point_count() -> int:
	return points.size()

func get_point_position(i : int) -> Vector2:
	return points[i]

func remove_point(i : int):
	points.remove(i)

func set_point_position(i : int):
	points.remove(i)

func _draw():
	var length = uv_size
	
	print()
	var start = OS.get_ticks_usec()
	_mesh_instance.mesh = _linegen.draw_from_points_strip(points)
	var end = OS.get_ticks_usec()
	print( points.size(), " points, ", (end-start)*0.001, " ms" )
	
	_update_material()

func redraw():
	call_deferred("_draw")

func _ready():
	if not is_connected("curve_changed",self,"redraw"):
		connect("curve_changed",self,"redraw")

