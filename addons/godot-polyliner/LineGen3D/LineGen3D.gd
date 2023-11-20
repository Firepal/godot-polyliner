@tool
extends Resource

class_name LineGen3D

var immediate_canvas : ImmediateMesh = null

var render_mode = Mesh.PRIMITIVE_TRIANGLES
var uv_scale = 1.0

var _sf = SurfaceTool.new()
var _is = ImmediateSurface.new()

# Draws a line from an array of Transforms or null values.
# p = array of Transforms
# inv_origin_xform = the inverse of the Trail3D node's transform
# it is used to keep vertex float values near 0.0
func draw_from_xforms_strip(p : Array = Array(),
					inv_origin_xform : Transform3D = Transform3D(),
					tangent_axis : int = 0) -> ArrayMesh:
	_sf.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	tangent_axis = tangent_axis % 3
	
	var last = Vector3(1,0,0)
	
	var ps = p.size()
	if ps <= 1: return ArrayMesh.new()
	
	var inv_ps = 1.0/(ps-1)
	
	for i in range(ps+2):
		var real_i = i
		if i > 0: i -= 1
		if i > ps-1: i -= 1
		var p1 = p[i]
		
		if p1 != null:
			p1 = inv_origin_xform*p[i]
			if i < ps-1 and p[i+1] != null:
				last = (inv_origin_xform*p[i+1].origin) - p1.origin
			if i < ps-3 and p[i+2] != null:
				last = (inv_origin_xform*p[i+2].origin) - p1.origin
			
			var tan_vector = p1.basis[tangent_axis]
			var p1_tangent = Plane(tan_vector,0.0)
			
			# TODO: calculate total_length
			var uv1x = 1.0-(inv_ps*(real_i-1))
			var extras_uv2 = Vector2(1.0, inv_ps)
			
			_sf.set_tangent( p1_tangent )
			_sf.set_normal( last )
			
			_sf.set_uv( Vector2(uv1x,1.0) )
			_sf.set_uv2( extras_uv2 )
			_sf.add_vertex( p1.origin )
			
			_sf.set_tangent( p1_tangent )
			_sf.set_normal( last )
			
			_sf.set_uv( Vector2(uv1x,0.0) )
			_sf.set_uv2( extras_uv2 )
			_sf.add_vertex( p1.origin )
			
	
	return _sf.commit(null,
		Mesh.ARRAY_FORMAT_VERTEX+
		Mesh.ARRAY_FORMAT_NORMAL+
		Mesh.ARRAY_FORMAT_COLOR+
		Mesh.ARRAY_FORMAT_TEX_UV+
		Mesh.ARRAY_FORMAT_TEX_UV2
	)

func draw_from_xforms_indexed(p : Array = Array(),
					inv_origin_xform : Transform3D = Transform3D()) -> ArrayMesh:
	_sf.begin(render_mode)
	
	var last = null
	
	var point_i = 0
	var verts = 0
	
	var ps = p.size()
	if ps <= 1: return ArrayMesh.new()
	
	var inv_ps = 1.0/(ps-1)
	
	for i in range(ps):
		var within_bound = i < ps-1
		var p1 = null
		var p_next = null
		if within_bound:
			if p[i] != null:
				p1 = inv_origin_xform*p[i]
			if i < ps-1 and p[i+1] != null:
				last = (inv_origin_xform*p[i+1]) - p1
			if i < ps-3 and p[i+2] != null:
				last = (inv_origin_xform*p[i+2]) - p1
		
			
			if within_bound and last != null:
#				within_bound = within_bound and p2 != null
				
				var p1c = Color(last.x,last.y,last.z)
				
				# TODO: calculate total_length
				var uv2 = 1.0-(inv_ps*i)
				var uv1 = uv2
				
				point_i += 1
				point_i += verts
				
				_sf.add_color( p1c )
				_sf.set_normal( p1.basis.x )
				
				_sf.set_uv( Vector2(uv1,1.0) )
				_sf.set_uv2( Vector2(uv2,1.0) )
				_sf.add_vertex( p1.origin )
				
				_sf.set_uv( Vector2(uv1,0.0) )
				_sf.set_uv2( Vector2(uv2,0.0) )
				_sf.add_vertex( p1.origin )
				
				if p[i+1] != null:
					_sf.add_index(i)
					_sf.add_index(i + 1)
					_sf.add_index(i + 2)
					
					_sf.add_index(i + 1)
					_sf.add_index(i + 3)
					_sf.add_index(i + 2)
					verts += 1
	
	return _sf.commit(null,
		Mesh.ARRAY_FORMAT_VERTEX+
		Mesh.ARRAY_FORMAT_NORMAL+
		Mesh.ARRAY_FORMAT_COLOR+
		Mesh.ARRAY_FORMAT_TEX_UV+
		Mesh.ARRAY_FORMAT_TEX_UV2
	)
	
func draw_from_xforms_indexed_olreliable(p : Array = Array(),
					inv_origin_xform : Transform3D = Transform3D()) -> ArrayMesh:
	_sf.begin(render_mode)
	
	var last = null
	var verts = 0
	var ps = p.size()-1
	if ps <= 0:
		return ArrayMesh.new()
	
	var inv_ps = 1.0/(ps-1)
	
	for i in range(ps):
		var p1 = p[i]
		var p2 = p[i+1]
		
		if p1 != null and p2 != null:
			var perp = inv_origin_xform.basis*p1.basis.x
			p1 = inv_origin_xform*p1.origin
			p2 = inv_origin_xform*p2.origin
			var p1pc = p2-p1
			
			if last != null: p1pc = last
			
			var p1c = Color(p1pc.x,p1pc.y,p1pc.z)
			
			var uv2 = lerp(1.0,0.0,inv_ps*i)
			var uv1 = uv2
			
			_sf.add_color( p1c )
			_sf.set_normal( perp )
			_sf.set_uv( Vector2(uv1,1.0) )
			_sf.set_uv2( Vector2(uv2,1.0) )
			_sf.add_vertex( p1 )
			_sf.set_uv( Vector2(uv1,0.0) )
			_sf.set_uv2( Vector2(uv2,0.0) )
			_sf.add_vertex( p1 )
			
			var overflow = i > ps-2
			i += verts
			
			if not overflow:
				_sf.add_index(i)
				_sf.add_index(i + 1)
				_sf.add_index(i + 2)
				
				_sf.add_index(i + 1)
				_sf.add_index(i + 3)
				_sf.add_index(i + 2)
			
			verts += 1
	return _sf.commit(null,
		Mesh.ARRAY_FORMAT_VERTEX+
		Mesh.ARRAY_FORMAT_NORMAL+
		Mesh.ARRAY_FORMAT_COLOR+
		Mesh.ARRAY_FORMAT_TEX_UV+
		Mesh.ARRAY_FORMAT_TEX_UV2
	)

# Experimental, do not use
func draw_from_points_arrays(p : PackedVector3Array = PackedVector3Array(),
						total_length : float = 1.0) -> ArrayMesh:
	if p.is_empty():
#		push_warning("p is empty, mesh will not be updated")
		return ArrayMesh.new()
	assert(p is PackedVector3Array) #,"p must be PackedVector3Array")
	var uvs = total_length
	
	var vert_arr = []
	var norm_arr = []
	
	_sf.begin(render_mode)
	
	var last = null
	var ps = p.size()-2
	
	vert_arr.resize(ps*6)
	norm_arr.resize(ps*6)
	
	for i in range(ps):
		var p1 = p[i]
		var p2 = p[i+1]
		var p3 = p[i+2]
		
		if p1 != null and p2 != null:
			var p1pc = p1.direction_to(p2)
			var p2pc = p1pc
			if p3 != null:
				p2pc = p1.direction_to(p3)
			
			if last != null: p1pc = last
			
			var p1c = Color(p1pc.x,p1pc.y,p1pc.z)
			var p2c = Color(p2pc.x,p2pc.y,p2pc.z)
			
			var uv1 = (float(ps-i)/ps)*uvs
			var uv2 = (float(ps-(i+1))/ps)*uvs
			
			_sf.add_color( p1c )
			_sf.set_uv( Vector2(uv1,1.0) )
			_sf.add_vertex( p1 )
			_sf.set_uv( Vector2(uv1,0.0) )
			_sf.add_vertex( p1 )
			
			_sf.add_color( p2c )
			_sf.set_uv( Vector2(uv2,1.0) )
			_sf.add_vertex( p2 )
			
			
			_sf.add_color( p1c )
			_sf.set_uv( Vector2(uv1,0.0) )
			_sf.add_vertex( p1 )
			
			_sf.add_color( p2c )
			_sf.set_uv( Vector2(uv2,0.0) )
			_sf.add_vertex( p2 )
			_sf.set_uv( Vector2(uv2,1.0) )
			_sf.add_vertex( p2 )
			
			last = p2pc
	
	return _sf.commit(null,
		Mesh.ARRAY_FORMAT_VERTEX+
		Mesh.ARRAY_FORMAT_NORMAL+
		Mesh.ARRAY_FORMAT_COLOR+
		Mesh.ARRAY_FORMAT_TEX_UV+
		Mesh.ARRAY_FORMAT_TEX_UV2
	)


func draw_from_points_strip(p : PackedVector3Array = PackedVector3Array(),
					line_length : float = 1.0
					) -> ArrayMesh:
	_sf.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var last = Vector3(0,0,0)
	var last_miter = null
	
	var ps = p.size()
	if ps < 2: return ArrayMesh.new()
	
	
	var acc = 0.0
	var last_dist = p[0].distance_squared_to(p[1])
	for i in range(ps-1):
		var cur_dist =p[i].distance_squared_to(p[i+1])
		acc += lerp(cur_dist,last_dist,0.2)
#	print(acc)
	acc = sqrt(acc)
	var ll = acc
#	line_length = ll
	
	var inv_ps = 1.0/(ps-1)
	
	for i in range(ps+2):
		var real_i = i
		if i > 0: i -= 1
		if i > ps-1: i -= 1
		var p1 = p[i]
		
		if p1 != null:
			if i < ps-1:
				last = p[i+1] - p1
			
			var dir = last
			if last_miter and i > 0 and i < ps-1:
				dir = last_miter
			
#			print(last_miter != null, " ", i)
			
			# TODO: calculate total_length
			var uv1x = 1.0-(inv_ps*(real_i-1)) 
#			print(uv, " ", i)
			var extras_uv2 = Vector2(line_length, inv_ps)
			
			
			_sf.set_normal( dir )
			
			_sf.set_uv( Vector2(uv1x,1.0) )
			_sf.set_uv2( extras_uv2 )
			_sf.add_vertex( p1 )
			
			_sf.set_normal( dir )
			
			_sf.set_uv( Vector2(uv1x,0.0) )
			_sf.set_uv2( extras_uv2 )
			_sf.add_vertex( p1 )
			
			
			if i < ps-2:
				last_miter = p[i+2] - p1
	
	var compress = Mesh.ARRAY_FORMAT_VERTEX+Mesh.ARRAY_FORMAT_NORMAL+Mesh.ARRAY_FORMAT_COLOR+Mesh.ARRAY_FORMAT_TEX_UV+Mesh.ARRAY_FORMAT_TEX_UV2
	
	# If vertex count > 1024, the method we use
	# to have rounded caps breaks
	# because half-float precision is not precise enough
	
	# We've enabled full-precision float for UV here
	# it's a waste of bits (uses 64 bits instead of 32) but it's a quick and easy fix,
	# and it's not as bad as using the entire vec4 COLOR buffer just to store a single float
#	compress -= Mesh.ARRAY_COMPRESS_TEX_UV
	
	return _sf.commit(null, compress)
