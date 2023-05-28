
#define PLYLINE_INPUTS VERTEX,UV,TANGENT,BINORMAL,NORMAL
#define quick_line(width,rounded) \
	LineData ld = pak_linedata(PLYLINE_INPUTS,width,rounded); \
	is_end = line_process(ld); \
	unpak_linedata(PLYLINE_INPUTS,ld);

#define __LD_MESH_ARGS inout vec3 vertex, inout vec2 uv, \
	inout vec3 tangent, inout vec3 binormal, inout vec3 normal

struct LineData {
	float width;
	vec3 vertex, dir_to_cam;
	vec2 uv;
	mat3 tbn;
	
	float is_end;
	bool tangent_facing, rounded;
};

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
	normal = ld.tbn[2];
	tangent = ld.tbn[0];
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
	
	ld.tbn[0] = perp;
	ld.tbn[2] = cross(perp,dir_to_next_point);
	ld.tbn[1] = cross(ld.tbn[2],ld.tbn[0]);
	
	return is_end;
}

float line_process_rounded_curve(inout LineData ld){
	vec3 dir_to_next_point = ld.tbn[2];
	vec3 perp = ld.tbn[0];
	if (!ld.tangent_facing) {
		perp = normalize(cross(ld.dir_to_cam,dir_to_next_point));
	}
	
	float is_end = 0.5-ld.uv.x;
	ld.is_end = float(abs(ld.is_end) > 0.5) * -sign(ld.is_end);
	vec3 rounder = vec3(0.0); 
	if (ld.rounded) { 
		rounder = is_end * normalize(cross(perp,ld.dir_to_cam));
	}
	
	float side = sign(float(ld.uv.y > 0.5)-0.5);
	ld.vertex += ((perp*side)-rounder) * ld.width;
	
	ld.tbn[0] = perp;
	ld.tbn[2] = cross(perp,dir_to_next_point);
	ld.tbn[1] = cross(ld.tbn[0],ld.tbn[2]);
	
	return is_end;
}

// SHADING

float getDistToLineCenter(vec2 uv, float is_end) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return length(c)*0.5;
}

float getDistSquaredToLineCenter(vec2 uv, float is_end) {
	vec2 c = vec2(is_end*0.5,uv.y-0.5);
	return dot(c,c);
}

vec2 getLineTubeNormal(vec2 uv, float is_end, bool rounded) {
	vec2 n = vec2(0.5);
		n.x = uv.y;
		if (rounded) {
			n.y = (is_end*0.5+0.5);
		}
	return n;
}