extends RigidBody3D

@onready var joint = $Generic6DOFJoint3D
@onready var col_shape = $CollisionShape3D.shape

var rope = null
var id : int = 0
var resistance : float = 100

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE:
			var p = get_parent()
			rope = p
			rope.segments.append(self)
		NOTIFICATION_EXIT_TREE:
			if rope != null:
				rope.segments.erase(self)

func _get_sibling_joints():
	var siblings = []
	var last_sibling = self
	
	while (last_sibling.get_child_count() > 1):
		if not is_instance_valid(last_sibling.joint): break
		last_sibling = get_node(last_sibling.joint.get_node_b())
		if last_sibling == null: break
		siblings.push_back(last_sibling)
	
	return siblings


var broken = false
func _break_joint():
	var sibs = _get_sibling_joints()
	
	broken = true
	joint.queue_free()

var break_timer = 0.0
func _integrate_forces(state):
	var vel_sqr: float = state.linear_velocity.length_squared()
	
	if vel_sqr > resistance: break_timer += state.step
	else: break_timer = 0.0

	if break_timer > 0.5 and not broken and false:
		_break_joint()
	
