shader_type spatial;
render_mode depth_draw_alpha_prepass;

uniform float line_width = 0.03;
uniform bool tangent_facing = false;
uniform bool rounded = false;
float line_process(float width, inout vec3 vertex, mat4 world_mat, vec3 cam_pos, vec2 uv,
					inout vec3 normal, inout vec3 tangent){
	vec3 dir_to_cam = ((world_mat*vec4(vertex,1.0)).xyz - cam_pos) * mat3(world_mat);
	vec3 perp = tangent;
	if (!tangent_facing) {
		perp = normalize(cross(dir_to_cam,normal));
	}
	
	
	float is_end = float(abs(uv.x-0.5) > 0.4999) * -sign(uv.x-0.5);
	vec3 rounder = vec3(0.0); 
	if (rounded) { 
		rounder = is_end * -normalize(cross(perp,dir_to_cam));
	}

	float side = sign(float(uv.y > 0.5)-0.5);
	vertex += ((perp*side)-rounder) * width;
	normal = cross(perp,normal);
	tangent = perp;
	
	return is_end;
}

varying float is_end;
void vertex(){
	is_end = line_process(line_width,VERTEX,WORLD_MATRIX,CAMERA_MATRIX[3].xyz,UV2,
							NORMAL,TANGENT);
	BINORMAL = cross(NORMAL,TANGENT);
	
	if (rounded) {
		float uv_correct = is_end*line_width;
		UV.x += uv_correct;
		UV2.x += uv_correct;
	}
}

float getDistToLineCenter(vec2 uv) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return length(c)*2.0;
}

float getDistSquaredToLineCenter(vec2 uv) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return dot(c,c)*4.0;
}

vec2 getLineTubeNormal(vec2 uv) {
	vec2 n = vec2(0.5);
		n.x = uv.y;
		if (rounded) {
			n.y = is_end*0.5+0.5;
		}
	return n;
}

uniform vec4 color : hint_color = vec4(vec3(1.0),1.0);
void fragment(){
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	if (!tangent_facing)	NORMALMAP.xy = vec2(UV2.y,is_end*0.5+0.5);
	
	vec2 tex_uv = UV;
	
	ALBEDO = color.rgb;
	
	if (rounded) {
		if (abs(is_end) > 0.0) {
				ALPHA *= smoothstep(1.0,0.95,getDistSquaredToLineCenter(UV));
		}
	}
	
	
	ALPHA_SCISSOR = 0.001; // uncomment for alpha blending
}