tool
extends ResourceFormatLoader
class_name CartoMultiTextureLoader

func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["mtex"])

func get_resource_type(path: String) -> String:
	return "Resource"

func handles_type(typename: String) -> bool:
	return true

func load(path: String, original_path: String):
	var file = File.new()
#	file.open(path, File.READ)
	file.open_compressed(path, File.READ, File.COMPRESSION_ZSTD)
	var data = file.get_var(true)
	var err = file.get_error()
	file.close()
	prints(data.layers, err)
	return CartoMultiTexture.new()
