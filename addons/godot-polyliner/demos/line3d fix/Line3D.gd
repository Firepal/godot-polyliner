@tool
extends "res://addons/godot-polyliner/Line3D/Line3D.gd"


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (false) else DisplayServer.VSYNC_DISABLED)

func randpoint():
	var p = Vector3()
	p.x = randf_range(-1,1)
	p.y = randf_range(-1,1)
	p.z = randf_range(-1,1)
	return p

func vCub(a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float):
	var P = (d-c)-(a-b)
	return P*pow(t,3) + ((a-b)-P)*pow(t,2) + (c-a)*t + b;

var cur_p2 = Vector3()
var cur_p = Vector3()
var nxt_p = Vector3()
var cur_step = 0
const STEPS = 0
func _process(delta):
	if not Engine.editor_hint:
		cur_step -= 1
		
		if get_point_count() > 3:
			var last_p = get_point(get_point_count()-1)
			
			cur_p = lerp(cur_p,nxt_p,0.04)
		add_point(cur_p)
#			add_point(vCub(last_p3,last_p2,last_p,nxt_p,0.1))
		
		if cur_step < 0:
			cur_step = STEPS
			
			nxt_p = randpoint()*8
