tool
extends ResourceFormatSaver
class_name CartoMultiTextureSaver

func get_recognized_extensions(res: Resource) -> PoolStringArray:
	return PoolStringArray(["texarr"]) if recognize(res) else PoolStringArray()

func recognize(res: Resource) -> bool:
	return res is CartoMultiTexture

func save(path: String, res: Resource, flags: int) -> int:
	var imp = CartoTextureArrayBuilder.new()
	var texarr = res as CartoMultiTexture
	texarr.take_over_path(path)
	return imp._save_tex(res.data.layers, path, imp.Compress.LOSSLESS, -1, texarr.flags)
