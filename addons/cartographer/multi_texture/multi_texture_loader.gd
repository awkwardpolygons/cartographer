tool
extends ResourceFormatLoader
class_name MultiTextureLoader

func get_recognized_extensions():
	return PoolStringArray(["mtex"])

func get_resource_type(path):
	return "TextureArray"

func handles_type(typename):
	return typename == "TextureArray"

func load(path, original_path):
	var mt
	var f = File.new()
	var err = f.open(path, File.READ)
	if err != OK:
		push_error("Error: %s, MultiTextureLoader: Failed to load %s" % [err, path])
		f.close()
		return err
	var res = JSON.parse(f.get_as_text())
	if res.error != OK:
		push_error("Error: %s, MultiTextureLoader: %s, %s" % [res.error, res.error_line, res.error_string])
		f.close()
		return res.error
	var d = res.result
	mt = MultiTexture.new()
	mt.create(d.width, d.height, d.depth, d.format, d.flags)
	mt.array.resize(len(d.array))
	for i in len(d.array):
		mt.assign(i, load(d.array[i]))
	f.close()
	return mt
