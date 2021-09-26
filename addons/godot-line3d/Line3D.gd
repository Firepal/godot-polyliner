tool
extends Path

enum Renderer {
	STATIC, # Use SurfaceTool for rendering
	IMMEDIATE # Use ImmediateGeoemtry
}

enum RenderMode {
	TRIANGLES,
	WIREFRAME
}

enum UVMode {
	# UV size never changes over curve length
	# Useful to keep UV in [0,1] range for float precision
	STRETCH,
	# UV scales with curve length
	# Good for applying repeated textures
	REPEAT
}

export(Renderer) var renderer = Renderer.STATIC setget set_renderer
export(RenderMode) var render_mode = RenderMode.TRIANGLES setget set_render_mode
export(UVMode) var uv_mode = UVMode.STRETCH setget set_uv_mode
export(float,0.0,100.0) var uv_size = 1.0 setget set_uv_size
export(Material) var material setget set_material

var _internal_render_mode = Mesh.PRIMITIVE_TRIANGLES

func set_renderer(value):
	renderer = value
	
	if _mesh_instance and _imm_geo:
		if Engine.editor_hint:
			_show_mesh_instance()
		else:
			match value:
				Renderer.STATIC: _show_mesh_instance()
				Renderer.IMMEDIATE: _show_imm_geo()
	redraw()

func _show_imm_geo():
	_mesh_instance.visible = false
	_imm_geo.visible = true
func _show_mesh_instance():
	_imm_geo.visible = false
	_mesh_instance.visible = true

func set_render_mode(value):
	render_mode = value
	if value == RenderMode.TRIANGLES:
		_internal_render_mode = Mesh.PRIMITIVE_TRIANGLES
	else:
		_internal_render_mode = Mesh.PRIMITIVE_LINE_STRIP
	redraw()

func set_uv_mode(value):
	uv_mode = value
	redraw()

func set_uv_size(value):
	uv_size = value
	redraw()

func set_material(mat):
	if mat == null:
		material = null
		return
	if mat is ShaderMaterial:
		material = mat
		if not mat.is_connected("changed",self,"_update_material"):
			mat.connect("changed",self,"_update_material")
		redraw()

var _mesh_instance = null
var _imm_sf = ImmediateSurface.new()
var _imm_geo : ImmediateGeometry = null

func _update_material():
	_mesh_instance.material_override = material
	_imm_geo.material_override = material

func _enter_tree():
	_mesh_instance = MeshInstance.new()
	add_child(_mesh_instance)
	
	_imm_geo = _imm_sf.get_immediate_geometry()
	add_child(_imm_geo)
	
	redraw()

var _sf = SurfaceTool.new()
func _draw():
	var p = curve.get_baked_points()
	var uvs = uv_size
	if uv_mode == UVMode.REPEAT: uvs *= curve.get_baked_length()
	
	var geo
	var renderer_is_static = renderer == Renderer.STATIC or Engine.editor_hint
	if renderer_is_static: 
		geo = _sf
	else: 
		geo = _imm_sf
		geo.clear()
	
	geo.begin(_internal_render_mode)
	
	var last = null
	var ps = p.size()-1
	for i in range(ps):
		var p1 = p[i]
		var p2 = p[i+1]
		
		var p1pc = p1.direction_to(p2)
		var p2pc = p1pc
		if last != null: p1pc = last
		
		var p1c = Color(p1pc.x,p1pc.y,p1pc.z)
		var p2c = Color(p2pc.x,p2pc.y,p2pc.z)
		
		var uv1 = (float(ps-i)/ps)*uvs
		var uv2 = (float(ps-(i+1))/ps)*uvs
		
		
		geo.add_color( p1c )
		geo.add_uv( Vector2(uv1,0.0) )
		geo.add_vertex( p1 )
		
		geo.add_color( p2c )
		geo.add_uv( Vector2(uv2,0.0) )
		geo.add_vertex( p2 )
		geo.add_uv( Vector2(uv2,1.0) )
		geo.add_vertex( p2 )
		
		
		geo.add_color( p1c )
		geo.add_uv( Vector2(uv1,1.0) )
		geo.add_vertex( p1 )
		geo.add_uv( Vector2(uv1,0.0) )
		geo.add_vertex( p1 )
		
		geo.add_color( p2c )
		geo.add_uv( Vector2(uv2,1.0) )
		geo.add_vertex( p2 )
		last = p2pc
	
	_update_material()
	if renderer_is_static:
		_mesh_instance.mesh = geo.commit(null,Mesh.ARRAY_COMPRESS_DEFAULT-Mesh.ARRAY_COMPRESS_COLOR)
	else:
		geo.end()

func redraw():
	call_deferred("_draw")


func _ready():
	if not is_connected("curve_changed",self,"redraw"):
		connect("curve_changed",self,"redraw")

