shader_type spatial;
render_mode unshaded;

uniform float line_width = 0.03;
uniform bool z_facing = false;
uniform bool rounded = false;
float line_process(float width, inout vec3 vertex, mat4 world_mat, vec3 cam_pos, vec3 dir_to_next_vertex, vec2 uv,
					inout vec3 normal, inout vec3 tangent){
	vec3 dir_to_cam = ((world_mat*vec4(vertex,1.0)).xyz - cam_pos)*mat3(world_mat);
	vec3 perp = cross(dir_to_cam,dir_to_next_vertex);
	if (z_facing)	perp = normal;
	
	float is_end = float(abs(uv.x-0.5) > 0.4999);
	float endsign = -sign(uv.x-0.5);
	vec3 rounder = (is_end*endsign) * normalize(-cross(perp,dir_to_cam));
	if (!rounded || z_facing)	rounder = vec3(0.0);

	float side = sign(float(uv.y > 0.5)-0.5);
	perp = normalize(perp);
	vec3 perpp = cross(perp,tangent);
	float d = dot(perpp,dir_to_next_vertex);
	d = acos(d);
	vertex += ((perp*side)-rounder) * (width/d);
//	if (!rounded || z_facing)	vertex *= 1.0-is_end;
	
	tangent = perp;
	normal = cross(perp,dir_to_next_vertex);
	
	return (d);
}

varying float anglee;
void vertex(){
	anglee = line_process(line_width,VERTEX,WORLD_MATRIX,CAMERA_MATRIX[3].xyz,NORMAL,UV2,
							NORMAL,TANGENT);
}

void fragment(){
	ALBEDO = vec3(anglee);
}