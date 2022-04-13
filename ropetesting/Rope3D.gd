extends RigidBody

class_name Rope3D

export(NodePath) var end_segment = ""
var end_segment_node : RigidBody = null 
export var segment_count : int = 10 setget _set_segment_count
var segments = []
var segment_positions = []

onready var joint : Generic6DOFJoint = null
onready var col_shape = $CollisionShape.shape

func _set_end_segment(val):
	var node = get_node(val)
	if node != null and node is RigidBody:
		end_segment_node = node
		create_segments()
	end_segment = val

func _set_segment_count(val):
	segment_count = val
	segments.resize(segment_count)
	segment_positions.resize(segment_count+2)

func _ready():
	var new_joint = Generic6DOFJoint.new()
	add_child(new_joint)
	joint = new_joint
	_set_joint_params(joint)
	
	_set_end_segment(end_segment)
	_set_segment_count(segment_count)

func _set_joint_params(t_joint : Generic6DOFJoint):
	t_joint["linear_limit_x/enabled"] = false
	t_joint["linear_limit_y/enabled"] = false
	t_joint["linear_limit_z/enabled"] = false
	t_joint["angular_limit_x/enabled"] = false
	t_joint["angular_limit_y/enabled"] = false
	t_joint["angular_limit_z/enabled"] = false
	
	t_joint["linear_spring_x/enabled"] = true
	t_joint["linear_spring_y/enabled"] = true
	t_joint["linear_spring_z/enabled"] = true
	
	var stiffness = 40*segment_count
	t_joint["linear_spring_x/stiffness"] = stiffness
	t_joint["linear_spring_y/stiffness"] = stiffness
	t_joint["linear_spring_z/stiffness"] = stiffness
	
	var eq = 0.0
	t_joint["linear_spring_x/equilibrium_point"] = eq
	t_joint["linear_spring_y/equilibrium_point"] = eq
	t_joint["linear_spring_z/equilibrium_point"] = eq
	
	var damp = segment_count*0.4
	t_joint["linear_spring_x/damping"] = damp
	t_joint["linear_spring_y/damping"] = damp
	t_joint["linear_spring_z/damping"] = damp

var line_renderer = LineGen3D.new()
func _draw_line():
	if segment_positions.size() > 0:
		var inv = global_transform.inverse()
		segment_positions[0] = inv * global_transform.origin
		for i in range(segment_count):
			segment_positions[i+1] = inv * segments[i].translation
		segment_positions[segment_count+1] = inv * end_segment_node.global_transform.origin
		$MeshInstance.mesh = line_renderer.draw_from_points_indexed(segment_positions)

func _process(delta):
	if segments.size() > 0: _draw_line()

func connect_to_other_segment(this_segment,other_segment):
	var this_joint : Generic6DOFJoint = this_segment.joint
	this_joint.set_node_a( this_segment.get_path() )
	this_joint.set_node_b( other_segment.get_path() )
	
	_set_joint_params(this_joint)

onready var rope_seg_template = preload("res://ropetesting/RopeSegment3D.tscn")

func create_segments():
	var start_pos = global_transform.origin
	var end_pos = end_segment_node.global_transform.origin
	
	var inv_ps = 1.0/(segment_count+1)
	
	for i in range(segment_count):
		var t = inv_ps*(i+1)
		var pos = start_pos.linear_interpolate(end_pos,t)
		
		var new_segment = rope_seg_template.instance()
		add_child(new_segment)
		new_segment.set_as_toplevel(true)
		new_segment.translation = pos
		
		var last_segment = self
		if i >= 1: last_segment = segments[i-1]
		segments[i] = new_segment
		
		var dist = last_segment.global_transform.origin.distance_to(new_segment.global_transform.origin)
#		new_segment.col_shape["radius"] = min(dist,0.1)
		new_segment.col_shape["height"] = dist*0.9
		
		connect_to_other_segment(last_segment,new_segment)
	
	connect_to_other_segment(segments[segment_count-1],end_segment_node)
