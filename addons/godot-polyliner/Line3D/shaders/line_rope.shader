shader_type spatial;
render_mode specular_schlick_ggx;
//render_mode unshaded;

uniform float line_width = 0.03;
uniform bool z_facing = false;
uniform bool rounded = false;
float line_process(float width, inout vec3 vertex, mat4 world_mat, vec3 cam_pos, vec3 dir_to_next_vertex, vec2 uv,
					inout vec3 normal, out vec3 tangent){
	vec3 dir_to_cam = ((world_mat*vec4(vertex,1.0)).xyz - cam_pos)*mat3(world_mat);
	vec3 perp = cross(dir_to_cam,dir_to_next_vertex);
	if (z_facing)	perp = normal;
	
	float is_end = float(abs(uv.x-0.5) > 0.4999);
	float endsign = -sign(uv.x-0.5);
	vec3 rounder = (is_end*endsign) * normalize(-cross(perp,dir_to_cam));
	if (!rounded || z_facing)	rounder = vec3(0.0);

	float side = sign(float(uv.y > 0.5)-0.5);
	perp = normalize(perp);
	perp = ((perp*side)-rounder);
	vertex += perp * width;
	
	tangent = perp;
	normal = cross(perp,dir_to_next_vertex);
	return is_end*endsign;
}

varying float is_end;
void vertex(){
	is_end = line_process(line_width,VERTEX,WORLD_MATRIX,CAMERA_MATRIX[3].xyz,NORMAL,UV2,
							NORMAL,TANGENT);
	BINORMAL = ( cross(NORMAL,TANGENT) );
	
	if (rounded && !z_facing) {
		UV.x += is_end*line_width;
		UV2.x += is_end*line_width;
	}
}

float getDistToLineCenter(vec2 uv) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return length(c);
}

float getDistSquaredToLineCenter(vec2 uv) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return dot(c,c);
}

vec2 getLineTubeNormal(vec2 uv) {
	vec2 n = vec2(0.5);
		n.x = uv.y;
		if (rounded) {
			n.y = is_end*0.5+0.5;
		}
	return n;
}

uniform float test = 0.4;
void fragment(){
	if (rounded && !z_facing && getDistSquaredToLineCenter(UV2) > 0.26) { discard; }
	
	vec2 u = UV2;
	
	u.x *= test*10.0;
	const float eps = 0.0001;
	const vec2 ofs = vec2(0.03,0.0);
	float lc = sin(dot(u,vec2(14.0)));
	lc = (lc*0.5)+0.5;
	
	ALBEDO = vec3( 1.0,1.0,0.8 )*lc;
	ROUGHNESS = 0.7;
	if (!z_facing) { NORMALMAP.xy = getLineTubeNormal(UV); }
}