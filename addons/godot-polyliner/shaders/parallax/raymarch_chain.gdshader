shader_type spatial;
render_mode skip_vertex_transform,cull_disabled;
render_mode depth_draw_opaque;

#include "res://addons/godot-polyliner/shaders/include/polyliner_inc.gdshaderinc"

const float RAY_MISS = 1e20;

uniform float twirl_aspect = 0.5;
uniform float extra_angle = 0.0;

varying vec3 ray_origin;
varying mat3 TBN;

uniform float line_width = 0.025;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	float is_end;
	quick_line(line_width,false)
	
	TBN = mat3(
		BINORMAL,
		TANGENT,
		NORMAL
	);
	
	vec3 yeds = MODELVIEW_MATRIX[1].xyz * TBN;
	mat3 rot = rotation3dX( atan(-yeds.y,yeds.z) );
	TBN *= rot;
	
	ray_origin = vec3(UV,0.0);
	ray_origin.x *= UV2.x;
	
	float asp = twirl_aspect / line_width;
	
	ray_origin.y -= 0.5;
	ray_origin.xy *= vec2(asp,1.0)*0.4;
	
	ray_origin *= rot;
}

vec3 opRep( in vec3 p, in vec3 c )
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

uniform float link_radius = 0.15;
uniform float link_thickness = 0.05;
uniform float repeat_size = 1.0;
uniform float repeat_size_b = 0.1;
float sdLink( vec3 p, float le ) {
	float r1 = link_radius;
	float r2 = link_thickness;
	vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
	return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

float scene(vec3 p){
	p = opRep(p,vec3(repeat_size+repeat_size_b,0.0,0.0));
	p.x = p.x - clamp(p.x,-repeat_size_b,repeat_size_b);
	p.x = clamp(p.x,-0.5,0.5);
	
	vec3 p1 = p.yxz;
	vec3 p2 = p.zxy - vec3(0.0,0.4,0.0);
	vec3 p3 = p.zxy + vec3(0.0,0.4,0.0);
	
	float r1 = sdLink(p1, 0.1);
	float r2 = sdLink(p2, 0.1);
	float r3 = sdLink(p3, 0.1);
	
//	return min(r1,r2);
	return min(r1,min(r2,r3));
}

vec3 getNormal( in vec3 p )
{
    const float h = 0.0001;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*scene( p + k.xyy*h ) + 
                      k.yyx*scene( p + k.yyx*h ) + 
                      k.yxy*scene( p + k.yxy*h ) + 
                      k.xxx*scene( p + k.xxx*h ) );
}

float raymarch(vec3 ro, vec3 rd){
	float total_dist = -2.0;
	
	for(int i=0;i<128;i++){
		if (total_dist > 4.0) { break; }
		
		vec3 ray = ro + (rd * total_dist);
		
		float dist = scene(ray);
		
		if (dist < 0.0001){
			return total_dist;
		}
		
		total_dist += dist;
	}
	
	return RAY_MISS;
}

float fake_ao(vec3 ro, vec3 rd) {
	float ao = 1.0;
	const float scale = 0.02;
	float sc = scale;
	for (int i = 0; i < 5; i++) {
		ao += scene(ro + rd * sc);
		sc *= 2.0;
	}
	return log2(ao)*1.6;
}

uniform float roughness : hint_range(0.0, 1.0, 0.001) = 0.25;
uniform float metallic : hint_range(0.0, 1.0, 0.001) = 1.0;
uniform vec4 color : source_color = vec4(vec3(0.9),1.0);

varying vec3 hit_pos;
void fragment() {
	vec3 ro = ray_origin*1.1;
	vec3 rd = -VIEW * TBN;
	
	float hit = raymarch(ro, rd);
	if ( abs(hit - RAY_MISS) < 0.001 ) { discard; }
	
	hit_pos = ro + rd * hit;
	
	vec3 hit_normal = getNormal(hit_pos);
	NORMAL = TBN * hit_normal;
	
	ALBEDO = color.rgb;
//	AO = fake_ao(hit_pos,hit_normal);
	
	ROUGHNESS = roughness;
	METALLIC = metallic;
}

//uniform float ls = 0.1;
//float raymarch_light(vec3 ro, vec3 rd){
//	float depth = 0.01;
//	float shadow = 1.0;
//	float light_size = ls;
//	for(int i = 0; i < 60; i++) {
//		float dist = scene(ro + depth*rd);
//		if(depth > 1.0 || shadow < -1.0) { break; }
//
//		shadow = min(shadow, dist/(light_size*depth));
//		depth += clamp(dist, 0.04, 0.05);
//	}
//
//	return smoothstep(-1.0, 0.0, shadow);
//}
//
//void light() {
//	vec3 normal = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * ALBEDO;
//	DIFFUSE_LIGHT += normal*raymarch_light(hit_pos,LIGHT*TBN);
//}