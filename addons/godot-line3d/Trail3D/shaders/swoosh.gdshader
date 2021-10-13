shader_type spatial;
render_mode cull_disabled;
render_mode unshaded;

uniform vec4 color : hint_color = vec4(vec3(1.0),1.0);
void fragment(){
	NORMAL = FRONT_FACING ? NORMAL : -NORMAL;
	ALPHA = (UV.x);
	ALBEDO = color.rgb;
}