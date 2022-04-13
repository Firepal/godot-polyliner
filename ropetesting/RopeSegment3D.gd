extends RigidBody

onready var joint = $Generic6DOFJoint
onready var col_shape = $CollisionShape.shape

var rope = null
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

var broken = false
func _break_joint():
	joint.queue_free()
	broken = true

var break_timer = 0.0
func _integrate_forces(state):
	var vel_sqr: float = state.linear_velocity.length_squared()
	
	if vel_sqr > resistance: break_timer += state.step
	else: break_timer = 0.0

	if break_timer > 0.17 and not broken:
		_break_joint()
	
