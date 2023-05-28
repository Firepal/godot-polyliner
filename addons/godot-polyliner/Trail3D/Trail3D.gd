@tool
extends Node3D

enum SamplingMode {
	Process,
	PhysicsProcess,
	None
}

enum TangentAxis {
	X,
	Y,
	Z
}

var _linegen = LineGen3D.new()
var _mesh_instance = MeshInstance3D.new()

var points = []

@export var sampling_mode: SamplingMode = SamplingMode.Process : set = set_sampling_mode
@export var max_points = 10 : set = set_max_points # (int,0,1000)
@export var damping = 0.5 # (float,0.0,1.0,0.002)
@export var tangent_axis: TangentAxis = TangentAxis.X
@export var skip_frames = 0 # (int,0,20)
@export var interpolate_skip: bool = false : set = set_interpolate_skip

@export var material: ShaderMaterial = null : set = _set_material


var damped_transform = Transform3D()

func _ready():
	damped_transform = global_transform
	_mesh_instance.set_as_top_level(true)
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
	if sampling_mode == SamplingMode.None and mode != SamplingMode.None:
		damped_transform = global_transform
	sampling_mode = mode
	set_physics_process(mode == SamplingMode.PhysicsProcess)

func set_interpolate_skip(val):
	interpolate_skip = val
	if interpolate_skip:
		_mesh_instance.transform = Transform3D.IDENTITY

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

func _skipped_frames(frames):
	return fmod(frames,max(skip_frames+1,1)) < 0.001

var _mesh_xform : Transform3D = Transform3D.IDENTITY
func _process(delta):
	
	if _skipped_frames(Engine.get_process_frames()):
		_mesh_xform = global_transform
		if sampling_mode == SamplingMode.Process:
			push_xform(global_transform)
		elif sampling_mode == SamplingMode.None:
			push_xform(null)
		
		_redraw()
	
	if not interpolate_skip:
		_mesh_instance.global_transform = _mesh_xform
	
#		_debug_spheres()

func _physics_process(delta):
	if _skipped_frames(Engine.get_physics_frames()):
		push_xform(global_transform)

# For testing correspondance between
# trail mesh and points
func _debug_spheres():
	var s = Node3D.new()
	if _mesh_instance.get_children().is_empty():
		_mesh_instance.add_child(s)
	else:
		s = _mesh_instance.get_child(0)
		for i in s.get_children():
			i.queue_free()
		var sphere = MeshInstance3D.new()
		var smesh = SphereMesh.new()
		smesh.radius = 0.01
		smesh.height = 0.02
		sphere.mesh = smesh
		for i in points:
			if i != null:
				var sphere_inst = sphere.duplicate()
				sphere_inst.transform = i
				s.add_child(sphere_inst)
