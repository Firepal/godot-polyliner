shader_type spatial;
render_mode skip_vertex_transform, cull_disabled;
render_mode unshaded;
render_mode blend_add;

// Shader for swooshy sword effects.
// Only really makes sense to use this
// with Tangent Facing enabled

uniform float line_width = 0.4;
uniform bool tangent_facing = true;
uniform float tangent_offset = 0.5;
float line_process(float width, inout vec3 vertex, vec3 dir_to_cam, vec2 uv,
					inout vec3 normal, inout vec3 tangent){
	vec3 dir_to_next_point = normal;
	vec3 perp = tangent;
	if (!tangent_facing) {
		perp = normalize(cross(dir_to_cam,dir_to_next_point));
	}

	float side = sign(float(uv.y > 0.5)-0.5);
	vertex += (perp*side) * width;
	
	tangent = perp;
	normal = cross(perp,dir_to_next_point);
	
	return 0.0;
}

void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	float err = line_process(line_width,VERTEX,normalize(VERTEX),UV2,
							NORMAL,TANGENT);
	VERTEX += TANGENT * tangent_offset;
}

uniform vec4 color : hint_color = vec4(vec3(1.0),1.0);
uniform float alpha_curve : hint_range(0.0,1.0,0.005) = 0.5;
void fragment(){
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	float thing = smoothstep(1.014,0.0,UV2.x);
	thing = 1.0-pow(thing,alpha_curve);
	ALPHA = thing;
	ALBEDO = mix(color.rgb,vec3(1.0),thing);
}