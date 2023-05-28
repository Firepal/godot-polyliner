@tool
extends MeshInstance3D

var _p = []

var capture : AudioEffectCapture
var linegen = LineGen3D.new()
func _ready():
	capture = AudioServer.get_bus_effect(0,0)
	linegen.render_mode = Mesh.PRIMITIVE_TRIANGLES
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if (false) else DisplayServer.VSYNC_DISABLED)

func _process(delta):
	if not Engine.editor_hint: _cap_do(delta)

const MAX_SAMPLES = 1000
func _cap_do(delta):
	var frames = capture.get_frames_available()*0.5
	var buf = capture.get_buffer(frames)
	if not buf.is_empty():
		var p = Vector3()
		for i in range( min(buf.size(),MAX_SAMPLES) ):
				var smpl = buf[i]
				var t = Vector3(smpl.x,smpl.y,0.0)*3.0
				t = t.rotated(Vector3.FORWARD,3.1415*0.75)
				p = t
				_p.push_front(t)
		$MeshInstance3D.global_transform = Transform3D(Basis(),p)
		_p.resize(MAX_SAMPLES)
		mesh = linegen.draw_from_points_strip(_p)
