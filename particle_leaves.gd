extends Particles


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	#randomize()
	preprocess = randi()%31+15
	#print(preprocess)
	yield(get_tree().create_timer(0.5), "timeout")
	speed_scale = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
