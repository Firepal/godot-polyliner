extends RigidBody3D

class_name Rope3D

@export var end_segment: NodePath = ""
var end_segment_node : RigidBody3D = null 
@export var segment_count : int = 10 : set = _set_segment_count
@export var attached_to_end = true
@export var segment_mass : float = 20
@export var stiff_multiplier : float = 5
@export var damp : float = 0.5
var segments = []
var segments_broke = []
var segment_positions = []

@onready var joint : Generic6DOFJoint3D = null
@onready var col_shape = $CollisionShape3D.shape
@onready var line = $Line3D

func _set_end_segment(val):
	var node = get_node(val)
	if node != null and node is RigidBody3D:
		end_segment_node = node
		create_segments()
	end_segment = val

func _set_segment_count(val):
	segment_count = val
	segments.resize(segment_count)
	segment_positions.resize(segment_count+1)

func _ready():
	var new_joint = Generic6DOFJoint3D.new()
	add_child(new_joint)
	joint = new_joint
	_set_joint_params(joint)
	
	_set_end_segment(end_segment)
	_set_segment_count(segment_count)

func _set_joint_params(t_joint : Generic6DOFJoint3D):
	t_joint["linear_limit_x/enabled"] = false
	t_joint["linear_limit_y/enabled"] = false
	t_joint["linear_limit_z/enabled"] = false
	t_joint["angular_limit_x/enabled"] = false
	t_joint["angular_limit_y/enabled"] = false
	t_joint["angular_limit_z/enabled"] = false
	
	t_joint["linear_spring_x/enabled"] = true
	t_joint["linear_spring_y/enabled"] = true
	t_joint["linear_spring_z/enabled"] = true
	t_joint["angular_spring_x/enabled"] = true
	t_joint["angular_spring_y/enabled"] = true
	t_joint["angular_spring_z/enabled"] = true
	
	var stiffness = 600*stiff_multiplier
	t_joint["linear_spring_x/stiffness"] = stiffness
	t_joint["linear_spring_y/stiffness"] = stiffness
	t_joint["linear_spring_z/stiffness"] = stiffness
	t_joint["angular_spring_x/stiffness"] = 500
	t_joint["angular_spring_y/stiffness"] = 500
	t_joint["angular_spring_z/stiffness"] = 500
	
	var eq = 0.0
	t_joint["linear_spring_x/equilibrium_point"] = eq
	t_joint["linear_spring_y/equilibrium_point"] = eq
	t_joint["linear_spring_z/equilibrium_point"] = eq
	
	var dampy = damp*50
	t_joint["linear_spring_x/damping"] = dampy
	t_joint["linear_spring_y/damping"] = dampy
	t_joint["linear_spring_z/damping"] = dampy

func _draw_line():
#	segment_positions[0] = global_transform.inverse() * global_transform.origin
	
	for i in range(segments.size()):
		var p = segments[i].global_transform.translated(Vector3.LEFT*0.5).origin
		segment_positions[i] = global_transform.inverse() * p
	
	segment_positions[segment_positions.size()-1] = global_transform.inverse() * end_segment_node.global_transform.origin
	
	line.points = PackedVector3Array(segment_positions)

func _process(delta):
	if segments.size() > 0: _draw_line()

func connect_to_other_segment(this_segment,other_segment):
	var this_joint : Generic6DOFJoint3D = this_segment.joint
	this_joint.set_node_a( this_segment.get_path() )
	this_joint.set_node_b( other_segment.get_path() )
	
	_set_joint_params(this_joint)

func _handle_breakage():
	pass

@onready var rope_seg_template = preload("res://addons/godot-polyliner/demos/ropetesting/RopeSegment3D.tscn")

func create_segments():
	var start_pos = global_transform.origin
	var end_pos = end_segment_node.global_transform.origin
	
	var inv_ps = 1.0/(segment_count+1)
	
	for i in range(segment_count):
		
		var new_segment = rope_seg_template.instantiate()
		new_segment.id = i
		new_segment.mass = segment_mass
		add_child(new_segment)
		new_segment.set_as_top_level(true)
		
		var t = inv_ps*(i+1)
		var pos = start_pos.lerp(end_pos,(t*0.9))
		new_segment.position = pos
		
		var last_segment = self
		if i >= 1: last_segment = segments[i-1]
		segments[i] = new_segment
		
		var dist = last_segment.global_transform.origin.distance_to(new_segment.global_transform.origin)
#		new_segment.col_shape["radius"] = min(dist,0.1)
		new_segment.col_shape["height"] = dist*0.8
		
		connect_to_other_segment(last_segment,new_segment)
	
	if attached_to_end:
		connect_to_other_segment(segments[segment_count-1],end_segment_node)
	segments_broke = segments.duplicate()
