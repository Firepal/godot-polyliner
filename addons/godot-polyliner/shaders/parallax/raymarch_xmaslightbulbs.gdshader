shader_type spatial;
render_mode skip_vertex_transform;
//render_mode unshaded;

// \"tangent-facing\" code and \"rounded end\" code was removed
// for this particular shader

#include "res://addons/godot-polyliner/shaders/include/polyliner_inc.gdshaderinc"

uniform float line_width = 0.05;

uniform float twirl_aspect = 0.5;
uniform float angle = 0.0;

varying vec3 ray_origin;
varying mat3 TBN;
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

float smin( float a, float b, float k ) {
	float h = max( k-abs(a-b), 0.0 )/k;
	return min( a, b ) - h*h*k*(1.0/4.0);
}


vec3 opRep( in vec3 p, in vec3 c, out vec3 y ) {
    vec3 q = mod(p+0.5*c,c)-0.5*c;
	y = floor((p+0.5*c)/c);
    return q;
}

float sdRoundCone(vec3 p, vec3 a, vec3 b, float r1, float r2) {
	// sampling independent computations (only depend on shape)
	vec3  ba = b - a;
	float l2 = dot(ba,ba);
	float rr = r1 - r2;
	float a2 = l2 - rr*rr;
	float il2 = 1.0/l2;

	// sampling dependant computations
	vec3 pa = p - a;
	float y = dot(pa,ba);
	float z = y - l2;
	
	vec3 pal = pa*l2 - ba*y;
	float x2 = dot( pal, pal );
	float y2 = y*y*l2;
	float z2 = z*z*l2;

  // single square root!
	float k = sign(rr)*rr*rr*x2;
	if( sign(z)*a2*z2>k ) return  sqrt(x2 + z2)        *il2 - r2;
	if( sign(y)*a2*y2<k ) return  sqrt(x2 + y2)        *il2 - r1;
	return (sqrt(x2*a2*il2)+y*rr) * il2 - r1;
}

uniform float repeat_size = 0.3;
uniform float rot_angle = 0.0;
uniform float rot_period = 0.0;
vec2 scene(vec3 p) {
	vec3 yes = vec3(0.0);
	vec3 pr = opRep(p,vec3(repeat_size,0.0,0.0),yes);
	
	vec3 p1 = pr.yxz;
	mat3 roty = rotation3dX((yes.x*rot_period)+rot_angle);
	vec3 p2 = p1.yzx * roty;
	
	float r1 = length(p.zy)-0.04;
	float r2 = sdRoundCone(p2,vec3(0.0,0.0,0.08),vec3(0.0,0.0,0.2),0.04,0.01);
	
//	float dist = r1;
	float dist = min(r1,r2);
//	float dist = smin(r1,r2,0.03);

	float col = yes.x;
	if (r2 > r1) { col = -10.0; }
	
	return vec2(dist,col);
//	return smin(r1,r2,yes.x*0.1);
}

vec3 getNormal( in vec3 p )
{
    const float h = 0.0001;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*scene( p + k.xyy*h ).x + 
                      k.yyx*scene( p + k.yyx*h ).x + 
                      k.yxy*scene( p + k.yxy*h ).x + 
                      k.xxx*scene( p + k.xxx*h ).x );
}

vec3 hashcol(float seed) {
	float randseed = fract(seed*0.3056);
	const vec3 red = vec3(1.0,0.0,0.0);
	const vec3 green = vec3(0.0,1.0,0.0);
	const vec3 blue = vec3(0.0,0.0,1.0);
	
	vec3 co = mix(red,green,smoothstep(0.3333,0.3,randseed));
	co = mix(co,blue,smoothstep(0.6,0.6666,randseed));
	
	return vec3(co);
}

float raymarch(vec3 ro, vec3 rd){
	float total_dist = -0.8;
	float r = smoothstep(-0.04,0.3,repeat_size);
	for(int i=0;i<128;i++){
		if (total_dist > 80.0) { break; }
		
		vec3 ray = ro + (rd * total_dist);
		
		float dist = scene(ray).x;
		
		if (dist < 0.00001){
			return total_dist;
		}
		
		total_dist += dist*r;
	}
	
	return -1e20;
}

uniform float roughness : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform vec4 color : source_color = vec4(vec3(0.1),1.0);

void fragment(){
	ALBEDO = color.rgb;
	ROUGHNESS = roughness;
	
	vec3 ro = ray_origin;
	vec3 rd = -VIEW * TBN;
	
	float hit_info = raymarch(ro, rd);
	
	if (hit_info == -1e20) { discard; }
	vec3 hit_pos = ro + rd * hit_info;
	
	float colhash = scene(hit_pos).y;
	
	vec3 hit_normal = TBN * getNormal(hit_pos);
	
	NORMAL = hit_normal;
	
	if (colhash > -1.0) {
		float thing = pow(smoothstep(1.0,0.0,dot(NORMAL,VIEW)),0.1);
		float thing2 = 1.0-pow(smoothstep(1.0,0.0,dot(NORMAL,VIEW)),0.5);
//		ALPHA = thing;
		EMISSION = hashcol( colhash ) + (1.0-thing);
		
		ALBEDO = vec3(0.01);
		ROUGHNESS = 0.3;
	}
	
}