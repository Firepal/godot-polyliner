shader_type spatial;
render_mode skip_vertex_transform;

// \"tangent-facing\" code and \"rounded end\" code was removed
// for this particular shader

uniform float line_width = 0.05;
float line_process(float width, inout vec3 vertex, vec3 dir_to_cam, vec2 uv,
					inout vec3 normal, inout vec3 tangent){
	vec3 dir_to_next_point = normal;
	vec3 perp = normalize(cross(dir_to_cam,dir_to_next_point));
	
	float is_end = 0.5-uv.x;
	is_end = float(abs(is_end) > 0.5) * -sign(is_end);
	
	float side = sign(float(uv.y > 0.5)-0.5);
	vertex += (perp*side) * width;
	
	tangent = perp;
	normal = cross(perp,dir_to_next_point);
	
	return is_end;
}

varying mat3 TBN;
varying vec3 eye_dir;
varying float is_end;
void vertex(){
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX,1.0)).xyz;
	NORMAL = mat3(MODELVIEW_MATRIX) * NORMAL;
	TANGENT = mat3(MODELVIEW_MATRIX) * TANGENT;
	
	is_end = line_process(line_width,VERTEX,normalize(VERTEX),UV2,NORMAL,TANGENT);
	
	// TODO: Why does this make TBN work,
	// while it breaks normal mapping?
	BINORMAL = TANGENT;
	TANGENT = cross(BINORMAL,NORMAL);
	
	TBN = mat3(
		TANGENT,
		BINORMAL,
		NORMAL
	);
	
	eye_dir = normalize(VERTEX) * TBN;
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
    const float h = 0.0001;
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*scene( p + k.xyy*h ) + 
                      k.yyx*scene( p + k.yyx*h ) + 
                      k.yxy*scene( p + k.yxy*h ) + 
                      k.xxx*scene( p + k.xxx*h ) );
}

float raymarch(vec3 ro, vec3 rd){
	float total_dist = 0.0;
	
	for(int i=0;i<60;i++){
		// culling below 3.0 is excessive
		// and even more visible at grazing angles
		if (total_dist > 3.0) { break; }
		
		vec3 ray = ro + (rd * total_dist);
		
		float dist = scene(ray);
		
		if (dist < 0.005){
			return total_dist;
		}
		
		total_dist += dist;
	}
	
	return -1.0;
}

vec2 hash22(vec2 p)
{
	vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
	p3 += dot(p3, p3.yzx+33.33);
	return fract((p3.xx+p3.yz)*p3.zy);
}
float ao(vec3 p, vec3 n, vec2 fragcoord)
{
	vec3 t = normalize(cross(n,vec3(0.0,1.0,0.0)));
	vec3 b = normalize(cross(t,n));
	
	float inv_t = 1.0/10.0;
	
	float occ = 0.0;
	for (int i=0;i<10;i++)
	{
		vec2  aa = ( hash22(fragcoord+TIME*float(i+1)) );
		float ra = sqrt(aa.y);
		float rx = ra*cos(6.2831*aa.x); 
		float ry = ra*sin(6.2831*aa.x);
		float rz = sqrt( 1.0-aa.y );
		vec3  dir = vec3( rx*t + ry*b + rz*n );
		vec3 no;
		float hit = raymarch(p+dir*0.1,dir);
		if (hit < 0.0)
			occ += inv_t;
	}
	
	return occ;
}

uniform vec4 color : hint_color = vec4(vec3(1.0,1.0,0.5),1.0);
uniform float twirl_aspect = 0.5;

void fragment(){
	// We can't do raycasts with objects
	// that intersect Z =< 0.0 in tangent-space; it gets clipped.
	// So the rope is actually below the line surface.
	vec3 ro = vec3(UV,0.45);
	vec3 rd = eye_dir;
	
	ro.x *= twirl_aspect / line_width;
	
	// fix weird offset
	ro.y += -0.5;
	
	// fit the model roughly to line mesh bounds
	ro.xy *= 0.8;
	
	float hit = raymarch(ro, rd);
	if (hit < 0.0) { discard; }
	
	vec3 hit_pos = ro + rd * hit;
	vec3 hit_normal = getNormal(hit_pos);
	NORMAL = TBN * hit_normal;
	
	float ao = ao(hit_pos, hit_normal, FRAGCOORD.xy);
	ALBEDO = color.rgb * ao;
	ROUGHNESS = 0.5;
}