shader_type spatial;
render_mode skip_vertex_transform,blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx;

uniform sampler2D h1 : hint_black;
uniform sampler2D h2 : hint_black;
uniform sampler2D h3 : hint_black;
uniform sampler2D t1 : hint_black;
uniform sampler2D t2 : hint_black;
uniform sampler2D t3 : hint_black;
varying vec3 UV3D;

bool within(vec2 uv, mat2 bounds) {
	return all(lessThan(uv, bounds[0])) && all(greaterThanEqual(uv, bounds[1]));
}

vec4 texture_select(sampler2D s1, sampler2D s2, sampler2D s3, vec2 uv, int idx) {
	vec4 clr;
	switch (idx) {
		case 0:
			clr = texture(s1, uv);
			clr += vec4(0.5, 0, 0, 1);
			break;
		case 1:
			clr = texture(s2, uv);
			clr += vec4(0, 0.5, 0, 1);
			break;
		default:
			clr = texture(s3, uv);
			clr += vec4(0, 0, 0.5, 1);
			break;
	}
	
	return clr;
}

void vertex() {
	vec3 vtx = VERTEX;
	vtx = (WORLD_MATRIX * vec4(vtx, 1)).xyz;
	vec3 org = WORLD_MATRIX[3].xyz;
	vec4 h = texture(h1, vtx.xz / 2048.0 + 0.5);
	VERTEX = vtx;
	UV3D = vtx;
	
	vec4 hgt;
	vec2 uv = UV3D.xz;
	mat2 bnd = mat2(vec2(0.5), vec2(-0.5));
	float scl = 2000.0;
	float bse = 2.0;
	uv /= scl;
	vec2 uva[3] = {uv, uv / bse, uv / pow(bse, 2)};
	int dst = int(max(abs(uv.x), abs(uv.y)) * 2.0) + 0;
	int idx = int(bool(dst)) * (int(log2(float(dst))) + 1);
	
	hgt = texture_select(h1, h2, h3, uva[idx] + 0.5, idx);
	
//	for (int i = 0; i < 1; i++) {
//		uv /= scl;
//		if (within(uv, bnd)) {
//			hgt = texture(h1, uv + 0.5);
////			clr += vec4(0.5, 0, 0, 1);
//			break;
//		}
//		uv /= bse;
//		if (within(uv, bnd)) {
//			hgt = texture(h2, uv + 0.5);
////			clr += vec4(0, 0.5, 0, 1);
//			break;
//		}
//		uv /= bse;
//		if (within(uv, bnd)) {
//			hgt = texture(h3, uv + 0.5);
////			clr += vec4(0, 0, 0.5, 1);
//			break;
//		}
//	}
	
	VERTEX.y = hgt.r * 32.0;
	VERTEX = (INV_CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
}



void fragment() {
	vec4 clr = vec4(1, 0, 0, 1);
	vec2 uv = UV3D.xz;
	mat2 bnd = mat2(vec2(0.5), vec2(-0.5));
	float scl = 2000.0;
	float bse = 2.0;
	uv /= scl;
	vec2 uva[3] = {uv, uv / bse, uv / pow(bse, 2)};
	int dst = int(max(abs(uv.x), abs(uv.y)) * 2.0) + 0;
	int idx = int(bool(dst)) * (int(log2(float(dst))) + 1);
	clr = vec4(float(idx), 0, 0, 1);
	
	clr = texture_select(t1, t2, t3, uva[idx] + 0.5, idx);
	
//	for (int i = 0; i < 1; i++) {
////		uv /= scl;
//		if (within(uv, bnd)) {
//			clr = texture(t1, uv + 0.5);
////			clr += vec4(0.5, 0, 0, 1);
//			break;
//		}
//		uv /= bse;
//		if (within(uv, bnd)) {
//			clr = texture(t2, uv + 0.5);
////			clr += vec4(0, 0.5, 0, 1);
//			break;
//		}
//		uv /= bse;
//		if (within(uv, bnd)) {
//			clr = texture(t3, uv + 0.5);
////			clr += vec4(0, 0, 0.5, 1);
//			break;
//		}
//	}
	
//	vec4 ter = texture(t1, UV3D.xz / 40.0);
	ALBEDO = clr.rgb;
//	ALBEDO = vec3(1, 0, 0);
}
