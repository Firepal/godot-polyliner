shader_type spatial;
render_mode skip_vertex_transform;
//render_mode alpha_to_coverage_and_one;
//render_mode unshaded;

const float RAY_MISS = -1e20;

// \"tangent-facing\" code and \"rounded end\" code was removed
// for this particular shader

uniform float line_width = 0.05;
float line_processe(float width, inout vec3 vertex, vec3 dir_to_cam, vec2 uv,
					inout vec3 normal, inout vec3 tangent){
	vec3 dir_to_next_point = normal;
	vec3 perp = normalize(cross(dir_to_cam,dir_to_next_point));
	
	float is_end = 0.5-uv.x;
	is_end = float(abs(is_end) > 0.5) * -sign(is_end);
	
	float side = sign(float(uv.y > 0.5)-0.5);
	vertex += (perp*side) * width;
	
	tangent = perp;
	normal = cross(perp,dir_to_next_point);
	tangent = cross(tangent,normal);
	
	return is_end;
}
#include "res://addons/godot-polyliner/shaders/include/polyliner_inc.gdshaderinc"

varying mat3 TBN;
varying float is_end;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
//	is_end = line_processe(line_width,VERTEX,normalize(VERTEX),UV,NORMAL,TANGENT);
	quick_line(line_width,false)
	
	BINORMAL = cross(TANGENT,NORMAL);
	
	TBN = mat3(
		TANGENT,
		-BINORMAL,
		NORMAL
	);
}

mat3 rotation3dX(float angle) {
	float s = sin(angle);
	float c = cos(angle);

	return mat3(
		vec3(1.0, 0.0, 0.0),
		vec3(0.0, c, s),
		vec3(0.0, -s, c)
	);
}

float sdCylinder( vec3 p, float c ){
	return length(p.yz)-c;
}

float scene(vec3 p){
	p = p*rotation3dX(p.x*3.1415);
	float o1 = sdCylinder(p - vec3(0.0,-0.2,0.0),0.2);
	float o2 = sdCylinder(p - vec3(0.0,0.1,0.2),0.2);
	float o3 = sdCylinder(p - vec3(0.0,0.1,-0.2),0.2);
	
	float rope = min(o1,min(o2,o3));
	
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
	return raymarch_base(ro,rd,512,0.00001,2.0,-2.0);
}

float raymarch_ao(vec3 ro, vec3 rd){
	return raymarch_base(ro,rd,32,0.001,0.3,0.2);
}

float raymarch_light(vec3 ro, vec3 rd){
	float depth = 0.2;
	float shadow = 1.0;
	for(int i = 0; i < 60; i++) {
		float dist = scene(ro + depth*rd);
		if(depth > 1.0 || shadow < -1.0) { break; }
		
		shadow = min(shadow, dist/(0.05*depth));
		depth += clamp(dist, 0.01, 0.05);
	}
	
	return smoothstep(-1.0, 0.0, shadow);
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx+33.33);
	return fract((p3.xx+p3.yz)*p3.zy);
}

uniform sampler2D blue_noise : filter_nearest, source_color;

vec2 R2(uint index) {
	const float g = 1.32471795724474602596;
	const float a1 = 1.0f/g;
	const float a2 = 1.0f/(g*g);
	return vec2(float(index)*a1, float(index)*a2);
}

float blue_noise_1(inout uvec3 state) {
	vec2 uv = vec2(state.xy) / 1024.0 + R2(state.z % uint(256));
	state.z = state.z + uint(1);
	return textureLod(blue_noise, uv, 0)[(state.z*uint(4)) % uint(3)];
}

uniform float ao_samples : hint_range(1,128,1) = 16;
float ao(vec3 p, vec3 n, vec2 fragcoord)
{
	vec3 t = normalize(cross(n,vec3(0.0,1.0,0.0)));
	vec3 b = normalize(cross(t,n));
	
	float inv_t = 1.0/ao_samples;
	uvec3 state = uvec3(uvec2(fragcoord),uint(TIME*1000.0*1.618));
	float occ = 0.0;
	for (float i=0.0; i < ao_samples; i++)
	{
		vec2 aa;
		aa.x = blue_noise_1(state);
		aa.y = blue_noise_1(state);
		
		float ra = sqrt(aa.y);
		float rx = ra*cos(6.2831*aa.x); 
		float ry = ra*sin(6.2831*aa.x);
		float rz = sqrt( 1.0-aa.y );
		vec3  dir = vec3( (rx*t)+(ry*b)+(rz*n) );
		
		float hit = float(raymarch_ao(p,dir) != RAY_MISS);
//		occ = 1.0-hit;
		occ = (inv_t * (1.0-hit)) + occ;
	}
	
	return occ;
}

uniform vec4 color : source_color = vec4(vec3(1.0,1.0,0.5),1.0);
uniform float twirl_aspect = 2;

uniform float ao_power : hint_range(0,2,0.001) = 1.0;

vec3 get_ro(vec2 uv) {
	vec2 scale = vec2(twirl_aspect / line_width, 1.0);
	return vec3((uv*scale)-0.5,0.0);
}

bool ray_miss(float hit) {
	return abs(hit-RAY_MISS) < 0.0001;
}

varying vec3 hit_pos;
varying vec3 hit_normal;
uniform float xez;
void fragment() {
	vec3 ro = get_ro(UV) * xez;
	vec3 rd = normalize(-VIEW * TBN);
	
	float hit = raymarch(ro, rd);
	if (ray_miss(hit)) { discard; }
	
	hit_pos = ro + (rd * hit);
	hit_normal = getNormal(hit_pos);
	NORMAL = TBN * hit_normal;
	
	ROUGHNESS = 0.8;
	
	ALBEDO = color.rgb;
//	ALPHA = smoothstep(-VERTEX.z*0.2,-0.1,dist);
//	ALBEDO = vec3(smoothstep(170.0,0.0,dist));
	float ao = ao(hit_pos, hit_normal, FRAGCOORD.xy);
//	ao = pow(ao,ao_power);
	AO = ao;
//	ALBEDO *= ao;
//	uvec3 state = uvec3(uvec2(FRAGCOORD.xy),uint(TIME*100.0));
//	ALBEDO = vec3(blue_noise_1(state));
}

void light() {
	vec3 lighting = clamp(dot(NORMAL,LIGHT)/3.1415,0.0,1.0) * LIGHT_COLOR * ATTENUATION * ALBEDO;
	float shadow = raymarch_light(hit_pos, LIGHT*TBN);
	DIFFUSE_LIGHT += lighting * shadow;
}