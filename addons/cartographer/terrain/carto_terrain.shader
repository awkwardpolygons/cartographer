shader_type spatial;
render_mode skip_vertex_transform,blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;

const float MESH_STRIDE = 16.0;
const int NUM_LAYERS = 16;
const float WEIGHTMAP_SCALE = 2.0;
uniform int INSTANCE_COUNT = 1;
uniform sampler2D heightmap : hint_black;
uniform sampler2D weightmap : hint_black;
uniform sampler2DArray albedo_textures : hint_albedo;
uniform sampler2DArray orm_textures;
uniform sampler2DArray normal_textures;
uniform vec3 terrain_size;
uniform float terrain_diameter = 256;
uniform float normal_scale : hint_range(-16,16);
uniform float triplanar_sharpness = 2.0;
uniform vec2 uv1_scale = vec2(1);
uniform uint use_triplanar = 0;
uniform float is_editing = 0.0;
uniform vec2 brush_pos;
uniform float brush_scale = 0.1;
varying vec3 position;
varying vec3 normal;
varying vec3 UV3D;
varying vec3 triplanar_blend;

float get_height(vec2 uv) {
	vec4 h = texture(heightmap, uv);
	return h.r;
}

// TODO: Fix the ground level being 0 rather than the height at cam position.
vec3 clipmap(int id, vec3 cam, vec3 vtx, inout vec2 uv, inout vec4 clr) {
	// Divide terrain_size by 2 to get the bounds around center, in local space
	vec3 box = terrain_size / 2.0;
	// Get the surface num, stored in the y val, 0 for the inner surface, 1 for the outer
	int sfc = int(ceil(vtx.y));
	// Get the current starting instance level, based on the camera's height above the plane, in steps of 64
	int lvl = int(cam.y / 64.0);
	// Cap the lvl at the instance count
	lvl = min(lvl, INSTANCE_COUNT - 1);
	// Get the size mulitplier for each instance, each level is twice the size of the former
	float mul = pow(2.0, float(id));
	// cam is the camera offset, limit it to within the bounds of the terrain size
//	vec3 off = clamp(cam, terrain_diameter / 2.0 * -1.0, terrain_diameter / 2.0);
	vec3 off = clamp(cam, box * -1.0, box);
	// Set the stride, or number of units it moves per step,
	// which is the max quad size (16) so you don't get wavy terrain.
	off = floor(off / MESH_STRIDE) * MESH_STRIDE;
	// Double the size of the mesh so we have some overlap to clip as it moves
//	vtx *= 2.0;
	
	// Calculate the terrain uv
	uv = ((vtx.xz * mul + off.xz) / terrain_diameter) + 0.5;
//	uv = ((vtx.xz * mul) / 256.0) + 0.5;
	// Get the height from the heightmap
	off.y = get_height(uv) * terrain_size.y;
	
	vtx = vtx * vec3(1, 0, 1) * mul + off;
	bool below = lvl + 1 - id > 0; // true if this vertex is on or below the first active level
	bool above = id + 1 - lvl > 0; // true if this vertex is on or above the first active level
	bool bound = !(abs(vtx.x) > box.x || abs(vtx.z) > box.z); // true if this vertex is within bounds
	bool clip = (bool(sfc) || below) && above && bound;
	
	clr = vec4(0.1 * float(id * 2 + sfc), 0, 0.1, 1);
//	vtx.y = 0.0;
//	return vtx * vec3(mul, 1.0 / float(clip), mul) + off;
	return vtx * vec3(1, 1.0 / float(clip), 1);
}

vec3 calc_normal(vec2 uv, float _off) {
	vec3 off = vec2(_off, 0.0).xxy;
	float x = get_height(uv - off.xz) - get_height(uv + off.xz);
	float y = get_height(uv - off.zy) - get_height(uv + off.zy);
	return normalize(vec3(x, off.x * 1.0, y));
}

void vertex() {
	position = clipmap(INSTANCE_ID, CAMERA_MATRIX[3].xyz, VERTEX, UV, COLOR);
	VERTEX = position;
	
	UV2 = UV;
	UV3D = position;
	UV3D.xz += 0.5 * terrain_diameter;
	UV3D *= vec3(1, 1, -1) * vec3(uv1_scale.x, (uv1_scale.x + uv1_scale.y)/2.0, uv1_scale.y);
	triplanar_blend = pow(abs(normal), vec3(triplanar_sharpness));
	UV = UV3D.xz;
	
	// Experimenting with displacement
//	VERTEX.y += (texture(normal_textures, vec3(UV, 0)).a - 0.5);
	
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	normal = calc_normal(UV2, 1.0 / terrain_diameter);
	NORMAL = normal;
	TANGENT = vec3(0.0,0.0,-1.0) * NORMAL.x;
	TANGENT+= vec3(1.0,0.0,0.0) * NORMAL.y;
	TANGENT+= vec3(1.0,0.0,0.0) * NORMAL.z;
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,-1.0,0.0) * NORMAL.x;
	BINORMAL+= vec3(0.0,0.0,1.0) * NORMAL.y;
	BINORMAL+= vec3(0.0,-1.0,0.0) * NORMAL.z;
	BINORMAL = normalize(BINORMAL);

	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	BINORMAL = (MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz;
	TANGENT = (MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz;
}

vec4 draw_gizmo(vec4 clr, vec2 uv, vec2 pos) {
	float r = length(uv - pos);
	float w = 1.0 / terrain_diameter * 2.0;
	return r > brush_scale || r < brush_scale - w ? vec4(0) : clr;
}

vec4 texture_triplanar(sampler2DArray sampler, vec3 tex_pos, float layer, vec3 blend) {
	vec4 tx = texture(albedo_textures, vec3(tex_pos.yz * vec2(-1.0,1.0), layer));
	vec4 ty = texture(albedo_textures, vec3(tex_pos.xz, layer));
	vec4 tz = texture(albedo_textures, vec3(tex_pos.xy, layer));
	return (tx * blend.x + ty * blend.y + tz * blend.z);
}

vec4 get_weight(int layer, vec2 uv) {
	uv /= WEIGHTMAP_SCALE;
	int x = (layer / 4);
	x = x % 2;
	int y = layer / 8;
	vec2 region = vec2(float(x), float(y)) / WEIGHTMAP_SCALE;
	vec4 weight = texture(weightmap, uv + region);
	return weight;
}

vec4 blend_alpha(vec4 dst, vec4 src) {
	float a = src.a + dst.a * (1.0 - src.a);
	vec3 rgb = (src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / a;
	return vec4(rgb, a);
}

vec4 blend_terrain(vec4 wg1, vec4 wg2, vec4 wg3, vec4 wg4, float wt, vec2 uv2, vec3 uv3d, vec3 tri_blend, out vec4 orm, out vec4 nrm) {
	vec4 alb = vec4(0);
	float alp = 0.0;
	float weights[16] = {wg1.r, wg1.g, wg1.b, wg1.a, 
						wg2.r,wg2.g, wg2.b, wg2.a,
						wg3.r, wg3.g, wg3.b, wg3.a,
						wg4.r, wg4.g, wg4.b, wg4.a};
	
	for (int lyr = 0; lyr < weights.length(); lyr++) {
		float w = weights[lyr];
		uint flg = uint(pow(2.0, float(lyr)));
		vec4 a, o, n;
		
		if ((flg & use_triplanar) > uint(0)) {
			a = texture_triplanar(albedo_textures, uv3d, float(lyr), tri_blend);
			o = texture_triplanar(orm_textures, uv3d, float(lyr), tri_blend);
			n = texture_triplanar(normal_textures, uv3d, float(lyr), tri_blend);
		}
		else {
			a = texture(albedo_textures, vec3(uv3d.xz, float(lyr)));
			o = texture(orm_textures, vec3(uv3d.xz, float(lyr)));
			n = texture(normal_textures, vec3(uv3d.xz, float(lyr)));
		}
		
		w = w * (w < 1.0 ? a.a : 1.0);
		alb += a * w;
		orm += o * w;
		nrm += n * w;
		alp += w;
	}
	
	alp = (alp < 1.0 ? 1.0 : alp);
	alb = alb / alp;
	orm = orm / alp;
	nrm = nrm / alp;
	return alb;
}

void fragment() {
	vec4 giz = draw_gizmo(vec4(1, 0, 1, 1), UV2, brush_pos);
	vec4 orm;
	vec4 nmp;
	// Get all the weights, for each layer, in groups of vec4 (cos GD shader array support is poor)
	vec4 wg1 = get_weight(0, UV2), wg2 = get_weight(4, UV2), wg3 = get_weight(8, UV2), wg4 = get_weight(12, UV2);
	// Get the weight total
	float wt = dot(wg1 + wg2 + wg3 + wg4, vec4(1));
	// Use the weights to blend the layers of the various texture arrays
	vec4 clr = blend_terrain(wg1, wg2, wg3, wg4, wt, UV2, UV3D, triplanar_blend, orm, nmp);
	
	ALBEDO = (clr.rgb + giz.rgb);
	NORMALMAP = nmp.xyz;
	float nmp_fade = (1.0 - length(CAMERA_MATRIX[3].xyz - UV3D) / terrain_diameter);
	NORMALMAP_DEPTH = nmp_fade * 4.0;
//	ALBEDO = (CAMERA_MATRIX * (vec4(NORMAL, 0.0))).rgb;
	AO = orm.r;
	ROUGHNESS = orm.g;
	METALLIC = orm.b;
	SPECULAR = 0.5;
}
