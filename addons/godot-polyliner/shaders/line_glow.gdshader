shader_type spatial;
render_mode skip_vertex_transform, cull_disabled;
render_mode blend_add, unshaded;

uniform bool tangent_facing = false;
uniform bool rounded = true;
float line_process(float width, inout vec3 vertex, vec3 dir_to_cam, vec2 uv,
					inout vec3 normal, inout vec3 tangent){
	vec3 dir_to_next_point = normal;
	vec3 perp = tangent;
	if (!tangent_facing) {
		perp = normalize(cross(dir_to_cam,dir_to_next_point));
	}
	
	float is_end = 0.5-uv.x;
	is_end = float(abs(is_end) > 0.5) * -sign(is_end);
	vec3 rounder = vec3(0.0); 
	if (rounded) { 
		rounder = is_end * normalize(cross(perp,dir_to_cam));
	}

	float side = sign(float(uv.y > 0.5)-0.5);
	vertex += ((perp*side)-rounder) * width;
	
	tangent = perp;
	normal = cross(perp,dir_to_next_point);
	
	return is_end;
}

uniform float line_width = 0.0;
uniform float glow_width = 0.4;

varying float is_end;
varying float lw;
varying float hider;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	float lww = line_width+glow_width;
	hider = smoothstep(1.0,0.8,abs(dot(NORMAL,normalize(VERTEX))));
	is_end = line_process(lww,VERTEX,normalize(VERTEX),UV2,NORMAL,TANGENT);
	
	lw = max(line_width,0.001)/max(line_width+glow_width,0.001);
}

float getDistToLineCenter(vec2 uv) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return length(c);
}


uniform vec4 color : hint_color = vec4(vec3(1.0),1.0);
uniform float curve : hint_range(0.0,1.0) = 0.2;
void fragment(){
	float roundededge = smoothstep(lw*0.5,0.5,getDistToLineCenter(UV));
	roundededge = 1.0-pow(roundededge,curve);
	
	ALBEDO = mix(color.rgb,vec3(1.0),roundededge);
	ALPHA = roundededge * hider;
}