shader_type spatial;
render_mode unshaded;
render_mode blend_add;

vec3 line_process(float width, vec3 vertex, mat4 world_mat, vec3 cam_pos, vec3 dir_to_next_vertex, vec2 uv,
					out vec3 normal, out vec3 tangent){
	vec3 wv = (world_mat*vec4(vertex,1.0)).xyz;
	vec3 dir_to_cam = cam_pos-wv;
	dir_to_cam *= mat3(world_mat);
	vec3 perp = normalize(cross(dir_to_cam,-dir_to_next_vertex));
	
	tangent = perp;
	normal = cross(perp,dir_to_next_vertex);
	
	if (uv.y < 0.5)	perp *= -1.0;
	vertex += perp*width;
	return vertex;
}
uniform float glow_width : hint_range(0.0,1.0) = 0.1;
uniform float line_width : hint_range(0.0,1.0) = 0.01;
uniform float curve : hint_range(0.0,1.0) = 0.01;
varying float lw;
void vertex(){
	float glo_width = pow(UV.x,curve)*glow_width;
	lw = max(line_width,0.001)/max(line_width+glo_width,0.001);
	VERTEX = line_process(line_width+glo_width,VERTEX,WORLD_MATRIX,CAMERA_MATRIX[3].xyz,COLOR.xyz,UV,
							NORMAL,TANGENT);
}

void fragment(){
	float line = abs(UV.y*2.0-1.0);
	
//	float lw = max(line_width,0.001)/max(glow_width+line_width,0.001);
	
	float center = smoothstep(lw,lw*0.5,line);
	float glow = pow(1.0-line,1.0/curve)*0.5;
	ALBEDO = vec3((center+glow)*UV.x);
//	ALPHA = (center+glow)*UV.x;
}