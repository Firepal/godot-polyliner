shader_type spatial;
render_mode skip_vertex_transform;
render_mode unshaded;

// \"tangent-facing\" code and \"rounded end\" code was removed
// for this particular shader

uniform float line_width = 0.05;
float line_process(float width, inout vec3 vertex, vec3 dir_to_cam, vec2 uv,
					inout vec3 normal, inout vec3 tangent,inout vec3 binormal){
	vec3 dir_to_next_point = normal;
	vec3 perp = normalize(cross(dir_to_cam,dir_to_next_point));
	
	float is_end = 0.5-uv.x;
	is_end = float(abs(is_end) > 0.5) * -sign(is_end);
	
	float side = sign(float(uv.y > 0.5)-0.5);
	vertex += (perp*side) * width;
	
	binormal = -perp;
	normal = cross(perp,dir_to_next_point);
	tangent = cross(normal,binormal);
	
	return is_end;
}

mat3 facevec(vec3 vector) {
	vec3 c = vector;
	vec3 a = normalize(cross(c,vec3(0.0,1.0,0.0)));
	vec3 b = normalize(cross(a,c));
	return mat3(a,b,c);
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

uniform float angle = 0.0;
varying vec3 eye_dir;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	
	float is_end = line_process(line_width,VERTEX,normalize(VERTEX),UV2,NORMAL,TANGENT,BINORMAL);
	
	mat3 TBN = mat3(
		TANGENT,
		-BINORMAL,
		NORMAL
	);
	eye_dir = VERTEX * TBN;
}

vec3 opRep( in vec3 p, in vec3 c )
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

uniform float link_radius = 0.15;
uniform float link_thickness = 0.05;
float sdLink( vec3 p, float le )
{
	
	float r1 = link_radius;
	float r2 = link_thickness;
	vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
	return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

uniform float repeat_size = 1.0;
uniform float repeat_size_b = 0.1;
float scene(vec3 p){
	p = opRep(p,vec3(repeat_size+repeat_size_b,0.0,0.0));
	p.x = p.x - clamp(p.x,-repeat_size_b,repeat_size_b);
	p.x = clamp(p.x,-0.5,0.5);
	vec3 p1 = rotateAlign(vec3(0.0,1.0,0.0), vec3(1.0,0.0,0.0)) * p;
	
	mat3 rot = rotateAlign(vec3(1.0,0.0,0.0), vec3(0.0,0.0,1.0));
	vec3 p2 = rot * p1-vec3(0.0,0.4,0.0);
	vec3 p3 = rot * p1-vec3(0.0,-0.4,0.0);
	float r1 = sdLink(p1, 0.1);
	float r2 = sdLink(p2, 0.1);
	float r3 = sdLink(p3, 0.1);
	
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
	float total_dist = 0.0;
	
	for(int i=0;i<80;i++){
		// culling below 3.0 is excessive
		// and even more visible at grazing angles
		if (total_dist > 5.0) { break; }
		
		vec3 ray = ro + (rd * total_dist);
		
		float dist = scene(ray);
		
		if (dist < 0.001){
			return total_dist;
		}
		
		total_dist += dist;
	}
	
	return -1.0;
}

uniform float roughness : hint_range(0.0, 1.0, 0.001) = 0.1;
uniform vec4 color : source_color = vec4(vec3(0.9),1.0);
uniform float twirl_aspect = 0.5;

void fragment(){
	mat3 TBN =  mat3(
		TANGENT,
		-BINORMAL,
		NORMAL
	);
	
	// I don't know how this works, but it does, so no complaints
	vec3 yeds = VIEW_MATRIX[1].xyz * TBN;
	float a1 = atan(-yeds.y,yeds.z);

	mat3 rot = rotation3dX( a1 + angle );
	TBN *= rot;
	
	vec3 ro = TBN * vec3(UV,0.0);
	
	ALBEDO = ro;
	
	ROUGHNESS = roughness;
	METALLIC = 1.0;
}