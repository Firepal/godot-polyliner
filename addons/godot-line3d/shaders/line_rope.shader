shader_type spatial;
render_mode specular_schlick_ggx;

vec3 line_process(float width, vec3 vertex, mat4 world_mat, vec3 cam_pos, vec3 dir_to_next_vertex, vec2 uv,
					out vec3 normal, out vec3 tangent){
	vec3 wv = (world_mat*vec4(vertex,1.0)).xyz;
	vec3 dir_to_cam = wv-cam_pos;
	dir_to_cam *= mat3(world_mat);
	vec3 perp = normalize(cross(dir_to_cam,dir_to_next_vertex));
	
	tangent = perp;
	normal = cross(perp,dir_to_next_vertex);
	
	if (uv.y < 0.5)	perp *= -1.0;
	vertex += perp*width;
	return vertex;
}
uniform float line_width;
void vertex(){
	VERTEX = line_process(line_width,VERTEX,WORLD_MATRIX,CAMERA_MATRIX[3].xyz,COLOR.xyz,UV,
							NORMAL,TANGENT);
	vec2 mull = vec2(10.0,line_width*10.0);
	UV2 = UV*mull;
}

void fragment(){
	float line = sin(dot(UV2,vec2(14.0)));
	line = smoothstep(1.0,-0.5,(line));
	line = pow(line,0.2);
	
	ALBEDO = vec3(0.2,0.5,0.3)*line;
	NORMALMAP.x = UV.y;
	ROUGHNESS = 0.7;
}