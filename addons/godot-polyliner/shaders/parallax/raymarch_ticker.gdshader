shader_type spatial;
render_mode skip_vertex_transform;
//render_mode alpha_to_coverage_and_one;
//render_mode unshaded;

const float RAY_MISS = -1e20;

// \"tangent-facing\" code and \"rounded end\" code was removed
// for this particular shader

uniform float line_width = 0.05;
#include "res://addons/godot-polyliner/shaders/include/polyliner_inc.gdshaderinc"

uniform float aspect = 1;
uniform bool stretch = false;

vec3 get_ro(vec2 uv) {
	vec2 scale = vec2(aspect / line_width, 1.0);
	return vec3((uv*scale)-0.5,0.0);
}

varying mat3 TBN;
varying vec3 ray_origin;
varying float is_end;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	quick_line(line_width,false)
	
	float line_length = UV2.x;
	if (!stretch) { UV.x *= line_length; }
	TBN = mat3(
		BINORMAL,
		TANGENT,
		NORMAL
	);
	
	vec3 yeds = MODELVIEW_MATRIX[1].xyz * TBN;
	mat3 rot = rotation3dX( atan(-yeds.y,yeds.z) );
	TBN *= rot;
	
	vec2 scale = vec2(aspect / line_width, 1.0);
	ray_origin = vec3((UV*scale)-0.5,0.0);
	ray_origin *= rot;
	
}

float sdCylinder( vec3 p, float c ){
	return length(p.yz)-c;
}

float scene(vec3 p){
	float o1 = sdCylinder(p,0.5);
	
	float rope = o1;
	
	return rope;
}

vec3 getNormal( in vec3 p )
{
    const float h = 0.01;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*scene( p + k.xyy*h ) + 
                      k.yyx*scene( p + k.yyx*h ) + 
                      k.yxy*scene( p + k.yxy*h ) + 
                      k.xxx*scene( p + k.xxx*h ) );
}

float raymarch_base(
	vec3 ro, 
	vec3 rd, 
	int sph_checks, 
	float min_dist,
	float max_dist,
	float start_dist
	){
	float total_dist = start_dist;
	
	for(int i=0; i<sph_checks; i++){
		if (total_dist > max_dist) { break; }
		
		vec3 ray = ro + (rd * total_dist);
		float dist = scene(ray);
		
		if (dist < min_dist){ return total_dist; }
		
		total_dist += dist;
	}
	
	return RAY_MISS;
}

float raymarch(vec3 ro, vec3 rd){
	return raymarch_base(ro,rd,512,0.001,0.6,-3.0);
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx+33.33);
	return fract((p3.xx+p3.yz)*p3.zy);
}

float IGN(vec2 p) {
	vec3 magic = vec3(0.06711056, 0.00583715, 52.9829189);
	return fract( magic.z * fract(dot(p,magic.xy)) );
}

float noise(inout uvec3 state) {
	vec2 uv = vec2(state.xy) + float(state.z)*5.588238;
	state.z = (state.z + 1u);
	return IGN(uv);
}

bool ray_miss(float hit) {
	return abs(hit-RAY_MISS) < 0.0001;
}

varying vec3 hit_pos;
varying vec3 hit_normal;
void fragment() {
	vec3 ro = ray_origin;
	vec3 rd = normalize(-VIEW * TBN);
	
	float hit = raymarch(ro, rd);
	if (hit > 0.0) { discard; }
	
	hit_pos = ro + (rd * hit);
	hit_normal = getNormal(hit_pos);
	NORMAL = TBN * hit_normal;
	
	ROUGHNESS = 0.8;
	
	vec2 uvr = vec2(
		hit_pos.x,
		atan(hit_pos.y,hit_pos.z)*0.159+0.5
	);
	uvr.y *= 7.0;
	uvr *= 2.0;
	vec2 i = floor(uvr);
	vec2 f = fract(uvr+0.5);
	vec2 grid2 = smoothstep(0.0,0.8,abs(f*2.0-1.0));
	float grid = 1.0-pow(1.0-(grid2.x*grid2.y),0.1);
	EMISSION = hash31((i.x)+i.y+floor(TIME*2.0))*grid*4.0;
	ALBEDO = vec3(0.0);
	ROUGHNESS = 0.2;
}