shader_type spatial;
render_mode skip_vertex_transform, cull_disabled;
render_mode unshaded;

uniform float line_width = 1.0;
uniform bool tangent_facing = true;
float line_process(float width, inout vec3 vertex, vec3 dir_to_cam, vec2 uv,
					inout vec3 normal, inout vec3 tangent){
	vec3 dir_to_next_point = normal;
	vec3 perp = tangent;
	if (!tangent_facing) {
		perp = normalize(cross(dir_to_cam,dir_to_next_point));
	}
	
	float is_end = 0.5-uv.x;
	is_end = float(abs(is_end) > 0.4999) * -sign(is_end);

	float side = sign(float(uv.y > 0.5)-0.5);
	vertex += (perp*side) * width;
	
	tangent = perp;
	normal = cross(perp,dir_to_next_point);
	
	return is_end;
}

uniform float offset = 1.0;
varying float is_end;
void vertex() {
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	is_end = line_process(line_width,VERTEX,normalize(VERTEX),UV2,
							NORMAL,TANGENT);
	VERTEX += TANGENT * line_width * offset;
}

uniform vec4 color : hint_color = vec4(vec3(1.0),1.0);
void fragment(){
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	ALPHA = (UV.x);
	ALBEDO = color.rgb;
}