tool
extends Resource
class_name CartoTerrainLayers

export(PoolIntArray) var layers: PoolIntArray
enum LayerTypes {SHRUB = 4, PAINT = 8, SCULPT = 16}
enum PaintLayerModes {BLEND, WEIGHT}

func add_layer(type):
	pass
