tool
extends Resource

class_name LineGen3D

enum UVMode {
	# UV size never changes over curve length
	# Useful to keep UV in [0,1] range for float precision
	STRETCH,
	# UV scales with curve length
	# Good for applying repeated textures
	REPEAT
}

var immediate_canvas : ImmediateGeometry = null

var render_mode = Mesh.PRIMITIVE_LINE_STRIP
var uv_mode = UVMode.STRETCH
var uv_scale = 1.0

var _sf = SurfaceTool.new()
var _is = ImmediateSurface.new()

func draw_from_xforms(p : Array = [], total_length : float = 1.0):
	if p.empty(): return
	var uvs = total_length
	
	_sf.begin(render_mode)
	
	var last = null
	var ps = p.size()-1
	for i in range(ps):
		var p1 = p[i]
		var p2 = p[i+1]
		
		# null has no satisfying replacement
		# so we immediately create the mesh
		if p2 == null:
			return _sf.commit()
		
		var uv1 = ((float(ps-i)/ps)*uvs)
		var uv2 = ((float(ps-(i+1))/ps)*uvs)
		
		_sf.add_normal( -p1.basis.y )
		_sf.add_uv( Vector2(uv1,0.0) )
		_sf.add_vertex( p1*Vector3(-1,0,0) )
		
		_sf.add_normal( -p2.basis.y )
		_sf.add_uv( Vector2(uv2,0.0) )
		_sf.add_vertex( p2*Vector3(-1,0,0) )
		
		_sf.add_normal( -p2.basis.y )
		_sf.add_uv( Vector2(uv2,1.0) )
		_sf.add_vertex( p2*Vector3(1,0,0) )
		
		
		_sf.add_normal( -p1.basis.y )
		_sf.add_uv( Vector2(uv1,1.0) )
		_sf.add_vertex( p1*Vector3(1,0,0) )
		
		_sf.add_normal( -p1.basis.y )
		_sf.add_uv( Vector2(uv1,0.0) )
		_sf.add_vertex( p1*Vector3(-1,0,0) )
		
		_sf.add_normal( -p2.basis.y )
		_sf.add_uv( Vector2(uv2,1.0) )
		_sf.add_vertex( p2*Vector3(1,0,0) )
	
	return _sf.commit()

func draw_from_xform_points(p : Array = [], total_length : float = 1.0):
	if p.empty(): return
	var uvs = total_length
	
	_sf.begin(render_mode)
	
	var last = null
	var ps = p.size()-1
	for i in range(ps):
		var p1 = p[i]
		var p2 = p[i+1]
		if p2 == null:
			return _sf.commit()
		p1 = p1.origin
		p2 = p2.origin
		
		var p1pc = p1.direction_to(p2)
		var p2pc = p1pc
		if last != null: p1pc = last
		
		var p1c = Color(p1pc.x,p1pc.y,p1pc.z)
		var p2c = Color(p2pc.x,p2pc.y,p2pc.z)
		
		var uv1 = (float(ps-i)/ps)*uvs
		var uv2 = (float(ps-(i+1))/ps)*uvs
		
		
		_sf.add_color( p1c )
		_sf.add_uv( Vector2(uv1,0.0) )
		_sf.add_vertex( p1 )
		
		_sf.add_color( p2c )
		_sf.add_uv( Vector2(uv2,0.0) )
		_sf.add_vertex( p2 )
		_sf.add_uv( Vector2(uv2,1.0) )
		_sf.add_vertex( p2 )
		
		
		_sf.add_color( p1c )
		_sf.add_uv( Vector2(uv1,1.0) )
		_sf.add_vertex( p1 )
		_sf.add_uv( Vector2(uv1,0.0) )
		_sf.add_vertex( p1 )
		
		_sf.add_color( p2c )
		_sf.add_uv( Vector2(uv2,1.0) )
		_sf.add_vertex( p2 )
		
		last = p2pc
	
	return _sf.commit(null,Mesh.ARRAY_COMPRESS_DEFAULT-Mesh.ARRAY_COMPRESS_COLOR)

func draw_from_points(p : PoolVector3Array = PoolVector3Array(), total_length : float = 1.0):
	if p.empty():
#		push_warning("p is empty, mesh will not be updated")
		return
	assert(p is PoolVector3Array, "p must be PoolVector3Array")
	var uvs = total_length
	
	_sf.begin(render_mode)
	
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
		
		_sf.add_color( p1c )
		_sf.add_uv( Vector2(uv1,1.0) )
		_sf.add_vertex( p1 )
		_sf.add_uv( Vector2(uv1,0.0) )
		_sf.add_vertex( p1 )
		
		_sf.add_color( p2c )
		_sf.add_uv( Vector2(uv2,1.0) )
		_sf.add_vertex( p2 )
		
		
		_sf.add_color( p1c )
		_sf.add_uv( Vector2(uv1,0.0) )
		_sf.add_vertex( p1 )
		
		_sf.add_color( p2c )
		_sf.add_uv( Vector2(uv2,0.0) )
		_sf.add_vertex( p2 )
		_sf.add_uv( Vector2(uv2,1.0) )
		_sf.add_vertex( p2 )
		
		last = p2pc
	
	return _sf.commit(null,Mesh.ARRAY_COMPRESS_DEFAULT-Mesh.ARRAY_COMPRESS_COLOR)
