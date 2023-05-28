class_name ImmediateSurface

# Interface for using SurfaceTool calls with ImmediateMesh

# Should not be changed
var _ig : ImmediateMesh = ImmediateMesh.new() : get = get_immediate_geometry


func get_immediate_geometry():
	return _ig

func begin(mode):
	_ig.begin(mode)
	
func end():
	_ig.end()
	
func clear():
	_ig.clear()

func add_vertex(vertex : Vector3):
	_ig.add_vertex( vertex )

func add_uv(uv : Vector2):
	_ig.set_uv( uv )

func add_color(color : Color):
	_ig.set_color( color )

var material_override : Material = null : set = set_material_override

func set_material_override(value):
	material_override = value
	_ig.material_override = value
