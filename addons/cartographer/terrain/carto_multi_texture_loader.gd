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
	var ta: CartoMultiTexture
	var data: Dictionary
	var file = File.new()
	var err = file.open_compressed(path, File.READ, File.COMPRESSION_ZSTD)
	if err == OK:
		data = file.get_var(true)
		err = file.get_error()
	file.close()
	if err == OK:
		ta = CartoMultiTexture.new()
		ta.data = data
		return ta
	return err
