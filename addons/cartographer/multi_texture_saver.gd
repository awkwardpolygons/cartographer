tool
extends ResourceFormatSaver
class_name MultiTextureSaver

func get_recognized_extensions(resource):
#	print("MultiTextureSaver.get_recognized_extensions: ", resource)
	if resource != null && resource is MultiTexture:
		return PoolStringArray(["mtex"])
	return PoolStringArray()

func recognize(resource):
	print("MultiTextureSaver.recognize: ", resource, resource is MultiTexture)
	return resource != null && resource is MultiTexture

func save(path, resource, flags):
	print("MultiTextureSaver: ", path, resource, flags)
	var d = {
		"type": "MultiTexture",
		"width": resource.get_width(),
		"height": resource.get_height(),
		"depth": resource.get_depth(),
		"format": resource.get_format(),
		"flags": resource.flags,
		"array": [],
	}
	for t in resource.array:
		d.array.append(t.resource_path)
	var f = File.new()
	f.open(path, File.WRITE)
	f.store_string(JSON.print(d))
	f.close()
	return OK
