tool
extends CSGMesh

func _ready():
	yield(get_tree().create_timer(3), "timeout")
	var shader_rid = VisualServer.material_get_shader(material.get_rid())
	prints("-->", shader_rid.get_id(), VisualServer.shader_get_code(shader_rid))
	prints("-->", VisualServer.material_get_param(material.get_rid(), "normal_scale"))
