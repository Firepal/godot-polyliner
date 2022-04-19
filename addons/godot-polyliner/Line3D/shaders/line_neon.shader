shader_type spatial;
render_mode specular_schlick_ggx;
//render_mode depth_draw_always;
render_mode blend_add;

uniform float line_width : hint_range(0.0,1.0) = 0.1;
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
void vertex(){
	VERTEX = line_process(line_width,VERTEX,WORLD_MATRIX,CAMERA_MATRIX[3].xyz,NORMAL,UV,
							NORMAL,TANGENT);
	UV2 = (UV2*2.0)-1.0;
}

uniform float edge_pos : hint_range(0.0,1.0) = 0.9;
uniform float edge_softness : hint_range(0.001,1.0) = 0.9;
uniform float edge_diminish : hint_range(0.001,1.0) = 0.9;
void fragment(){
	ALBEDO = vec3(0.0);
	ROUGHNESS = 0.4;
	NORMALMAP.x = UV.y;
	
	vec2 base = abs(UV2);
	
	float light = smoothstep(1.0,0.0,base.y);
	light = pow(light,0.75);
	const vec3 white = vec3(1.0);
	EMISSION = mix(vec3(1.0,0.1,1.0)*light,white,light)*0.8;
	
	float s0 = edge_pos-edge_softness;
	float s1 = edge_pos+edge_softness;
	float edge = smoothstep(s1,s0,base.x);
	EMISSION *= mix(edge,1.0,edge_diminish);
	
	ALPHA = smoothstep(1.0,0.98,base.x);
}