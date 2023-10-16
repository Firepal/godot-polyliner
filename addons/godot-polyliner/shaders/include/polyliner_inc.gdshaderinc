#define PLYLINE_INPUTS VERTEX,UV,TANGENT,BINORMAL,NORMAL
#define quick_line(width,rounded) \
	LineData ld = pak_linedata(PLYLINE_INPUTS,width,rounded); \
	is_end = line_process(ld); \
	unpak_linedata(PLYLINE_INPUTS,ld);

struct LineData {
	float width;
	vec3 vertex, dir_to_cam;
	vec2 uv;
	mat3 tbn;
	
	float is_end;
	bool tangent_facing, rounded;
};

#define __LD_MESH_ARGS inout vec3 vertex, inout vec2 uv, \
	inout vec3 tangent, inout vec3 binormal, inout vec3 normal

LineData pak_linedata(__LD_MESH_ARGS, float width, bool rounded){
	LineData ld;
	ld.width = width;
	ld.vertex = vertex;
	ld.dir_to_cam = normalize(vertex);
	ld.uv = uv;
	ld.tbn = mat3(
		tangent,
		binormal,
		normal
	);
	ld.tangent_facing = false;
	ld.rounded = rounded;
	return ld;
}


void unpak_linedata(__LD_MESH_ARGS, LineData ld){
	vertex = ld.vertex;
	normal = (ld.tbn[2]);
	tangent = (ld.tbn[0]);
	binormal = (ld.tbn[1]);
}

float line_process(inout LineData ld){
	vec3 dir_to_next_point = ld.tbn[2];
	vec3 perp = normalize(cross(ld.dir_to_cam,dir_to_next_point));
	
	float is_end = 0.5-ld.uv.x;
	is_end = float(abs(is_end) > 0.5) * -sign(is_end);
	
	vec3 rounder = vec3(0.0); 
	if (ld.rounded) { 
		rounder = is_end * normalize(cross(perp,ld.dir_to_cam));
	}
	
	float side = sign(float(ld.uv.y > 0.5)-0.5);
	ld.vertex += ((perp*side)-rounder) * ld.width;
	
//	tangent = perp;
//	normal = cross(perp,dir_to_next_point);
//	ld.tbn[0] = normalize(perp);
//	ld.tbn[2] = normalize(cross(perp,dir_to_next_point));
//	ld.tbn[1] = (cross(ld.tbn[2],ld.tbn[0]));
	
	// fixes raymarching but breaks lighting
	ld.tbn[1] = perp;
	ld.tbn[2] = normalize(cross(perp,dir_to_next_point));
	ld.tbn[0] = normalize(cross(ld.tbn[1],ld.tbn[2]));
	
	return is_end;
}

//float line_process_rounded_curve(inout LineData ld){
//	vec3 dir_to_next_point = ld.tbn[2];
//	vec3 perp = ld.tbn[0];
//	if (!ld.tangent_facing) {
//		perp = normalize(cross(ld.dir_to_cam,dir_to_next_point));
//	}
//
//	float is_end = 0.5-ld.uv.x;
//	ld.is_end = float(abs(ld.is_end) > 0.5) * -sign(ld.is_end);
//	vec3 rounder = vec3(0.0); 
//	if (ld.rounded) { 
//		rounder = is_end * normalize(cross(perp,ld.dir_to_cam));
//	}
//
//	float side = sign(float(ld.uv.y > 0.5)-0.5);
//	ld.vertex += ((perp*side)-rounder) * ld.width;
//
//	ld.tbn[1] = perp;
//	ld.tbn[2] = cross(perp,dir_to_next_point);
//	ld.tbn[0] = cross(ld.tbn[2],ld.tbn[1]);
//
//	return is_end;
//}

// SHADING

float getDistToLineCenter(vec2 uv, float is_end) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return length(c)*0.5;
}

float getDistSquaredToLineCenter(vec2 uv, float is_end) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return dot(c,c);
}

vec3 getLineTubeNormal(vec2 uv, float is_end, bool rounded) {
	vec3 n = vec3(0.0,0.0,1.0);
		n.x = uv.y*2.0-1.0;
		if (rounded) {
			n.y = (is_end);
		}
	return normalize(n)*0.5+0.5;
}

// MISC

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