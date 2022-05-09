shader_type spatial;
render_mode skip_vertex_transform, cull_disabled;
render_mode vertex_lighting,specular_blinn;
//render_mode depth_draw_alpha_prepass;

uniform float line_width = 0.1;
uniform bool tangent_facing = false;
uniform bool rounded = false;
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

varying float is_end;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	is_end = line_process(line_width,VERTEX,normalize(VERTEX),UV,NORMAL,TANGENT);
	
	BINORMAL = cross(TANGENT,NORMAL);
	
	float line_length = UV2.x;
	UV.x = 1.0-UV.x;
	UV2 = UV;
	UV2.x *= line_length;
	
	if (rounded) {
		float uv_correct = is_end*line_width;
		UV.x += uv_correct;
		UV2.x += uv_correct;
	}
}

uniform sampler2D albedo_tex : hint_albedo;
uniform bool tex_stretch = true;
uniform vec2 tex_scale = vec2(1.0,1.0);

uniform vec4 color : hint_color = vec4(vec3(1.0),1.0);
uniform float metallic  : hint_range(0.0,1.0,0.005) = 0.0;
uniform float specular  : hint_range(0.0,1.0,0.005) = 0.5;
uniform float roughness : hint_range(0.0,1.0,0.005) = 0.5;
void fragment() {
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
	
	vec2 uv_alb = UV2;
	if (tex_stretch) {
		uv_alb = UV;
	}
	uv_alb *= tex_scale;
	
	vec4 alb_sample = texture(albedo_tex,uv_alb);
	
	ALBEDO = alb_sample.rgb * color.rgb;
	ALPHA = alb_sample.a * color.a;
	SPECULAR = specular;
	ROUGHNESS = roughness;
	METALLIC = metallic;
}