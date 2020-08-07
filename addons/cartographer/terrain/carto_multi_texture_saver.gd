tool
extends ResourceFormatSaver
class_name CartoMultiTextureSaver

func get_recognized_extensions(res: Resource) -> PoolStringArray:
	return PoolStringArray(["mtex"]) if recognize(res) else PoolStringArray()

func recognize(res: Resource) -> bool:
	return res is CartoMultiTexture

func save(path: String, res: Resource, flags: int) -> int:
	var ta = load("res://example/terra1.png")
	var file = File.new()
#	file.open(path, File.WRITE)
	file.open_compressed(path, File.WRITE, File.COMPRESSION_ZSTD)
	file.store_var(ta.data, true)
	var err = file.get_error()
	file.close()
	prints(ta.data)
	return err
