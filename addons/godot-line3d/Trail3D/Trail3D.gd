tool
extends Spatial

# TODO: this
enum ProcessMode {
	Idle,
	Physics
}


var _linegen = LineGen3D.new()
var _mesh_instance = MeshInstance.new()

func _ready():
	_linegen.render_mode = Mesh.PRIMITIVE_TRIANGLES

func _enter_tree():
	add_child(_mesh_instance)

func _exit_tree():
	remove_child(_mesh_instance)

var points = []
export(int,0,1000) var max_points = 10
export(int,0,8) var extra_points = 0
export(float,0.0,1.0) var damping = 0.0
export var render_as_line = false
export(Material) var material setget set_material

var damped_transform = global_transform
var last = null

func _interpolate_sample(current : Transform):
	if last != null and extra_points != 0.0:
			var ep = extra_points
			var rcp = 1.0/(ep+1)
			for i in range(extra_points):
				var interp_factor = float(ep-i)*rcp
	#			var t = current
	#			t.origin = current.origin.linear_interpolate(last.origin,interp_factor)
				var t = current.interpolate_with(last,interp_factor)
				points.push_front(t)
	
	last = current

func _process(delta):
	_mesh_instance.global_transform = Transform()
	
	if is_zero_approx(damping): damped_transform = global_transform
	else: damped_transform = global_transform.interpolate_with(damped_transform,damping)
	
	_interpolate_sample(damped_transform)
	points.push_front(damped_transform)
	points.resize(max_points*(extra_points+1)+1)
	
	if render_as_line:
		_mesh_instance.mesh = _linegen.draw_from_xform_points(points)
	else:
		_mesh_instance.mesh = _linegen.draw_from_xforms(points)

func set_material(mat):
	material = mat
	_mesh_instance.material_override = mat
