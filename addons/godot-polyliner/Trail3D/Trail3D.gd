tool
extends Spatial

enum SamplingMode {
	Idle,
	Physics,
	None
}

enum TangentAxis {
	X,
	Y,
	Z
}

var _linegen = LineGen3D.new()
var _mesh_instance = MeshInstance.new()

var points = []

export(SamplingMode) var sampling_mode = SamplingMode.Idle setget set_sampling_mode
export(int,0,1000) var max_points = 10 setget set_max_points
export(float,0.0,1.0,0.002) var damping = 0.5
export(TangentAxis) var tangent_axis = TangentAxis.X
export(int,0,20) var skip_frames = 0
export(bool) var interpolate_skip = false setget set_interpolate_skip

export(ShaderMaterial) var material = null setget _set_material


var damped_transform = Transform()

func _ready():
	damped_transform = global_transform
	_mesh_instance.set_as_toplevel(true)
	set_sampling_mode(sampling_mode)
	set_max_points(max_points)
	_set_material(material)
	_linegen.render_mode = Mesh.PRIMITIVE_TRIANGLES

func _enter_tree():
	add_child(_mesh_instance)

func _exit_tree():
	remove_child(_mesh_instance)

func _set_material(mat):
	if mat == null:
		material = load("res://addons/godot-polyliner/default_line_material.tres").duplicate(true)
	if mat is ShaderMaterial:
		material = mat
	_mesh_instance.material_override = material

func set_sampling_mode(mode):
	sampling_mode = mode
	set_physics_process(mode == SamplingMode.Physics)

func set_interpolate_skip(val):
	interpolate_skip = val
	if interpolate_skip:
		_mesh_instance.transform = Transform.IDENTITY

func set_max_points(val):
	val = max(val,2)
	var diff = val - max_points
	var old_size = max_points
	max_points = val
	
	points.resize(val)
	if diff == 0: return
	print(diff)
	if diff > 0:
		refill_points(old_size-1)

func refill_points(fill_index : int = 0):
	for i in range(fill_index,points.size()):
		points[i] = points[fill_index]

func _shift_points_forward():
	var s = points.size()-1
	for i in range(s):
		points[s-i] = points[s-(i+1)]

func push_xform(xform = null):
	_shift_points_forward()
	if xform == null:
		points[0] = null
		return
	if is_zero_approx(damping): damped_transform = xform
	else: damped_transform = xform.interpolate_with(damped_transform,damping)
	points[0] = damped_transform

func _redraw():
	if visible:
		_mesh_instance.mesh = _linegen.draw_from_xforms_strip(points,global_transform.inverse(),tangent_axis)

var _mesh_xform : Transform = Transform.IDENTITY
func _process(delta):
	
	if fmod(Engine.get_idle_frames(),max(skip_frames+1,1)) < 0.001:
		_mesh_xform = global_transform
		if sampling_mode == SamplingMode.Idle:
			push_xform(global_transform)
		elif sampling_mode == SamplingMode.None:
			push_xform(null)
		
		_redraw()
	
	if not interpolate_skip:
		_mesh_instance.global_transform = _mesh_xform
	
#		_debug_spheres()

func _physics_process(delta):
	if fmod(Engine.get_physics_frames(), max(skip_frames+1,1)) < 0.001:
		push_xform(global_transform)

# For testing correspondance between
# trail mesh and points
func _debug_spheres():
	var s = Spatial.new()
	if _mesh_instance.get_children().empty():
		_mesh_instance.add_child(s)
	else:
		s = _mesh_instance.get_child(0)
		for i in s.get_children():
			i.queue_free()
		var sphere = MeshInstance.new()
		var smesh = SphereMesh.new()
		smesh.radius = 0.01
		smesh.height = 0.02
		sphere.mesh = smesh
		for i in points:
			if i != null:
				var sphere_inst = sphere.duplicate()
				sphere_inst.transform = i
				s.add_child(sphere_inst)
