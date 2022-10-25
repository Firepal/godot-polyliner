shader_type spatial;
render_mode skip_vertex_transform;
render_mode unshaded;
render_mode blend_add;

// \"tangent-facing\" code and \"rounded end\" code was removed
// for this particular shader

uniform float line_width = 0.05;
float line_process(float width, float depth, inout vec3 vertex, vec3 dir_to_cam, vec2 uv,
					inout vec3 normal, inout vec3 tangent, inout vec3 binormal){
	vec3 dir_to_next_point = normal;
	vec3 perp = normalize(cross(dir_to_cam,dir_to_next_point));
	
	float is_end = 0.5-uv.x;
	is_end = float(abs(is_end) > 0.5) * -sign(is_end);
	
	float side = sign(float(uv.y > 0.5)-0.5);
	binormal = perp;
	normal = cross(perp,dir_to_next_point);
	tangent = cross(binormal,normal);
	
	vertex += (perp*side) * width;
	
	
	
	return is_end;
}

vec3 hash31(float p) {
   vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
   p3 += dot(p3, p3.yzx+33.33);
   return fract((p3.xxy+p3.yzz)*p3.zyx); 
}

mat3 rotateAlign( vec3 v1, vec3 v2 )
{
	vec3 axis = cross( v1, v2 );
	
	float cosA = dot( v1, v2 );
	float k = 1.0 / (1.0 + cosA);
	
	mat3 result = mat3(
		vec3(
		(axis.x * axis.x * k) + cosA,
		(axis.y * axis.x * k) - axis.z, 
		(axis.z * axis.x * k) + axis.y),
		vec3(
			(axis.x * axis.y * k) + axis.z,  
			(axis.y * axis.y * k) + cosA,      
			(axis.z * axis.y * k) - axis.x),
		vec3(
			(axis.x * axis.z * k) - axis.y,  
			(axis.y * axis.z * k) + axis.x,  
			(axis.z * axis.z * k) + cosA)
		);

	return result;
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
uniform float twirl_aspect = 0.5;
uniform float circle_margin = 1.0;
uniform float angle = 0.0;

varying vec3 ray_dir;
varying vec3 ray_origin;
varying mat3 rot;
varying mat3 TBN;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	float is_end = line_process(line_width,0.5,VERTEX,normalize(VERTEX),UV,NORMAL,TANGENT,BINORMAL);
	
	
	TBN = mat3(
		TANGENT,
		BINORMAL,
		NORMAL
	);
	
	// I don't know how this works, but it does, so no complaints
	vec3 yeds = INV_CAMERA_MATRIX[1].xyz * TBN;
	float a1 = atan(-yeds.y,yeds.z);
	rot = rotation3dX( a1 + angle );
	TBN *= rot;
	
	ray_dir = VERTEX * TBN;
	ray_origin = vec3(UV,0.2);
	float asp = twirl_aspect / line_width;
	asp *= UV2.x;
	
	ray_origin.y -= 0.5;
	ray_origin.xy *= vec2(asp,1.0)*0.4;
	ray_origin *= circle_margin;
	
	ray_origin *= rot;
	
	// Handle object rotation
	rot = mat3(WORLD_MATRIX) * rot;
}
float sdBox2D( in vec2 p, in vec2 b ) {
	vec2 d = abs(p)-b;
	return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

float sdCappedCylinder( vec3 p, float h, float r ) {
	vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
	return min(max(d.x,d.y),0.0) + length(max(d,0.0));
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

uniform float repeat_size = 1.0;
uniform float rot_angle = 0.0;
uniform float rot_period = 0.0;
vec2 scene(vec3 p) {
	vec3 yes = vec3(0.0);
	vec3 pr = opRep(p,vec3(repeat_size,0.0,0.0),yes);
	
	mat3 roty = rotation3dX((yes.x*rot_period)+rot_angle);
	vec3 p1 = (pr * roty).yxz;
	
	float r1 = sdCappedCylinder(p1,0.2,0.005);
	r1 = max(-(length(p1.zx)-0.2),r1);
	r1 = max(-sdBox2D(p1.zx-vec2(0.15),vec2(0.15)),r1);
//	float r1 = length(p.zy)-0.04;
	
	float dist = r1;
//	float dist = smin(r1,r2,0.03);

	float color = yes.x;
	
	return vec2(dist,color);
//	return smin(r1,r2,yes.x*0.1);
}

vec3 getNormal( in vec3 p )
{
	const float h = 0.001;
	const vec2 k = vec2(1,-1);
	return normalize( k.xyy*scene( p + k.xyy*h ).x + 
                      k.yyx*scene( p + k.yyx*h ).x + 
                      k.yxy*scene( p + k.yxy*h ).x + 
                      k.xxx*scene( p + k.xxx*h ).x );
}

vec2 raymarch(vec3 ro, vec3 rd) {
	float total_dist = 0.0;
	float min_dist = 1e20;
	
	for(int i=0;i<30;i++){
		// culling below 3.0 is excessive
		// and even more visible at grazing angles
		if (total_dist > 5.0) { break; }
		
		vec3 ray = ro + (rd * total_dist);
		
		float dist = scene(ray).x;
		
		if (dist < 0.001){
			return vec2(total_dist,dist);
		}
		
		min_dist = min(dist,min_dist);
		total_dist += dist;
	}
	
	return vec2(-1.0,min_dist);
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

uniform float roughness : hint_range(0.0, 1.0, 0.001) = 0.5;
uniform vec4 color : hint_color = vec4(vec3(1.0,0.1,1.0),1.0);

void fragment(){
	ALBEDO = color.rgb;
	ROUGHNESS = roughness;
	
	vec3 ro = ray_origin;
	vec3 rd = normalize(ray_dir);
	
	vec2 hit = raymarch(ro, rd);
	float hit_dist = hit.x;
	vec3 hit_pos = ro + rd * hit_dist;
	
	
//	if (hit_dist < 0.0) { discard; }
	
	vec3 hit_normal = TBN * getNormal(hit_pos);
	
	NORMAL = hit_normal;
	
	ALPHA = 1.0-pow(smoothstep(0.01,0.2,hit.y),0.1);
	ALBEDO = mix(color.rgb,vec3(1.0),ALPHA*color.a);
	
	
}