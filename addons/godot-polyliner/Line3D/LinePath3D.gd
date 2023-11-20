@tool
extends Path3D

enum UVMode {
	# UV size never changes over curve length
	# Useful to keep UV in [0,1] range for float precision
	STRETCH,
	# UV scales with curve length
	# Good for applying repeated textures
	REPEAT
}

enum CurveSamplingMode {
	# Pretty fast, but has uneven parts
	BAKED,
	# Slow but hopefully more accurate to euclidean distance
	ITERATIVE
}

@export var curve_mode: CurveSamplingMode = CurveSamplingMode.BAKED : set = set_curve_mode
@export_range(0.0,4.0,0.001) var iter_min_dist = 0.1 : set = set_tess_dist

## When using the Iterative curve mode, includes the final point of the curve.
## The caveat is that the last point will have warped texture coordinates.
@export var iter_add_last_point = true : set = set_add_last_point
@export var uv_mode: UVMode = UVMode.STRETCH : set = set_uv_mode
@export var uv_size = 1.0 : set = set_uv_size # (float,0.0,100.0)
@export var material: Material = null : set = set_material

var _internal_render_mode = Mesh.PRIMITIVE_TRIANGLES

var _linegen = LineGen3D.new()

func _show_imm_geo():
	push_warning("Immediate renderer is not implemented.")
	_mesh_instance.visible = false
func _show_mesh_instance():
	_mesh_instance.visible = true

func set_uv_mode(value):
	uv_mode = value
	_rd()

func set_curve_mode(value):
	curve_mode = value
	_rd()

func set_add_last_point(value):
	iter_add_last_point = value
	_rd()

func set_uv_size(value):
	uv_size = value
	_rd()

func set_tess_dist(value):
	iter_min_dist = value
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
	
	set_uv_mode(uv_mode)
	set_uv_size(uv_size)
	set_material(material)
	
	_rd()

func _get_iterative_points():
	var points = []
	var expected_dist = iter_min_dist
	var allowed_error = expected_dist*0.01
	
	points.push_back(curve.get_point_position(0))
	var last_good_f = 0.0
	var last_good_f2 = null
	var test_f = 0.1
	var dist_error = 0.0
	var spins = 0
	var f_to_dist = 0.05
	while points.size() < 4096:
		if spins >= 500:
			print("too many spins")
			return points
		var p = curve.samplef(test_f)
		
		f_to_dist = 0.05
		
		dist_error = p.distance_to(points[-1]) - expected_dist
		if abs(dist_error) < allowed_error:
			
			points.push_back(p)
#			print("point!")
			if last_good_f != 0.0:
				last_good_f2 = last_good_f
			last_good_f = test_f
			
			if last_good_f2 != null:
				f_to_dist = last_good_f2 - last_good_f
			
			spins = 0
			
		else:
			var cur = curve.samplef(test_f)
			var last = curve.samplef(curve.point_count)
			
			if cur.distance_squared_to(last) < 1e-8:
				if iter_add_last_point:
					points.push_back(last)
				break
			spins += 1
		
#		print(f_to_dist)
		test_f = max(test_f-(dist_error * f_to_dist), last_good_f)
	
#	print(points.size(), " ", spins, " spins total")
	return points

func _draw():
	var stages = 8
	if curve.point_count > 4: stages = 5
	var points
	if curve_mode == CurveSamplingMode.BAKED:
		points = curve.get_baked_points()
	else:
		points = _get_iterative_points()
	
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

