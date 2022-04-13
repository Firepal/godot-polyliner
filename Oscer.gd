tool
extends "res://addons/godot-line3d/Trail3D/Trail3D.gd"

var capture : AudioEffectCapture
func _ready():
	capture = AudioServer.get_bus_effect(0,0)

func _process(delta):
	var buf = capture.get_buffer(capture.get_frames_available()*0.5)
	if not buf.empty():
		for i in buf:
			var t = Transform()
			t.origin = Vector3(i.x,i.y,0.0).rotated(Vector3.FORWARD,3.1415*0.75)*4.0
			global_transform = t
			push_xform(t)
	else:
		push_xform()
#	capture.clear_buffer()
