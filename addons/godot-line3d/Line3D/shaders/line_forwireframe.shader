shader_type spatial;
render_mode unshaded;

vec3 line_process(float width, vec3 vertex, mat4 world_mat, vec3 cam_pos, vec3 dir_to_next_vertex, vec2 uv){
	vec3 wv = (world_mat*vec4(vertex,1.0)).xyz;
	vec3 dir_to_cam = wv-cam_pos;
	dir_to_cam *= mat3(world_mat);
	vec3 perp = normalize(cross(dir_to_cam,dir_to_next_vertex));
	
	if (uv.y < 0.5)	perp *= -1.0;
	vertex += perp*width;
	return vertex;
}
uniform float line_width;
void vertex(){
	VERTEX = line_process(line_width,VERTEX,WORLD_MATRIX,CAMERA_MATRIX[3].xyz,COLOR.xyz,UV);
}

void fragment(){
	ALBEDO = vec3(1.0);
}