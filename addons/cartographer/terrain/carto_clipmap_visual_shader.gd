tool
extends VisualShader
class_name CartoClipmapVisualShader

var clipmap_vertex_node: VisualShaderNodeCartoClipmapVertex
var clipmap_transform_node: VisualShaderNodeCartoClipmapTransform
var tangent_space_node: VisualShaderNodeCartoTangentSpace
var heightmap_calc_node: VisualShaderNodeCartoHeightmapCalc
var offset_add_node: VisualShaderNodeVectorOp

func _init():
	set("flags/skip_vertex_transform", true)
	clipmap_vertex_node = VisualShaderNodeCartoClipmapVertex.new()
	clipmap_transform_node = VisualShaderNodeCartoClipmapTransform.new()
	tangent_space_node = VisualShaderNodeCartoTangentSpace.new()
	heightmap_calc_node = VisualShaderNodeCartoHeightmapCalc.new()
	offset_add_node = VisualShaderNodeVectorOp.new()
	offset_add_node.operator = VisualShaderNodeVectorOp.OP_ADD
	
	add_node(VisualShader.TYPE_VERTEX, clipmap_transform_node, Vector2(32, 32), 3)
	add_node(VisualShader.TYPE_VERTEX, tangent_space_node, Vector2(-256, -64), 4)
	add_node(VisualShader.TYPE_VERTEX, heightmap_calc_node, Vector2(-512, -48), 5)
	add_node(VisualShader.TYPE_VERTEX, offset_add_node, Vector2(-256, 64), 6)
	add_node(VisualShader.TYPE_VERTEX, clipmap_vertex_node, Vector2(-768, 32), 7)
	connect_nodes(VisualShader.TYPE_VERTEX, 4, 0, 3, 1)
