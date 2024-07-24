@tool
extends Node3D

var lg = LineGen3D.new()

@export var pinchyness = 0.1 :
	set(v):
		pinchyness = v
		_update()

@export var stiffness = 0.1 :
	set(v):
		stiffness = v
		_update()

@export var link_angle = 0.1 :
	set(v):
		link_angle = v
		_update()

@export var hori_sep = 1.7 :
	set(v):
		hori_sep = v
		_update()

func get_chain_curve():
	var c = Curve3D.new()
	var o = Vector3()
	print("making chain curve")
	
	var eds = [
		Vector3(1.0,0.0,0.0),
		Vector3(1.0,2.0,0.0),
		Vector3(2.0,2.0,0.0)
	]
	
	var p = [o]
	for e in eds:
		e.x = e.x / 0.707
		e.y = e.y / 0.707
		p.push_back(o + (e))
	
#	for i in p.size():
#		p[i] = p[i] * Basis(Vector3.FORWARD,PI/4.0)
	
	
	for i in p.size():
		var in_ = Vector3()
		var out_ = Vector3()
		if i != 0 and i != p.size()-1:
			var th = Vector3(0.0,1.0,0.0).normalized()
			var rot = Basis(Vector3.RIGHT,link_angle)
			var t = th*pinchyness
			in_ = -(t * rot)
			out_ = (t * rot)
			
		else:
			in_ = Vector3.RIGHT.normalized() * sign(float(i==0)*2-1) * stiffness
			out_ = in_
		
		c.add_point(p[i],in_,out_)
	c.bake_interval = 0.01
	
	return c

func _update_line_mesh():
	var c = get_chain_curve()
	var p = c.tessellate_even_length(5,0.05)
	var mesh = lg.draw_from_points_strip(PackedVector3Array(p))
	return mesh

func _update_multimesh(mesh):
	var mm = MultiMesh.new()
	mm.mesh = mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var hori = 100
	var vert = 30
	mm.instance_count = vert*hori
	
	for j in range(vert):
		for i in range(hori):
			var t = Transform3D()
			t.origin = Vector3(i*hori_sep,j*4,0)
			t.basis = Basis(Vector3.FORWARD,-PI/4)
			if i % 2 == 1:
				t.basis = Basis(Vector3.UP,PI) * t.basis
			
			mm.set_instance_transform(j+(i*vert),t)
	
	$MultiMeshInstance3D.multimesh = mm

func _update():
	var m = _update_line_mesh()
	
	$"MeshInstance3D".mesh = m
	
	_update_multimesh(m)
	

func _ready():
	_update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
